import { LightningElement ,api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import { loadStyle } from 'lightning/platformResourceLoader';
import EMAIL_FIELD from '@salesforce/schema/User.Email';
import NAME_FIELD from '@salesforce/schema/User.Name';
import USER_ID from '@salesforce/user/Id';
import configuationItemList from '@salesforce/apex/TicketCreatorController.configuationItemList';
import createAzureTicket from '@salesforce/apex/TicketCreatorController.createAzureTicket';
import createJiraTicket from '@salesforce/apex/TicketCreatorController.createJiraTicket';
import createServiceNowTicket from '@salesforce/apex/TicketCreatorController.createServiceNowTicket';
import deleteAttachment from '@salesforce/apex/TicketCreatorController.deleteAttachment';
import fileIcons from '@salesforce/resourceUrl/fileIcons';
import fileSelectorStyle from '@salesforce/resourceUrl/fileSelectorStyle';
import getAzureTeams from '@salesforce/apex/ExternalUserIntegrationService.getAzureTeams';
import getDocumentSize from '@salesforce/apex/AttachmentManager.getDocumentSize';
import getJiraUsersList from '@salesforce/apex/ExternalUserIntegrationService.getJiraUsersList';
import getRaiseItNowConnectionStatus from '@salesforce/apex/AdminController.getRaiseItNowConnectionStatus';
import getRaiseItNowConnections from '@salesforce/apex/ConnectionHandler.getRaiseItNowConnections';
import getReporter from '@salesforce/apex/TicketCreatorController.getReporter';
import getServiceNowLookup from '@salesforce/apex/ExternalUserIntegrationService.serviceNowLookup';
import getTemplateDetails from '@salesforce/apex/TicketCreatorController.getTemplateDetails';
import getUploadedAttachments from '@salesforce/apex/TicketCreatorController.getUploadedAttachments';
const BYTE_VALUE = 1024,
      NEGATIVE_ONE = -1,
      ONE = 1,
      ONE_SIXTY = 160,
      THOUSAND_FIVE_HUNDRED = 1500,
      THREE = 3,
      TWELVE = 12,
      ZERO = 0;

/* eslint-disable new-cap */
export default class TicketCreator extends NavigationMixin(LightningElement) {
/* eslint-enable new-cap */

    @api recordId;
    @track  ticketCreatorData = {
        uploadedFiles: []
    };
    @track isLoading = false;
    @track uploadError = null;
    @track assigneeRequired = false;
    @track showDescriptionVisiblity = false;
    isMaximized = false;
    observer;

    @track isSpinner = false;
    @track maxLength = ONE_SIXTY;
    @track serviceEmail ='';
    @track deleteCacheAttachment;
    @track contentVersion = {};
    @track videoUrl = '';
    @track fileName = '';
    @track currentUserName = '';
    @track userEmail = '';
    @track showServiceCombo = false;
    @track serviceOptions = [];
    @track selectedService;
    messageHandler;
    @track templateFileSizeMap = {};
    @wire(getRecord, {
        fields: [NAME_FIELD,EMAIL_FIELD,],
        recordId: USER_ID
      })
          wiredUser({ error, data }) {
          if (data) {
             this.currentUserName = data.fields.Name.value;
             this.userEmail = data.fields.Email.value;
             
           } else if (error) {
               TicketCreator.safeLog('Error retrieving user name:', error);
          } 
         }

    
acceptedFormats = [".pdf", ".webm", ".docx", ".doc", ".xls", ".png", ".jpg", ".jpeg", ".mp4", ".xlsx", ".txt", ".rtf"];
    initialData = { attachment: { required: false }, description: { required: true, value: '' }, inputValues: {}, selectedProject: '', selectedProjectKey: '', selectedProjectfullname: '' };
    setSpinner(state) {
        this.isSpinner = state;
    }

     /** Safe no-op logger: allowed in dev, silent in managed package */
    static safeLog(...args) {
        // Intentionally blank: prevents console usage in AppExchange
        return args.length;
    }
     static getInitialData() {
        return {
            attachment: { required: false },
            description: { required: true, value: '' },
            inputValues: {},
            selectedProject: '',
            selectedProjectKey: '',
            selectedProjectfullname: ''
        }
    }

 connectedCallback() {
    TicketCreator.injectCustomStyles();
    this.initializeTicketData();
    this.loadTemplateAndConnections();
    this.handleUserSelectedData();
    this.setupEventListeners();
    this.deferObserverSetup();
}

// ------------------ Helper Methods ------------------

static injectCustomStyles() {
    const style = document.createElement('style');
    style.innerText = `
        .slds-docked-composer.slds-is-open {
            height: 435px !important;
        }
    `;
    document.head.appendChild(style);
}

initializeTicketData() {
    this.setSpinner(true);
    this.ticketCreatorData = { 
        ...TicketCreator.getInitialData(), 
        selectedTemplateId: this.ticketCreatorData?.selectedTemplateId 
    };
}

loadTemplateAndConnections() {
    this.getTemplateDetails();
    this.loadConnections();
    this.callReporters(['Jira', 'ServiceNow']);
    loadStyle(this, fileSelectorStyle);
}

handleUserSelectedData() {
    if (!localStorage) {return};

    const userSelectedData = localStorage.getItem('userSelected');
    if (!userSelectedData) {return};

    this.applyUserSelectedData(JSON.parse(userSelectedData));
    localStorage.removeItem('userSelected');
    this.getSelectedTemplateAttachments();
}

applyUserSelectedData(data) {
    this.ticketCreatorData.projectDisable = true;
    this.ticketCreatorData = { 
        ...this.ticketCreatorData, 
        ...data, 
        defaultData: true 
    };
}

setupEventListeners() {
    window.addEventListener('message', this.handleExtensionMessage.bind(this));
    window.addEventListener("beforeunload", this.handlePageUnload);
}

deferObserverSetup() {
    setTimeout(() => this.setupObserver(), ZERO);
}

    loadConnections() {
        this.isSpinner = true;
        getRaiseItNowConnections()
            .then(result => {
                if (result.success) {
                    const connectionNames = result.payloadMap.connectionNames || [];
                    this.serviceOptions = connectionNames.map(name => ({
                        label: name,
                        value: name
                    }));

                    if (this.serviceOptions.length > ZERO) {
                        this.showServiceCombo = true;
                    }
                } else {
                   TicketCreator.safeLog('Error: ', result.payloadMap.message);
                }
                this.isSpinner = false;
            })
            .catch(() => {
                this.showToast('There is no configuration for any project. Please contact Administrator.', '', 'warning');
                this.isSpinner = false;
            });
    }

    handleServiceChange(event) {
        this.updateSelectedService(event);
        if (this.allTemplates && this.allTemplates.length > ZERO) {
            const filteredTemplates = this.allTemplates.filter(
                temp => temp.servName === this.selectedService
            );

            if(filteredTemplates.length > ZERO){
                this.constructUiData(filteredTemplates);
            }else{
                this.showToast('No Templates Found',`There is no configuration for this "${this.selectedService}". Please contact Administrator.`, 'warning');
                this.setSpinner(false);
            }
        }else{
            this.showToast('No Templates Found',`There is no configuration for this "${this.selectedService}". Please contact Administrator.`, 'warning');
            this.setSpinner(false);
        }
    }
//Helper Method for handleServiceChange
updateSelectedService(event) {
   this.setSpinner(true);
        this.deleteCacheFiles();
        this.selectedService = event.detail.value;
        this.ticketCreatorData.selectedService = this.selectedService;
        this.ticketCreatorData.selectedProject = '';
        this.ticketCreatorData.fieldsList = [];
        this.ticketCreatorData.selectedProjectfullname = '';
        this.ticketCreatorData.projDetails =[];
}

    get showFieldsSection() {
            return (
            this.ticketCreatorData?.selectedService &&
            this.ticketCreatorData?.selectedProject &&
            Array.isArray(this.ticketCreatorData?.fieldsList) &&
            this.ticketCreatorData.fieldsList.length > ZERO
            );
        }


    handleExtensionMessage(event) {
         if (event?.data?.source === 'my_extension' && event.data?.type === 'getAttachments') {
               this.getSelectedTemplateAttachments();
           }
      }
     

     disconnectedCallback() {
        if (this.observer) {
            this.observer.disconnect();
        }
        this.deleteCacheFiles();
        window.addEventListener("beforeunload", this.handlePageUnload);
    }

   handlePageUnload = () => {
    this.deleteCacheFiles();
};

    setupObserver() {
        const targetNode = this.template.host.closest('.forceDockingPanel');
        if (!targetNode) {return};

        this.observer = new MutationObserver(() => {
            this.isMaximized = targetNode.classList.contains('MAXIMIZED');
        });

        this.observer.observe(targetNode, {
            attributeFilter: ['class'],
            attributes: true
        });
    }
    get scrollContainerClass() {
        if(this.isMaximized){
            return 'modal-no-scroll';
        }
            return 'modal-scroll-content';
    }

    callReporters(reporters) {
        reporters.forEach(reporter => this.getReporter(reporter));
    }

    getTemplateDetails() {
        getTemplateDetails({}).then(res => {
            if (res?.success) {
                if (res?.payloadMap?.templates && res?.payloadMap?.templates?.length > ZERO) {
                    this.allTemplates = JSON.parse(JSON.stringify(res.payloadMap.templates));
                }
            } else {
                this.showToast(res?.message, '', 'error');
                this.setSpinner(false);
            }
        }).catch(err => {
            this.showToast(err, '', 'error');
            this.setSpinner(false);
        })
    }

 constructUiData(templates) {
       const projDetails = [];
        if (templates && templates?.length > ZERO) {
            templates?.forEach(ele => {
                projDetails.push({ label: `${ele?.projectName} (${ele?.servName})`, value: `${ele?.servName} : ${ele?.projectName}` });
            });
            this.ticketCreatorData.templates = JSON.parse(JSON.stringify(templates));

            this.ticketCreatorData.projDetails = [...projDetails];

             this.ticketCreatorData.selectedProjectfullname = '';

             
        }else{
            this.ticketCreatorData.selectedProjectfullname = '';
            this.ticketCreatorData.projDetails = [];           
        }
        this.setSpinner(false);
    }
    checkConnection() {
        getRaiseItNowConnectionStatus({ serviceName: this.ticketCreatorData.selectedService }).then((res) => {
           this.serviceEmail = res.payloadMap?.emailAddress ;
            if (res.success) {
                this.setTemplateDetails();
            } else {
                this.showToast(res.payloadMap.message, '', 'error');
                this.setSpinner(false);
            }
        });
    }

    onProjectSelection(event) {

       const projDetail = event?.target?.value?.split(' : '),
           projName = projDetail[ONE],
          serviceName = projDetail[ZERO];
        this.setSpinner(true);  
        this.deleteCacheFiles();
        this.ticketCreatorData.selectedProjectfullname = event?.target?.value;
        this.ticketCreatorData.description.value='';
        this.ticketCreatorData.userLookupList = false;
        this.ticketCreatorData.filteredconfiguationItemList = false;
        this.ticketCreatorData.selectedService = serviceName;
        this.ticketCreatorData.selectedProject = projName;
        setTimeout(()=>{ this.maxLengthvalid();
        this.checkConnection();},ZERO)
       
    }
setTemplateDetails() {
    this.showDescriptionVisiblity = false;
    let selectedTemplateFields = {};
    let projKey = '';
    const matchedTemplate = this.ticketCreatorData?.templates?.find(ele =>
        this.ticketCreatorData.selectedService === ele?.servName &&
        this.ticketCreatorData.selectedProject === ele?.projectName
    );
    if (matchedTemplate) {
        projKey = matchedTemplate?.projectKey;
        this.ticketCreatorData.selectedProjectKey = projKey;
        this.ticketCreatorData.selectedTemplateId = matchedTemplate?.recordId;
        this.ticketCreatorData.selectedUserId = matchedTemplate?.lookUpId;
        this.ticketCreatorData.selectedAssinee = matchedTemplate?.userName;

        try {
            selectedTemplateFields = JSON.parse(matchedTemplate?.fieldsJson || '{}');
        } catch (ex) {
            return;
        }

        const fieldsList = [];
        this.ticketCreatorData.description = {
            ...TicketCreator.getInitialData()?.description,
            projectName: this.ticketCreatorData?.selectedProject,
            serviceName: this.ticketCreatorData?.selectedService,
            value: this.ticketCreatorData?.description?.value || null
        };

        this.ticketCreatorData.attachment = {
            ...TicketCreator.getInitialData()?.attachment,
            projectName: this.ticketCreatorData?.selectedProject,
            serviceName: this.ticketCreatorData?.selectedService
        };

        Object.entries(selectedTemplateFields).forEach(([key, value]) => {
            if (value.label === 'Description') {
                this.showDescriptionVisiblity = true;
                this.ticketCreatorData.description.required = value.required;
            } else if (value.label === 'Attachment') {
                this.ticketCreatorData.attachment.required = value.required;
            } else if (value.label === 'Configuration item') {
                this.ticketCreatorData.configItem = {
                    ...this.ticketCreatorData.configItem,
                    required: value.required
                };
                this.getConfiguationItemList();
            }else if (value.label === 'Assigned To') {

                this.getAzureUsersList();
            }else if (value.label === 'Assignee') {
                

                this.getJiraUsersList();
            }else if (value.label === 'Assigned to') {

                this.getServiceNowLookupList();
            }else {
                 let field = {
                    ...value,
                    isPickList: Array.isArray(value?.dropdown) && value.dropdown.length > 0,
                    isText: !value?.dropdown,
                    projectName: this.ticketCreatorData?.selectedProject,
                    serviceName: this.ticketCreatorData?.selectedService,
                    projectKey: projKey,
                    isView:false
                 };

                if (field.isPickList) {
                    
                    if(field.projectName === 'Incident' && key === 'priority'){
                        field.options = value.dropdown.slice(1).map(val => ({ label: val, value: val }));
                    }
                    else{

                        field.options = value.dropdown.map(val => ({ label: val, value: val }));
                    }
                    
                }

                if (value?.defaultValue) {
                   
                    field.value = value.defaultValue;
                  
                    this.ticketCreatorData.inputValues[field.name] = value.defaultValue;
                }
                if(value.label ==='Issue Type'){                 
                    field.value=value.dropdown[0];                                     
                    field.isText=true;
                    field.isPickList=false;                                 
                    this.ticketCreatorData.inputValues[field.name]=value.dropdown[0];
                   
                }
                if(value.label=='State'){

                    field.isView=true;

                }
                
        
                fieldsList.push(field);
            }
        });

        this.ticketCreatorData.fieldsList = [...fieldsList];
        this.getSelectedTemplateAttachments();
        this.setDefaultInputValues();
    } else {
        this.ticketCreatorData.fieldsList = [];
    }
}

    getConfiguationItemList() {
        const usersList = [];
        this.setSpinner(true);
        configuationItemList({}).then(res => {
            if (res?.success) {
                if (res?.payloadMap?.configItemList) {
                    const users = res.payloadMap.configItemList;
                    for (const [id, name] of Object.entries(users)) {
                        usersList.push({ Id: id, Name: name });
                    }
                    this.ticketCreatorData.configuationItemList = [...usersList];
                    this.ticketCreatorData.filteredconfiguationItemList = [...usersList];
                }
            } else {
                this.showToast(res.message, '', 'error');
            }
        }).catch(error => {
            this.setSpinner(false);
            this.showToast(error, '', 'error');
        })
    }

    handleLookupChange(event) {
        const selection = JSON.parse((event?.detail?.selection));
        this.ticketCreatorData.selectedUser = { id: selection?.Id, name: selection?.Name };
        this.ticketCreatorData.selectedConfigItem = selection?.Name;
        this.ticketCreatorData.sysId = selection?.Id;

        this.ticketCreatorData.selectedUserName = selection?.Name;
        this.ticketCreatorData.lookUpId = selection?.Id;
    }

async getReporter(serviceName) {
    try {
        const res = await getReporter({ service: serviceName });
        if (res?.success && res.payloadMap?.reporterName) {
            const { property, idProperty } = TicketCreator.getReporterProperties(serviceName),
                   users = res.payloadMap.reporterName;
            this.assignReporterData(users, property, idProperty);
        }
    } catch (error) {
        this.handleReporterError(error);
    }
}
static getReporterProperties(serviceName) {
    if (serviceName === 'Jira') {
        return { idProperty: 'reporterId',property: 'reporter' };
    }
    return { idProperty: 'callerId',property: 'caller' };
}
assignReporterData(users, property, idProperty) {
    for (const [id, name] of Object.entries(users)) {
        this.ticketCreatorData[property] = name;
        this.ticketCreatorData[idProperty] = id;
    }
}
handleReporterError(error) {
    this.showToast(error, '', 'error');
    this.setSpinner(false);
}
setDefaultInputValues() {
    for (let ii = 0; ii < this.ticketCreatorData.fieldsList.length; ii+=ONE) {
        const field = this.ticketCreatorData.fieldsList[ii];
        this.applyDefaultInputValue(field);
    }
}

applyDefaultInputValue(field) {
    const item = field.name;
    if (item === 'assignee' || item === 'assigned_to' || item === 'System.AssignedTo') {
    } else if (item === 'reporter') {
        field.value = this.ticketCreatorData.reporter;
        this.ticketCreatorData.inputValues = {
            ...this.ticketCreatorData.inputValues,
            [item]: this.ticketCreatorData.reporterId
        };
        field.view = true;
    } else if (item === 'caller_id') {
        field.value = this.ticketCreatorData.caller;
        this.ticketCreatorData.inputValues = {
            ...this.ticketCreatorData.inputValues,
            [item]: this.ticketCreatorData.callerId
        };
        field.view = true;
    } else if (item === 'issuetype') {
        field.view = true;
    } else {
        field.view = false;
    }
} 
onInput(event) {
        const index = event?.currentTarget?.dataset?.index,
            value = event?.target?.value;
        if (index) {
            this.ticketCreatorData.fieldsList[index].value = value;
        } else {
            this.ticketCreatorData.description.value = value;
        }
        this.ticketCreatorData.inputValues = { ...this.ticketCreatorData.inputValues, [event?.target?.name]: value };

}
createTicket() {
    sessionStorage.removeItem('project');
    if (this.validateInputs()) {
        this.setSpinner(true);
        var data = {
            templateId: this.ticketCreatorData?.selectedTemplateId,
            projectKey: this.ticketCreatorData?.selectedProjectKey,
            projectName: this.ticketCreatorData?.selectedProject,
            valuesMap: JSON.parse(JSON.stringify(this.ticketCreatorData?.inputValues)),
            configItemId: this.ticketCreatorData.sysId,
            assigneeName:this.ticketCreatorData?.selectedUserName
        };

        if (this.ticketCreatorData?.selectedService == 'Jira') {
           let cleanedInputValues = { ...this.ticketCreatorData?.inputValues, 'assignee': this.ticketCreatorData?.lookUpId };
            const forbiddenFields = [
                'Microsoft.VSTS.Common.Priority',
                'System.State',
                'System.AssignedTo',
                'caller_id',
                'Configuration item'
            ];
            for (const field of forbiddenFields) {
                delete cleanedInputValues[field];
            }
             if (this.userEmail !== this.serviceEmail) {
                const note = `\n*Note: This issue was created from Salesforce. Reported by Salesforce user: ${this.currentUserName} (${this.userEmail}).*`;
                if (cleanedInputValues.description) {
                    cleanedInputValues.description += note;
                } else {
                    cleanedInputValues.description = note;
                }
                console.log('Updated description:', cleanedInputValues['description']);
            }
            data.valuesMap = JSON.parse(JSON.stringify(cleanedInputValues));
            console.log('before send the data',JSON.stringify(data) );
            createJiraTicket({ ticketInputs: JSON.stringify(data) }).then(res => {
                console.log('res from after created the ticket',res);
                this.handleTicketResonse(res);
            }).catch(err => {
                this.setSpinner(false);
                this.showToast(err, '', 'error');
            });
        }

        else if (this.ticketCreatorData?.selectedService === 'Azure Devops') {
            let cleanedInputValues = { ...this.ticketCreatorData?.inputValues, 'System.AssignedTo': this.ticketCreatorData.lookUpId };
            const forbiddenFields = ['caller_id', 'Configuration item','issuetype','priority'];
            for (const field of forbiddenFields) {
                delete cleanedInputValues[field];
            }
              if (this.userEmail === this.serviceEmail) {
                 const note = `<p><b>Note: This issue was created from Salesforce. Reported by Salesforce user: ${this.currentUserName} (${this.userEmail}).</b></p>`;
                if (cleanedInputValues.description) {
                    cleanedInputValues.description += note;
                } else {
                    cleanedInputValues.description = note;
                }
                console.log('Updated description:', cleanedInputValues['description']);
            }
            data.valuesMap = JSON.parse(JSON.stringify(cleanedInputValues));
           console.log('before send the data',JSON.stringify(data) );
            createAzureTicket({ ticketInputs: JSON.stringify(data) }).then(res => {
                console.log('Created Record ID:', res?.payloadMap?.recordId);
                this.handleTicketResonse(res);
            }).catch(err => {
                this.setSpinner(false);
                this.showToast(err, '', 'error');
            });
        }

        else if (this.ticketCreatorData?.selectedService === 'ServiceNow') {
            let cleanedInputValues = { ...this.ticketCreatorData?.inputValues, 'assigned_to': this.ticketCreatorData.lookUpId };
            const forbiddenFields = [
                'Microsoft.VSTS.Common.Priority',
                'System.State',
                'System.AssignedTo'
            ];
            for (const field of forbiddenFields) {
                delete cleanedInputValues[field];
            }
            if (this.userEmail !== this.serviceEmail) {
                const note = `  [Note: This issue was created from Salesforce. Reported by Salesforce user: ${this.currentUserName} (${this.userEmail})]`;
                
                if (cleanedInputValues.description) {
                    cleanedInputValues.description += note;
                } else {
                    cleanedInputValues.description = note;
                }

                console.log('Updated description for Service:', cleanedInputValues['description']);
            }
            data.valuesMap = JSON.parse(JSON.stringify(cleanedInputValues));
           console.log('before send the data',JSON.stringify(data) );
            createServiceNowTicket({ ticketInputs: JSON.stringify(data) }).then(res => {
                this.handleTicketResonse(res);
            }).catch(err => {
                this.setSpinner(false);
                this.showToast(err, '', 'error');
            });
        }
    } else {
        this.setSpinner(false);
        this.showToast('Error!', 'Ticket cannot be created, please check the mandatory fields.', 'error');
    }

}

 validateInputs() {
    var result = true;
    this.ticketCreatorData?.fieldsList?.forEach(field => {
        const value = this.ticketCreatorData?.inputValues?.[field?.name];
        if (field?.required && value == null) {
            console.warn(`Missing required field: ${field?.name}`);
            result = false;
        }
    });

    const descRequired = this.ticketCreatorData?.description?.required;
    const descValue = this.ticketCreatorData?.inputValues?.description;
    if (descRequired && descValue == null) {
        result = false;
    }

    const configItemRequired = this.ticketCreatorData?.configItem?.required;
    const selectedConfigItem = this.ticketCreatorData?.selectedConfigItem;
    if (configItemRequired && selectedConfigItem == null) {
        console.warn('Missing required config item');
        result = false;
    }
    return result;
}

    handleTicketResonse(res) {
        const contentDocumentIds = [];
        if (res?.success) {

                const recordId = res?.payloadMap?.recordId,
                      recordUrl = `/lightning/r/Bug_Tracking__c/${recordId}/view`;
                this.showToast('Ticket Created Successfully', '', 'success', recordUrl, 'View Ticket');

            this.ticketCreatorData.uploadedFiles.forEach(ele => {
                contentDocumentIds.push(ele?.documentId);
            })
            this.deleteAttachments(contentDocumentIds, true);

        } 
        else {
            this.showToast('Please refer to the documentation on how to set input values for this field.');
        }
        this.setSpinner(false);
    }
async handleUploadFinished(event) {
    const MAX_FILE_SIZE = THREE * BYTE_VALUE * BYTE_VALUE,
          MAX_TOTAL_SIZE = TWELVE * BYTE_VALUE * BYTE_VALUE,
          UploadedFiles = event?.detail?.files || [],
          existingFiles = this.ticketCreatorData?.uploadedFiles 
                        ? [...this.ticketCreatorData.uploadedFiles] 
                        : [],
         successfullyUploaded = [],
         templateId = this.ticketCreatorData?.selectedTemplateId;
    if (!this.templateFileSizeMap[templateId]) {
        this.templateFileSizeMap[templateId] = 0;
    }

    let totalSizeBytes = this.templateFileSizeMap[templateId];

    // Process all files in parallel
    const processedFiles = await Promise.all(
        UploadedFiles.map(async (file) => {
            try {
                const asizeInBytes = await getDocumentSize({ docId: file.documentId });
                const finalFile = {
                    ...file,
                    contentSize: asizeInBytes,
                    url: fileIcons + TicketCreator.getFileIconClass(file)
                };

                if (asizeInBytes > MAX_FILE_SIZE) {
                    await deleteAttachment({ contentDocumentIds: [file.documentId] });
                    this.showToast('Error', `File "${file.name}" exceeds 3MB limit and was not uploaded.`, 'error');
                    return null;
                }

                if ((totalSizeBytes + asizeInBytes) > MAX_TOTAL_SIZE) {
                    await deleteAttachment({ contentDocumentIds: [file.documentId] });
                    this.showToast('Error', `Total file limit of 12MB exceeded. File "${file.name}" was not added.`, 'error');
                    return null;
                }

                totalSizeBytes += asizeInBytes;
                successfullyUploaded.push(file.name);
                return finalFile;

            } catch (ex) {
                TicketCreator.safeLog(`❌ Error processing file "${file.name}":`, ex);
                this.showToast('Error', `Unexpected error uploading "${file.name}".`, 'error');
                return null;
            }
        })
    );

    // Keep only valid files
    const validFiles = processedFiles.filter(ff => ff !== null);

    if (successfullyUploaded.length > ZERO) {
        this.ticketCreatorData.uploadedFiles = [...existingFiles, ...validFiles];
        this.deleteCacheAttachment = this.ticketCreatorData.uploadedFiles;

        this.templateFileSizeMap[templateId] = totalSizeBytes;

        const fileList = successfullyUploaded.join(', ');
        this.showToast('Success', `Uploaded: ${fileList}`, 'success');
    }
}


  deleteCacheFiles() {
    const contentDocumentIds = (this.deleteCacheAttachment || []).map(file => file.documentId),
          files              = this.deleteCacheAttachment || [];

    if (!files.length) {
        TicketCreator.safeLog('No files found in cache.');
        return;
    }


    deleteAttachment({ contentDocumentIds })
        .then(() => {
            this.deleteCacheAttachment = [];
        })
        .catch(error => {
            TicketCreator.safeLog('Error deleting cache attachments:', error);
        });
}
    getSelectedTemplateAttachments() {
        getUploadedAttachments({ recordId: this.ticketCreatorData?.selectedTemplateId }).then(res => {
            if (res?.success) {     
                if (res?.payloadMap?.jiraAttachments) {
                    const MAX_FILE_SIZE = THREE * BYTE_VALUE * BYTE_VALUE,
                          MAX_TOTAL_SIZE = TWELVE * BYTE_VALUE * BYTE_VALUE,
                          acceptedFiles = [],
                          files = JSON.parse(JSON.stringify(res?.payloadMap?.jiraAttachments || [])),
                          filesToDelete = [];

                    let totalSize = ZERO;
                    this.deleteCacheAttachment = files;

              for (const file of files) {
                      const size = file.contentFileSize || ZERO;

                    if (size > MAX_FILE_SIZE) {
                                    filesToDelete.push(file.documentId);
                                    this.showToast('Error', `File "${file.name}" exceeds 3MB limit and was not added.`, 'error');
                    }

                    if ((totalSize + size) <= MAX_TOTAL_SIZE) {
                        totalSize += size;
                        acceptedFiles.push(file);
                    } else {
                        filesToDelete.push(file.documentId);
                        this.showToast('Error', `File "${file.name}" could not be added as total file size would exceed 12MB.`, 'error');
                    }
              }

                if (filesToDelete.length > ZERO) {
                    deleteAttachment({ contentDocumentIds: filesToDelete });
                }


                  this.templateFileSizeMap[this.ticketCreatorData?.selectedTemplateId] = totalSize;
                  this.ticketCreatorData.uploadedFiles = [...acceptedFiles];

                  if (acceptedFiles.length > ZERO) {
                         const uploadedFileNames = acceptedFiles.map(ff => ff.name).join(', ');
                         this.showToast('Success',`Successfully retrieved the uploaded files: ${uploadedFileNames}`,'success');
                    }
                 this.ticketCreatorData.uploadedFiles?.forEach(ele => {
                 ele.iconName = TicketCreator.getIconName(ele.type);
                 ele.isVideo = ['webm', 'mp4'].includes(ele.type);

                if (['png', 'jpg', 'jpeg'].includes(ele.type)) {
                         ele.url = res?.payloadMap?.pngBaseUrl + ele.fileContent;
                 } else if (['webm', 'mp4'].includes(ele.type)) {
                         ele.url = `/sfc/servlet.shepherd/version/download/${ele.contentVersionId}`;
                      
                  }
              });

                }
                if (res?.payloadMap?.thumbnailURL) {
                    this.ticketCreatorData.thumbnailURL = res?.payloadMap?.thumbnailURL;
                }
                if (this.ticketCreatorData.filteredconfiguationItemList === false){
                    this.setSpinner(false);
                }
                
            } else {
                this.showToast(res?.message, 'getSelectedTemplateAttachments', 'error');
            }

        }).catch(err => {
            this.showToast(err, '', 'error');
            this.setSpinner(false);
        })
    }

   handleRemoveAttachment(event) {
    const  UploadedFiles = this.ticketCreatorData.uploadedFiles,
            contentDocId = event?.currentTarget?.dataset?.contentdocumentid,
            index = UploadedFiles.findIndex(file => file.documentId === contentDocId),
           templateId = this.ticketCreatorData?.selectedTemplateId;

    if (index === NEGATIVE_ONE) {
        TicketCreator.safeLog('❌ File not found for contentDocId:', contentDocId);
    } 
    else{
         const aremovedFile = UploadedFiles[index],
              currentSize = this.templateFileSizeMap[templateId] || ZERO,
              fileSize = aremovedFile?.contentSize ?? aremovedFile?.contentFileSize ?? aremovedFile?.size ?? ZERO;

        let updatedSize = currentSize - fileSize;
        if(updatedSize < ZERO){
            updatedSize = ZERO;
        }
        this.templateFileSizeMap[templateId] = updatedSize;

        UploadedFiles.splice(index, ONE);
    }

    this.deleteAttachments(contentDocId, false);
}

    deleteAttachments(contentDocumentIds, clear) {
        this.setSpinner(true);
        deleteAttachment({ contentDocumentIds }).then(res => {  
            if (res?.success) {
                if (res?.payloadMap?.message) {
                    if (clear) {
                        const value = 'Testing Application',
                              valueChangeEvent = new CustomEvent("valuechange", {
                            detail: { value }
                        });
                        this.dispatchEvent(valueChangeEvent);
                    }
                }
            } else {
                this.showToast(res?.message, '', 'error');
            }
        }).catch(err => {
            this.setSpinner(false);
            this.showToast(err, '', 'error');
        })
        this.setSpinner(false);
    }

    
    static getIconName(extension) {
        if (extension) {
            switch (extension) {
                case "pdf":
                    return "doctype:pdf";
                case "ppt":
                    return "doctype:ppt";
                case "xls":
                    return "doctype:excel";
                case ".xlsx":
                    return "doctype:excel";
                case "csv":
                    return "doctype:csv";
                case "doc":
                    return "doctype:word";
                case "mp4":
                case 'webm':
                    return "doctype:video";
                case "txt":
                    return "doctype:txt";
                case "rtf":
                    return "doctype:rtf";
                default:
                    return "doctype:image";
            }
        }
        return "doctype:image";
    }
    previewFileFromThumbNail(event) {
        this[NavigationMixin.Navigate]({
            attributes: {
                pageName: 'filePreview'
            },
            state: {
                selectedRecordId: event?.target?.dataset?.id
            },
            type: 'standard__namedPage'
        })

    }

  showToast(title, message, variant, url = null, label = 'Click here to view') {
    const options = {
        title,   
        variant  
    };
    if (url) {
        options.message = '{0}';
        options.messageData = [{ label,url }]; 
    } else if (message) {
        options.message = message;
    } else {
        options.message = ' ';
    }
    this.dispatchEvent(new ShowToastEvent(options));
}


    maxLengthvalid() {
        if (this.ticketCreatorData?.selectedService === 'ServiceNow') {
            this.maxLength = ONE_SIXTY;
        }
        else {
            this.maxLength = 255;
            setTimeout(() => {
                this.setSpinner(false);
                }, THOUSAND_FIVE_HUNDRED);
        }
    }
    static getFileIconClass(file) {
        const extension = file.name.split('.').pop().toLowerCase();
        switch (extension) {
            case 'pdf':
                return '/fileIcons/pdfIcon.png';
            case 'jpg':
                return '/fileIcons/jpgIcon.png';
            case 'jpeg':
                return '/fileIcons/jpegIcon.png';
            case 'png':
                return '/fileIcons/picture.png';
            case 'ppt':
                return '/fileIcons/pptIcon.png';
            case 'doc':
            case 'docx':
                return '/fileIcons/docsIcon.png';
            case 'xls':
            case 'xlsx':
                return '/fileIcons/xlsIcon.png';
            case 'txt':
                return '/fileIcons/txtIcon.png';
            case 'mp4':
            case 'webm':
                return '/fileIcons/video.png';
            case 'rtf':
                return '/fileIcons/rtfIcon.png';
            default :
                return '/fileIcons/defaultIcon.png'; 
        }
    }
    extnScreencapture() {
        const aa = this.template.querySelector('[data-name="captureimage"]'),
            styles = window.getComputedStyle(aa);
        if (styles.color === 'rgb(0, 128, 0)') {
           //Empty if block
        } else {
            const { userAgent } = navigator;
            if (userAgent.match(/edg/iu)) {
                this.showToast("Please click Add Extension Button to Install the Salesforce Capture Annotation Tools in edge Extension", '', 'warning');
                window.open('https://microsoftedge.microsoft.com/addons/detail/jpemkciihdbcfieofmbjmhhpgpjdedbn', "_blank");
            }
            else if (userAgent.match(/chrome|chromium|crios/iu)) {
                this.showToast("Please click Add Extension Button to Install the Salesforce Capture Annotation Tools in chrome Extension", '', 'warning');
                window.open('https://chromewebstore.google.com/detail/raiseitnow/oglcclmebmocihooogealjaadbmcheeo', "_blank");
            }
            else if (userAgent.match(/firefox|fxios/iu)) {
                this.showToast("Please click Add Extension Button to Install the Salesforce Capture Annotation Tools in firefox Extension", '', 'warning');
                window.open('https://addons.mozilla.org/en-US/firefox/addon/raise-issue-capture-annotation/', "_blank");
            }
            else {
                this.showToast("Sorry,Salesforce Capture Annotation Tools not available for this browser.", '', 'warning');
            }
        }
    }

    recordExtnScreencapture() {
        const aa = this.template.querySelector('[data-name="recordimage"]'),
            styles = window.getComputedStyle(aa);
        if (styles.color === 'rgb(0, 128, 0)') {
         //Empty if block
        } else {
            const { userAgent } = navigator;
            if (userAgent.match(/edg/iu)) {
                this.showToast("Please click Add Extension Button to Install the Salesforce Capture Annotation Tools in edge Extension", '', 'warning');
                window.open('https://microsoftedge.microsoft.com/addons/detail/jpemkciihdbcfieofmbjmhhpgpjdedbn', "_blank");
            }
            else if (userAgent.match(/chrome|chromium|crios/iu)) {
                this.showToast("Please click Add Extension Button to Install the Salesforce Capture Annotation Tools in chrome Extension", '', 'warning');
                window.open('https://chromewebstore.google.com/detail/raiseitnow/oglcclmebmocihooogealjaadbmcheeo', "_blank");
            }
            else if (userAgent.match(/firefox|fxios/iu)) {
                this.showToast("Please click Add Extension Button to Install the Salesforce Capture Annotation Tools in firefox Extension", '', 'warning');
                window.open('https://addons.mozilla.org/en-US/firefox/addon/raise-issue-capture-annotation/', "_blank");
            }
            else {
                this.showToast("Sorry,Salesforce Capture Annotation Tools not available for this browser.", '', 'warning');
            }
        }
    }

     getJiraUsersList() {
        const action = getJiraUsersList({}),
               usersList = [];
        this.setSpinner(true);
        
        action.then(res => {
            if(res?.success) {
                if(res?.payloadMap?.UsersList){
                    res?.payloadMap?.UsersList?.forEach(ele => {
                        if(ele?.accountType === "atlassian") {
                            usersList.push({  Id: ele?.accountId ,Name: ele?.displayName});
                        }
                    });
                    this.ticketCreatorData.userLookupList = [...usersList];
                    this.ticketCreatorData.selectedUserName = this.ticketCreatorData.selectedAssinee;
                    this.ticketCreatorData.lookUpId = this.ticketCreatorData.selectedUserId;
                }
                
            } else {
                this.showToast(res.message,'','error');
            }
        }).catch(error => {
            this.showToast(error,'','error');
            this.setSpinner(false);
      });
    }
    getAzureUsersList() {
        const action = getAzureTeams({projectId:this.ticketCreatorData.selectedProjectKey}),
              usersList = [];
        this.setSpinner(true);

        action.then(res => {
            if (res?.success) {
                if (res?.payloadMap?.Users) {
                    const users = res.payloadMap.Users;
                    for (const [name, id] of Object.entries(users)) {
                        usersList.push({ Id: id ,Name: name });
                    }
                }
                this.ticketCreatorData.userLookupList = [...usersList];
                this.ticketCreatorData.selectedUserName = this.ticketCreatorData.selectedAssinee;
                this.ticketCreatorData.lookUpId = this.ticketCreatorData.selectedUserId;  
            } else {
                this.showToast(res.message,'','error');
            }
        }).catch(error => {
            this.showToast(error,'','error');
            this.setSpinner(false);
        })
    }
    getServiceNowLookupList() {
        const usersList = [];
        this.setSpinner(true);
        getServiceNowLookup({fieldName : 'assigned_to'}).then(res => {
            if(res?.success) {
                if(res?.payloadMap?.serviceNowLookupList){
                    const users = res.payloadMap.serviceNowLookupList;
                    for (const [name, id] of Object.entries(users)) {
                        usersList.push({ Id: id,Name: name  });
                    }
                    this.ticketCreatorData.userLookupList = [...usersList];
                    this.ticketCreatorData.selectedUserName = this.ticketCreatorData.selectedAssinee;
                    this.ticketCreatorData.lookUpId = this.ticketCreatorData.selectedUserId;
                }
               
            } else {
                this.showToast(res.message,'','error');
            }
        }).catch(error => {
            this.showToast(error,'','error');
            this.setSpinner(false);
        })
    }
    
}