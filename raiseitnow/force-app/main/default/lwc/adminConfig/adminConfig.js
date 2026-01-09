import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadScript } from 'lightning/platformResourceLoader';
import AZURELOGO from '@salesforce/resourceUrl/AzureLogo';
import CREATE_ANIM from '@salesforce/resourceUrl/createTemplate';
import DELETE_ANIM from '@salesforce/resourceUrl/RemoveTemplate';
import JiraLogo from '@salesforce/resourceUrl/JiraLogo';
import LOTTIE_WEB from '@salesforce/resourceUrl/lottie';
import ServiceNowLogo from '@salesforce/resourceUrl/ServiceNowLogo';
import deleteTemplate from '@salesforce/apex/AdminController.deleteTemplate';
import deleteTemplates from '@salesforce/apex/ServiceTemplateHandler.deleteTemplates';
import getAzureTeams from '@salesforce/apex/ExternalUserIntegrationService.getAzureTeams';
import getCurrentUserName from '@salesforce/apex/AdminController.getCurrentUserName';
import getJiraUsersList from '@salesforce/apex/ExternalUserIntegrationService.getJiraUsersList';
import getProjectsForService from '@salesforce/apex/ProjectMetadataSyncService.getProjectsForService';
import getRaiseItNowConnectionStatus from '@salesforce/apex/ConnectionHandler.getRaiseItNowConnectionStatus';
import getServiceNowLookup from '@salesforce/apex/ExternalUserIntegrationService.serviceNowLookup';
import getTemplateDetails from '@salesforce/apex/AdminServiceTemplateHelper.getTemplateDetails';
import projFieldsList from '@salesforce/apex/ProjectFieldService.projFieldsList';
import saveMultipleTemplateDataSimple from '@salesforce/apex/ServiceTemplateHandler.saveMultipleTemplateDataSimple';
import saveTemplateData from '@salesforce/apex/AdminController.saveTemplateData';
import syncMetadataForService from '@salesforce/apex/ProjectMetadataSyncService.syncMetadataForService';
const animationDuration = 1000,defaultFps=60, emptyCount = 0,fiveCount = 5,minusOne = -1,msinSeconds=1000,oneCount = 1,twoCount = 2;

/* eslint-disable new-cap */
export default class AdminConfig extends NavigationMixin(LightningElement) {
/* eslint-enable new-cap */
jiraLogo = JiraLogo;
azureLogo = AZURELOGO;
serviceNowLogo = ServiceNowLogo;
pillPageSize = fiveCount;

@track isInitialLoadSubmitDone = false;
@track showServicePopup = false;
@track selectedServiceName = '';
@track selectedProjects = new Set(); 
@track showTable = false;           
@track selectedProjectKey = '';        
@track tableData = [];
@track firstTimeFlags = {
        'Azure Devops': false,
        Jira: false,
        ServiceNow: false
    };
@track serviceWiseTableData = {
         'Azure Devops': [],
          Jira: [],
          ServiceNow: []
    };
@track selectedProjectsMap = {
           'Azure Devops': new Set(),
            Jira: new Set(),
            ServiceNow: new Set() 
    };
@track adminConfigData = {
        recordsFound: true,
        selectedService: 'Jira',
        templateModal: false,
        templates: [],
    }
@track isSpinner = false;
@track searchLoading = false;
@track popupMultiSelectOptions = [];    
@track popupMultiSelectSelected = [];     
@track availableSearchText = ''; 
@track showTemplateMessage = false;
@track isCreateSuccess = false;
@track isDeleteSuccess = false;
@track currentPillPage = emptyCount;
@track showDropdown = false;
@track isAddProjectDisabled = false;
@track showAuthMessage = false;

get jiraClass() {
    if (this.adminConfigData.selectedService === 'Jira') {
        return 'active';
    }
    return '';
}
get azureClass() {
    if (this.adminConfigData.selectedService === 'Azure Devops') {
        return 'active';
    }
    return '';
}
get snClass() {
    if (this.adminConfigData.selectedService === 'ServiceNow') {
        return 'active';
    }
    return '';
}
get ServiceNowDisable() {
    return this.adminConfigData.selectedService === 'ServiceNow';
}
get totalPages() {
    return Math.ceil(this.popupMultiSelectSelected.length / this.pillPageSize);
}

get hasPrev() {
    return this.currentPillPage > emptyCount;
}

get noPrev() {
    return !this.hasPrev;
}

get noNext() {
    return !this.hasNext;
}

get hasNext() {
    return this.currentPillPage < this.totalPages - oneCount;
}
get hasAnyTemplate() {
        return this.tableData.some(item => item.hadTemplate);
    }
get pageNumbers() {
    const current = this.currentPillPage,
          pageItems = [],
          total = this.totalPages;
   if (total <= twoCount) {

     AdminConfig.addInitialPages(pageItems, current, total);
     return pageItems;
  }
    // Always show current page
pageItems.push({
        className: 'page-adv-btn active-adv',
        id: current,
        label: current + oneCount,
    });

    AdminConfig.addNextPages(pageItems, current, total);
    return pageItems;
}
get filteredAvailableOptions() {
    const searchText = this.availableSearchText?.toLowerCase() || '';
    return this.popupMultiSelectOptions
        .filter(opt => !this.popupMultiSelectSelected.includes(opt.value))
        .filter(opt => opt.label.toLowerCase().includes(searchText));
}

get isNoMatch() {
    return this.filteredAvailableOptions.length === emptyCount;
}
get paginatedSelectedProjects() {
    const end = this.currentPillPage * this.pillPageSize + this.pillPageSize,
          map = new Map(this.popupMultiSelectOptions.map(opt => [opt.value, opt.label])),
          start = this.currentPillPage * this.pillPageSize;

    return this.popupMultiSelectSelected.slice(start, end).map(val => ({
        label: map.get(val),
        value: val,
    }));
}

handleAddProject() {
    this.setSpinner(true);
    this.selectedServiceName = this.adminConfigData.selectedService;
    // If templates are not loaded yet, fetch them first
    if (!this.adminConfigData.templates || this.adminConfigData.templates.length === emptyCount) {
        getTemplateDetails({ serviceName: this.selectedServiceName }).then((res) => {
            if (res?.success) {
                const selectedKeys = this.selectedProjectsMap[this.selectedServiceName] || new Set(),
                      templates = res.payloadMap?.templates || [];
                this.adminConfigData.templates = templates;
                this.popupMultiSelectOptions = templates.map(proj => ({
                    label: proj.projectName,
                    value: proj.projectKey
                }));
                this.popupMultiSelectSelected = [...selectedKeys];
                 this.currentPillPage = 0;
                this.showServicePopup = true;
            } else {
                this.showToast(res.payloadMap.message || 'Failed to fetch templates', '', 'error');
            }
            this.setSpinner(false);
        }).catch((err) => {
            this.showToast(err?.body?.message || 'Unexpected error', '', 'error');
            this.setSpinner(false);
        });
    } else {
        this.popupMultiSelectOptions = this.adminConfigData.templates.map(proj => ({
            label: proj.projectName,
            value: proj.projectKey
        }));

        const selectedKeys = this.selectedProjectsMap[this.selectedServiceName] || new Set();
        this.popupMultiSelectSelected = [...selectedKeys];
         this.currentPillPage = 0;
        this.showServicePopup = true;
        this.setSpinner(false);
    }
}

setSpinner(state) {
    this.isSpinner = state;
 }

connectedCallback() {
    this.setSpinner(true);
    getCurrentUserName()
        .then(userName => this.initializeServices(userName))
        .catch(() => this.handleConnectionError());
}

initializeServices(userName) {
    this.currentUserName = userName;
    const services = ['Jira', 'ServiceNow', 'Azure Devops'];

    Promise.all(services.map(service => this.loadServiceProjects(service)))
        .then(results => {
            const hasSavedData = results.includes(true);
            this.afterProjectsLoaded(hasSavedData);
        });
}

loadServiceProjects(service) {
    const existingKeys = this.selectedProjectsMap[service];
    if (existingKeys && existingKeys.size > emptyCount) {
        this.getTemplateDetailsFromKeys(service, existingKeys);
        this.firstTimeFlags[service] = true;
        return Promise.resolve(true);
    }

    return getProjectsForService({ serviceName: service })
        .then(keys => {
            if (keys && keys.length > emptyCount) {
                const keySet = new Set(keys);
                this.selectedProjectsMap[service] = keySet;
                this.firstTimeFlags[service] = true;
                this.getTemplateDetailsFromKeys(service, keySet);
                return true;
            }
            return false;
        });
}

afterProjectsLoaded(hasSavedData) {
    this.selectedServiceName = this.adminConfigData.selectedService;
    //  Only one checkConnection() before verifying status
    this.checkConnection();

    getRaiseItNowConnectionStatus({ serviceName: this.selectedServiceName })
        .then(res => this.handleConnectionResponse(res, hasSavedData))
        .catch(() => this.handleConnectionError());
}

handleConnectionResponse(res, hasSavedData) {
    this.setSpinner(false);
    if (res?.success) {
        this.isAddProjectDisabled = false;
        this.showAuthMessage = false;
        this.showServicePopup = !hasSavedData;
        this.showTable = hasSavedData;
        // re-check if you want UI to refresh again after success
         this.checkConnection();
    } else {
        this.disableAndCleanUp();
    }
}

handleConnectionError() {
    this.isAddProjectDisabled = true;
    this.showAuthMessage = true;
    this.showTable = false;
    this.setSpinner(false);
}

disableAndCleanUp() {
    this.isAddProjectDisabled = true;
    this.showAuthMessage = true;
    this.showTable = false;
    deleteTemplates({ templateName: this.selectedServiceName });
}

getTemplateDetailsFromKeys(service, keysSet) {
    const parseDate = (dd) => {
                    if (!dd || dd === '-' || dd === ' - ') {return null};
                    const parsed = new Date(dd);
                    if (isNaN(parsed.getTime())) {return null;}
                    return parsed;
                };
    getTemplateDetails({ serviceName: service }).then((res) => {
        if (res?.success) {
            const sortedTemplates = AdminConfig.sortTemplatesByDate(AdminConfig.processTemplates(res.payloadMap?.templates || [], keysSet), parseDate);  
            this.serviceWiseTableData[service] = [...sortedTemplates];
            if (this.selectedServiceName === service) {
                this.tableData = [...sortedTemplates];
                this.adminConfigData.filtered = [...sortedTemplates];
            }
            this.setSpinner(false);
        } else {
            this.showToast(res.payloadMap.message, '', 'error');
            this.setSpinner(false);
        }
    }).catch(error => {
        this.showToast(error, '', 'error');
        this.setSpinner(false);
    });
}

static processTemplates(templates, keysSet) {
    let formattedDate='';
    return templates
        .filter(template => keysSet.has(template.projectKey))
        .map(template => {
            const isMissing = !template.createdDate || template.createdDate === '-' || template.createdDate === ' - ',
                 rawDate = template.createdDate;    
            if (isMissing) {
                formattedDate = ' - ';
            } else {
                formattedDate = new Date(rawDate.replace(' ', 'T')).toISOString();
            }
            return {
                ...template,
                checked: true,
                createdDate: formattedDate,
                isDates: isMissing
            };
        });
}

static sortTemplatesByDate(templates, parseDate) {
    return templates.sort((aa, bb) => AdminConfig.compareTemplateDates(aa, bb, parseDate));
}
static compareTemplateDates(aa, bb, parseDate) {
    const aDate = parseDate(aa.createdDate),
          bDate = parseDate(bb.createdDate);
    if (aDate && !bDate) { return minusOne;}
    if (!aDate && bDate) {return oneCount;} 
    if (aDate && bDate) { return bDate - aDate;}
    return emptyCount;
}

 checkConnection() {
        this.setSpinner(true);
        getRaiseItNowConnectionStatus({ serviceName: this.adminConfigData.selectedService }).then((res) => {
            if (res?.success) {
                this.getTemplateDetails();
            } else {
                this.adminConfigData = {
                    filtered: [],
                    recordsFound: false,
                    searchProj: this.adminConfigData?.searchProj,
                    selectedService: this.adminConfigData?.selectedService,
                    templateModal: false,
                    templates: [],
                }
                this.setSpinner(false);
            }
        }).catch(error => {
            this.showToast(error,'','error');
            this.setSpinner(false);
        })
    }

onServiceSelection(event) {
    this.setSpinner(true);
    const clickedService = event?.currentTarget?.dataset?.value;
    this.adminConfigData.selectedService = clickedService;
    this.selectedServiceName = clickedService;
    this.checkConnection();

    getRaiseItNowConnectionStatus({ serviceName: this.selectedServiceName })
      .then(res => {
         if (res?.success) {
             this.isAddProjectDisabled = false;
             this.showAuthMessage = false;
             this.handleRaiseItNowSuccess(clickedService);
         } else {
             this.disableAndCleanUp();      
         }

         this.setSpinner(false);
     })
      .catch(() => {
         this.handleConnectionError();
     });
}
handleRaiseItNowSuccess(clickedService) {
    const hasAlreadySubmitted = this.firstTimeFlags[clickedService];

    if (hasAlreadySubmitted) {
        this.tableData = [...(this.serviceWiseTableData[clickedService] || [])];
        this.showServicePopup = false;
        this.showTable = true;
    } else {
        this.showServicePopup = true;
        this.showTable = false;
        this.selectedProjects = new Set();
        this.tableData = [];
        this.checkConnection();
    }
}

static stopEventPropagation(event) {
        event.stopPropagation();
    }

getTemplateDetails() {
    if (!this.adminConfigData?.selectedService) {
        return;
    }
    this.setSpinner(true);
    const parseDate = (dd) => {
            if (!dd || dd === '-' || dd === ' - '){return null};
            const parsed = new Date(dd);
            if (isNaN(parsed.getTime())) {return null;}
            return parsed;
        };
    getTemplateDetails({ serviceName: this.adminConfigData?.selectedService })
        .then((res) => {

             this.handleTemplateResponse(res,parseDate);
             if (this.adminConfigData?.searchProj) { this.searchProjects({ target: { value: this.adminConfigData?.searchProj } });}
             if (!this.firstTimeFlags[this.adminConfigData.selectedService]) { this.handleAddProject(); }
             this.setSpinner(false);
        })
        .catch((error) => {
            this.showToast(error, '', 'error');
            this.setSpinner(false);
        });
}

handleTemplateResponse(res,parseDate) {
    if (!res?.success) {
        this.showToast(res.payloadMap?.message, '', 'error');
        return;
    }
    const checkedKeys = this.selectedProjectsMap[this.adminConfigData.selectedService] || new Set(),
          sortedTemplates = AdminConfig.sortTemplatesByDate( AdminConfig.processTemplatesWithDynamicCheck(res?.payloadMap?.templates || [], checkedKeys), parseDate);

    this.adminConfigData.templates = sortedTemplates;
    this.adminConfigData.filtered = [...sortedTemplates];
    this.adminConfigData.recordsFound = sortedTemplates.length > emptyCount;

}

static processTemplatesWithDynamicCheck(templates, checkedKeys) {
    let createdDate='';
    return templates.map(item => {
        const dateVal = item.createdDate,
              isDateMissing = !dateVal || dateVal === '-' || dateVal === ' - ';
        if (isDateMissing) { createdDate = ' - '; } 
        else { createdDate = new Date(dateVal.replace(' ', 'T')).toISOString(); }

        return {
            ...item,
            checked: checkedKeys.has(item.projectKey),
            createdDate,
            isDates: isDateMissing,
        };
    });
}

searchProjects(event) {
    this.searchLoading = true;
    const searchVal = event.target.value?.toLowerCase() || '';
    this.adminConfigData.searchProj = searchVal;
    if (searchVal) {
        const sourceList = this.serviceWiseTableData[this.adminConfigData.selectedService] || [];
        this.tableData = sourceList.filter(val =>
            val?.projectName?.toLowerCase().includes(searchVal)
        );
    } else {
        this.tableData = [...this.serviceWiseTableData[this.adminConfigData.selectedService]];
    }
    this.searchLoading = false;
}

getFieldsList(event) { 
    const project = this.initializeAdminConfig(event),
          recordId = event?.currentTarget?.dataset?.recordid,
          selectedService = this.adminConfigData?.selectedService;

    projFieldsList({ projKey: project, selectedServiceName: selectedService })
        .then(res => {
            if (!res?.success) {
                this.showToast(res.payloadMap.message, '', 'error');
                this.handleModalClose();
                this.setSpinner(false);
                return;
            }
            const result = this.getFieldsByService(res, selectedService);
            
            this.setAdminConfigFields(project, recordId, result);
            this.setSpinner(false);
        })
        .catch(error => {
            this.showToast(error,'','error');
            this.setSpinner(false);
        });
}
getFieldsByService(res, selectedService) {
    if (selectedService === 'Jira'){return this.parseJiraService(res);} 
    if (selectedService === 'ServiceNow'){return this.parseServiceNowService(res);} 
    return this.parseAzureService(res);
}
parseJiraService(res) {
    const parsed = AdminConfig.parseJiraFields(res);
    this.getJiraUsersList();
    return parsed;
}

parseServiceNowService(res) {
    const parsed = AdminConfig.parseServiceNowFields(res);
    this.getServiceNowLookupList();
    return parsed;
}

parseAzureService(res) {
    const parsed = AdminConfig.parseAzureFields(res);
    this.getAzureUsersList();
    return parsed;
}

initializeAdminConfig(event) {
    const project = event?.currentTarget?.dataset?.project,
          recordId = event?.currentTarget?.dataset?.recordid;
    this.adminConfigData.projectKey = project;
    this.adminConfigData.projectName = event?.currentTarget?.dataset?.projectname;
    if (recordId) {
        this.adminConfigData.recordId = recordId;
        this.setModalProperties('update', true);
    } else {
        this.setModalProperties('create', true);
    }
    this.resetAdminConfigFields(); 
    return project;
}
resetAdminConfigFields() {
    this.adminConfigData.selectedUserName = null;
    this.adminConfigData.lookUpId = null;
    this.adminConfigData.selectedUser = null;
    this.adminConfigData.fieldsRetrieveing = true;
}

setAdminConfigFields(project, recordId, result) {
    this.adminConfigData.availableFields = JSON.parse(JSON.stringify(result.availableFields));
    this.adminConfigData.fieldsData = JSON.parse(JSON.stringify(result.fieldsData));
    this.adminConfigData.requiredFields = JSON.parse(JSON.stringify(result.requiredFields));

    const selectedFields = this.getSelectedFieldsFromTemplate(project, recordId);
    this.adminConfigData.selectedFields = selectedFields;

    this.adminConfigData.showAssignee = selectedFields.some(element =>
        ['assignee', 'System.AssignedTo', 'assigned_to'].includes(element)
    );

    this.adminConfigData.fieldsRetrieveing = false;
}
static parseJiraFields(res) {
    const availableFields = [],
          jiraResponse = JSON.parse(res?.payloadMap?.JiraResponse),
          requiredFields = [];
    let  fieldsData = {};

    if (jiraResponse?.projects?.length > emptyCount &&
        jiraResponse.projects[emptyCount]?.issuetypes?.length > emptyCount &&
        jiraResponse.projects[emptyCount]?.issuetypes[emptyCount]?.fields
    ) {
        Object.entries(jiraResponse.projects[emptyCount].issuetypes[emptyCount].fields)
            .forEach(([key, value]) => {
                if (![...res.payloadMap.jiraAllowedList].includes(value.name)){ return;}

                const { defaultValue, dropdown, isRequired } = AdminConfig.processJiraFieldDetails({ availableFields ,key ,requiredFields ,value });
                fieldsData = { ...fieldsData, [key]: { defaultValue, dropdown, label: value?.name, name: key, required: isRequired } };
                console.log('OUTPUT : fieldsData',JSON.stringify(fieldsData));
            });
    }

    return { availableFields,fieldsData, requiredFields };
}
static processJiraFieldDetails({ availableFields ,key ,requiredFields ,value }) {
    let dropdown = [];

    if (value?.allowedValues?.length > emptyCount) {
        value.allowedValues.forEach(ele => {
            dropdown.push(ele?.name || ele?.value);
        });
    }

    if (!(dropdown.length > emptyCount)){dropdown = null;} 

    const defaultValue = value?.defaultValue?.name ?? null,
          isRequired = value?.required || key === 'description';

    availableFields.push({ label: value?.name, value: key });
    if (isRequired){requiredFields.push(key);} 

    return { defaultValue, dropdown, isRequired };
}


static parseServiceNowFields(res) {
    const availableFields = [],
          requiredFields = [],
          serviceNowResponse = JSON.parse(JSON.stringify(res?.payloadMap?.ServiceNowResponse));
    let fieldsData = {};

    if (serviceNowResponse?.result?.columns) {
        Object.entries(serviceNowResponse.result.columns).forEach(([key, value]) => {
             if (![...res.payloadMap.serviceNowAllowedList].includes(value.label)){ return;}

            const { dropdown, isRequired } = AdminConfig.processServiceNowFieldDetails({ availableFields ,key ,requiredFields ,value });
            fieldsData = { ...fieldsData, [key]: { dropdown, label: value?.label, name: key, required: isRequired } };
        });
    }

    return { availableFields, fieldsData ,requiredFields };
}
static processServiceNowFieldDetails({ availableFields ,key ,requiredFields ,value }) {
    
     let dropdown = AdminConfig.getValidDropdown(value?.choices);

     if (!(dropdown.length > emptyCount)) {
        dropdown = null;
    }
    
    //  if (value?.mandatory === false){value.mandatory = true;} 
     if (value?.label === 'Short description' || value?.label === 'Description') { value.mandatory = true;}

     const  isRequired = value?.mandatory || value?.label === 'Short description' || value?.label === 'Description';

     if (isRequired){requiredFields.push(key);} 
     availableFields.push({ label: value?.label, value: key });

    return { dropdown, isRequired };
}
static getValidDropdown(values) {
    const dropdown = [];

    if (values?.length > emptyCount) {
        values.forEach(ele => {
            dropdown.push(ele?.value);
        });
    }

    return dropdown;
}

static parseAzureFields(res) {
    const availableFields = [],
          azureResponse = JSON.parse(JSON.stringify(res?.payloadMap?.AzureResponse)),
          requiredFields = [];
    let fieldsData = {};

    azureResponse?.value?.forEach(ele => {
        if (![...res.payloadMap.azureNowAllowedList].includes(ele.name)){ return;}

        const { defaultValue, dropdown, isRequired } = AdminConfig.processAzureFieldDetails({ availableFields ,ele ,requiredFields });

        fieldsData = { ...fieldsData,  [ele?.referenceName]: { defaultValue, dropdown, label: ele?.name, name: ele?.referenceName, required: isRequired } };
    });

    return { availableFields, fieldsData ,requiredFields };
}

static processAzureFieldDetails({ availableFields ,ele ,requiredFields }) {
     let dropdown = [];

    if (ele?.allowedValues?.length > emptyCount){dropdown = [...ele.allowedValues];} 

    const defaultValue = ele?.defaultValue || null,
          isRequired = ele?.alwaysRequired || ele?.name === 'Description';

    if (isRequired){requiredFields.push(ele?.referenceName);} 

    availableFields.push({ label: ele?.name, value: ele?.referenceName });

    return { defaultValue, dropdown, isRequired };
}


getSelectedFieldsFromTemplate(project, recordId) {
    let selectedFields = [];
    if (recordId && this.adminConfigData?.templates) {
        this.adminConfigData.templates.forEach(ele => {
            if (ele.projectKey === project) {
                if (typeof ele?.fieldsJson === 'string') {
                    const parsedFields = JSON.parse(JSON.parse(ele.fieldsJson));
                    if (typeof parsedFields === 'object') {
                        selectedFields = [...Object.getOwnPropertyNames(parsedFields)];
                        if (ele?.lookUpId && ele?.userName) {
                            this.handleLookupChange({ detail: { selection: JSON.stringify({ Id: ele.lookUpId, Name: ele.userName }) } });
                        }
                    }
                }
            }
        });
    }
    return selectedFields;
}

setModalProperties(type, state) {
    this.adminConfigData.templateModal = state;
    if(type === 'create') {
        this.adminConfigData.modalProps = { 
            title: `Configure Template - ${this.adminConfigData.projectName}` 
        };
    } else {
        this.adminConfigData.modalProps = { 
            title: `Update Template - ${this.adminConfigData.projectName}` 
        };
    }
}

    handleModalClose() {
        this.adminConfigData.templateModal = !this.adminConfigData.templateModal;
    }
    onFieldSelect(event) {
        this.adminConfigData.selectedFields = event.detail.value;
        this.adminConfigData.showAssignee = this.adminConfigData?.selectedFields.some(element => ['assignee', 'System.AssignedTo', 'assigned_to'].includes(element));

        if(!this.adminConfigData.showAssignee){
            this.handleLookupChange({detail: {selection: JSON.stringify({Id: null, Name: null})}});
        }
    }

handleTemplateSave(event) {
     
        const fieldsToSave = Object.fromEntries(
        Object.entries(this.adminConfigData.fieldsData)
            .filter(([key]) => this.adminConfigData.selectedFields.includes(key))),
        jsonData = {
        fieldsJson: JSON.stringify(fieldsToSave),
        lookUpId: this.adminConfigData.lookUpId,
        projectKey: this.adminConfigData.projectKey,
        projectName: this.adminConfigData.projectName,
        servName: this.adminConfigData?.selectedService,
        userName: this.adminConfigData.selectedUserName},
        recordId = event?.currentTarget?.dataset?.recordid;
   
    if (this.adminConfigData?.showAssignee) {
        if (!this.adminConfigData?.lookUpId || !this.adminConfigData?.selectedUserName) {
             this.showToast('Error', 'Please select an assignee', 'error');
            return; 
        }
    }

    if (recordId) {
        jsonData.recordId = recordId;
    }
    saveTemplateData({ jsonString: JSON.stringify(jsonData) })
        .then((res) => {
            if (res?.success) {
                this.adminConfigData.recordId=null;
                this.handleModalClose();
                this.connectedCallback();
                this.showTemplateStatusBox('create');
            }
        })
        .catch((ex) => {
            AdminConfig.safeLog('saveTemplateData-Error response',JSON.stringify(ex));
            this.setSpinner(false);
        });
}

handleDeleteTemplate(event) {
    const recordId = event?.currentTarget?.dataset?.recordid;
    if (!recordId) {return};
    // Call Apex to delete template
    deleteTemplate({ templateId: recordId }).then((res) => {
            if (res?.success) {
                this.adminConfigData.recordId=null;
                this.connectedCallback();
                this.showTemplateStatusBox('delete');
            }
        })
        .catch(() => {
            this.setSpinner(false);
        });
}
handleDeleteTemplatesByService() {
    const currentProjects = this.tableData || [],
          recordIds = currentProjects
        .filter(proj => proj.recordId)
        .map(proj => proj.recordId),
        serviceName = this.adminConfigData?.selectedService;
    if (!serviceName) {return};
    if (!recordIds.length) {
        this.showToast('No templates found to delete for current projects', '', 'error');
        return;
    }
    this.setSpinner(true);
    Promise.all(recordIds.map(id => deleteTemplate({ templateId: id })))
        .then((resArray) => {
            this.adminConfigData.recordId = null;
            this.connectedCallback();
            let res = null;
            if (resArray && resArray.length > emptyCount) {
                res = resArray[emptyCount];
            }
            this.showToast(res?.payloadMap?.message || 'Service Templates deleted successfully', '', 'error');
            this.setSpinner(false);
        })
        .catch(() => {
            this.showToast('Unexpected error occurred while deleting templates', '', 'error');
            this.setSpinner(false);
        });
}
 getJiraUsersList() {
        const action = getJiraUsersList({});
        action.then(res => {
            if(res?.success) {
                if(res?.payloadMap?.UsersList){
                    const usersList = [];
                    res?.payloadMap?.UsersList?.forEach(ele => {
                        if (ele?.accountType === "atlassian") {
                            usersList.push({ Id: ele?.accountId, Name: ele?.displayName });
                        }
                    });
                    this.adminConfigData.userLookupList = [...usersList];
                }
            } else {
                this.showToast(res.payloadMap.message,'','error');
            }
        }).catch(error => {
            this.showToast(error,'','error');
            this.setSpinner(false);
      });
    }
    getAzureUsersList() {
        const action = getAzureTeams({projectId:this.adminConfigData.projectKey});
        action.then(res => {
            if (res?.success) {
                const usersList = [];
                if (res?.payloadMap?.Users) {
                    const users = res.payloadMap.Users;
                    for (const [name, id] of Object.entries(users)) {
                        usersList.push({ Id: id,Name: name });
                    }
                }
                this.adminConfigData.userLookupList = [...usersList];
            } else {
                this.showToast(res.payloadMap.message,'','error');
            }
        }).catch(error => {
            this.showToast(error,'','error');
            this.setSpinner(false);
        })
    }
    getServiceNowLookupList() {
        getServiceNowLookup({fieldName : 'assigned_to'}).then(res => {
            if(res?.success) {
                const usersList = [];
                if(res?.payloadMap?.serviceNowLookupList){
                    const users = res.payloadMap.serviceNowLookupList;
                    for (const [name, id] of Object.entries(users)) {
                        usersList.push({ Id: id,Name: name  });
                    }
                    this.adminConfigData.userLookupList = [...usersList];
                }
            } else {
                this.showToast(res.payloadMap.message,'','error');
            }
        }).catch(error => { 
            this.showToast(error,'','error');
            this.setSpinner(false);
        })
    }
    handleLookupChange(event) {
        const selection = JSON.parse((event?.detail?.selection));
        this.adminConfigData.selectedUser = { id: selection?.Id, name: selection?.Name };
        this.adminConfigData.selectedUserName = selection?.Name;
        this.adminConfigData.lookUpId = selection?.Id;
    }
    showToast(title, message, variant) {
    const event = new ShowToastEvent({
        message,
        title,
        variant
    });
    this.dispatchEvent(event);
}
closeServicePopup() {
    this.showServicePopup = false;

    const savedKeys = this.selectedProjectsMap[this.selectedServiceName];

    if (savedKeys && savedKeys.size > emptyCount) {
        this.tableData = this.serviceWiseTableData[this.selectedServiceName] || [];
        this.adminConfigData.filtered = this.tableData.map(project => ({
            ...project,
            checked: savedKeys.has(project.projectKey)
        }));

        this.showTable = true;
        this.showAuthMessage=true;
    } else {
        this.showTable = false;
        this.showAuthMessage=false;
    }
}

handleServiceSubmit() {
    this.setSpinner(true);

    const allTemplates = this.adminConfigData.templates || [],
         selectedKeys = new Set(this.popupMultiSelectSelected),
          selectedProjects = allTemplates
        .filter(proj => selectedKeys.has(proj.projectKey))
        .map(proj => ({
            ...proj,
            checked: true 
        }));

    if (selectedKeys.size === emptyCount) {
        this.showToast('At least select one project before submitting.', '', 'error');
        this.setSpinner(false);
        return;
    }

    this.updateServiceData(selectedKeys, selectedProjects);

    syncMetadataForService({
        projectKeys: [...selectedKeys] ,
        serviceName: this.selectedServiceName,  
     })
      .then(() => this.setSpinner(false))
      .catch(() => this.setSpinner(false));
    this.getTemplateDetailsFromKeys(this.selectedServiceName,selectedKeys);
}
updateServiceData(selectedKeys, selectedProjects) {
    this.tableData = [...selectedProjects];
    this.adminConfigData.filtered = [...selectedProjects];
    this.showTable = true;
    this.showServicePopup = false;
    this.selectedProjectsMap[this.selectedServiceName] = selectedKeys;
    this.serviceWiseTableData[this.selectedServiceName] = [...selectedProjects];
    this.firstTimeFlags[this.selectedServiceName] = true;
    this.isInitialLoadSubmitDone = true;
}

 renderedCallback() {
   
    if (this.lottieInitialized) {
        return;
    }

    loadScript(this, LOTTIE_WEB)
        .then(() => { this.lottieInitialized = true; })
        .catch(error => AdminConfig.safeLog('Lottie init failed:', error) );
}

  /** Safe no-op logger: allowed in dev, silent in managed package */
static safeLog(...args) {
        // Intentionally blank: prevents console usage in AppExchange
        return args.length;
    }

async showTemplateStatusBox(type) {
    this.showTemplateMessage = true;

    await Promise.resolve();

    let animation = null;

    if (type === 'create') {
        animation = await this.playCreateAnimation();
    } else if (type === 'delete') {
        animation = await this.playDeleteAnimation();
    }

     this.handleAnimationCompletion(animation);
}

// Helper to play create animation
async playCreateAnimation() {
    this.isCreateSuccess = true;
    this.isDeleteSuccess = false;
     await Promise.resolve();
    const container = this.template.querySelector('.lottie-container.create');
    if (!container) {
            AdminConfig.safeLog('container not found');
            return Promise.resolve();
        }

    container.style.display = 'block';
    return await this.setupAndPlayAnimation('create', CREATE_ANIM, 'createAnim');
}

// Helper to play delete animation
async playDeleteAnimation() {
    this.isCreateSuccess = false;
    this.isDeleteSuccess = true;
     await Promise.resolve();
    const container = this.template.querySelector('.lottie-container.delete');
     if (!container) {
            AdminConfig.safeLog('container not found');
            return Promise.resolve();
        }
     container.style.display = 'block';
    return await this.setupAndPlayAnimation('delete', DELETE_ANIM, 'deleteAnim');
}

// Helper to handle animation speed and completion
 handleAnimationCompletion(animation) {
   
     return new Promise(resolve => {
            if (!animation) {
                this.showTemplateMessage = false;
                resolve();
                return;
            }

      const { totalFrames, frameRate } = animation,
            fps = frameRate || defaultFps,
            naturalDurationMs = (totalFrames / fps) * msinSeconds,
            speed = naturalDurationMs / animationDuration; 

        animation.setSpeed(speed);

        animation.addEventListener('complete', () => {
                AdminConfig.safeLog('❌ Error animation completed');
                this.showTemplateMessage = false;
                resolve();
            }, { once: true });
        });
}


 setupAnimation(type, animationData, autoplay) {
        const container = this.template.querySelector(`.lottie-container.${type}`);
        if (!container) {
            AdminConfig.safeLog(`Missing container for ${type}`);
            return null;
        }

        AdminConfig.clearContainer(container);

        return window.lottie.loadAnimation({
            autoplay,
            container,
            loop: type === 'loading',
            path: animationData,
            renderer: 'svg',
            rendererSettings: {
                preserveAspectRatio: 'xMidYMid slice',
                progressiveLoad: true
            }
        });
    }

static clearContainer(container) {
        while (container.firstChild) {
            container.removeChild(container.firstChild);
        }
    }
async setupAndPlayAnimation(animType, animData, animProperty) {
    // Destroy previous animation instance if it exists
    if (this[animProperty] && !this[animProperty].isDestroyed) {
        this[animProperty].destroy();
        this[animProperty] = null;
    }

    // Setup a new animation instance
    this[animProperty] = this.setupAnimation(animType, animData, false);

    // Wait until the container is ready and play
    await this.waitForContainerAndPlay(animType, animProperty);

    return this[animProperty];
}

   
async waitForContainerAndPlay(animType, animProperty) {
     await this.waitForContainer(animType);
     if (this[animProperty]) {
        this[animProperty].play();
     }
  }
    
waitForContainer(animType) {
        return new Promise(resolve => {
            const container = this.template.querySelector(`.lottie-container.${animType}`);
            if (container && container.firstChild) {
                resolve();
            } else if (container) {
                const observer = new MutationObserver(() => {
                    if (container.firstChild) {
                        observer.disconnect();
                        resolve();
                    }
                });
                observer.observe(container, { childList: true });
            } else {
                resolve();
            }
        });
}

handleAvailableSearch(event) {
    this.availableSearchText = event.target.value;
    this.showDropdown = true;
}

handleProjectSelect(event) {
    const selectedId = event.currentTarget.dataset.id;
    if (selectedId && !this.popupMultiSelectSelected.includes(selectedId)) {
        this.popupMultiSelectSelected = [...this.popupMultiSelectSelected, selectedId];
        this.currentPillPage = Math.floor((this.popupMultiSelectSelected.length - oneCount) / this.pillPageSize);
    }
    this.availableSearchText = ''; 
    this.showDropdown = false;
   
}

removeProject(event) {
    const removeId = event.currentTarget.dataset.id,
        totalPages = Math.ceil(this.popupMultiSelectSelected.length / this.pillPageSize);
    this.popupMultiSelectSelected = this.popupMultiSelectSelected.filter(val => val !== removeId);
    if (this.currentPillPage >= totalPages) {
        this.currentPillPage = Math.max(emptyCount, totalPages - oneCount);
    }
}


nextPage() {
    if (this.currentPillPage < this.totalPages - oneCount) {
        this.currentPillPage += oneCount; 
    }
}
prevPage() {
    if (this.currentPillPage > emptyCount) {
        this.currentPillPage -= oneCount; 
    }
}
goToPage(event) {
    this.currentPillPage = parseInt(event.target.dataset.page, 10);
}


static addInitialPages(pageItems, current, total) {
    for (let int = 0; int < total; int += oneCount) {
        let classNameValue = 'page-adv-btn';
        if (int === current) {
            classNameValue = 'page-adv-btn active-adv';
        }
        pageItems.push({
            className: classNameValue,
            id: int,
            label: int + oneCount,
        });
    }
}
static addNextPages(pageItems, current, total) {
    if (current + oneCount < total) {
        pageItems.push({
            className: 'page-adv-btn',
            id: current + oneCount,
            label: current + twoCount,
        });
    }
    if (current + twoCount < total - oneCount) {
        pageItems.push({
            className: 'page-adv-btn disabled',
            id: 'ellipsis',
            label: '...',
        });
    }
   if (current + twoCount < total) {
       let classNameValue = 'page-adv-btn'; 
            if (current === total - oneCount) {
                classNameValue = 'page-adv-btn active-adv';
            }
            pageItems.push({
                className: classNameValue,
                id: total - oneCount,
                label: total,
            });
    }
}

getPageButtonClass(pageNumber) {
    let classNameValue = 'page-btn'; 
    if (pageNumber === this.currentPillPage) {
        classNameValue = 'page-btn active';
    }
    return classNameValue;
}

navigateToNamedCredentials() {
    this.setSpinner(false);
    window.open(`${window.location.origin}/lightning/setup/NamedCredential/home`, '_blank');
}

handleAssignToAll() {
    if (!this.validateAssignToAllFields()) {
        return;
    }
    this.setSpinner(true);
    const baseData = {
            fieldsJson: JSON.stringify(
                Object.fromEntries(
                    Object.entries(this.adminConfigData.fieldsData)
                        .filter(([key]) => this.adminConfigData.selectedFields.includes(key))
                )
            ),
            lookUpId: this.adminConfigData.lookUpId,
            servName: this.adminConfigData?.selectedService,
            userName: this.adminConfigData.selectedUserName
        },
        recordsToCreate = [];
    if (this.tableData && this.tableData.length > emptyCount) {
        this.tableData.forEach(project => {
            const recordData = {
                ...baseData,
                projectKey: project.projectKey || project.key,
                projectName: project.projectName || project.name
            };
            recordsToCreate.push(recordData);
        });
    }
    this.saveMultipleTemplates(recordsToCreate);
}


saveMultipleTemplates(recordsToCreate) {
    saveMultipleTemplateDataSimple({ jsonRecordsList: recordsToCreate.map(record => JSON.stringify(record)) })
        .then((res) => {
            this.setSpinner(false);
            if (res?.success) {
                this.handleSaveTemplatesSuccess(res, recordsToCreate);
            } else {
                this.showToast('Error', 
                    res?.payloadMap?.message || 'Failed to assign templates to all projects', 
                    'error');
                if (res?.payloadMap?.status) {
                    AdminConfig.safeLog('Detailed error:', res.payloadMap.status);
                }
            }
        })
        .catch((error) => {
            this.handleSaveTemplatesError(error);
        });
}
// Inside your class
handleSaveTemplatesSuccess(res, recordsToCreate) {
    this.adminConfigData.recordId = null;
    this.handleModalClose();
    this.connectedCallback();

    const successCount = res?.payloadMap?.successCount || recordsToCreate.length;
    this.showToast(
        'Success',
        res?.payloadMap?.message || `Template assigned to ${successCount} projects successfully!`,
        'success'
    );

    if (res?.payloadMap?.partialErrors && res.payloadMap.partialErrors.length > emptyCount) {
        AdminConfig.safeLog('Partial errors:', res.payloadMap.partialErrors);
    }
}

// Helper to handle errors from the promise
handleSaveTemplatesError(error) {
    this.setSpinner(false);
    AdminConfig.safeLog('Error in saveMultipleTemplates:', error);
    this.showToast(
        'Error',
        'An error occurred while assigning templates to all projects',
        'error'
    );
}

checkTableData() {
    if (!this.tableData || this.tableData.length === emptyCount) {
        this.showToast('Warning', 'No projects available to assign templates', 'warning');
        return false;
    }
    return true;
}

checkCheckedProjects() {
    const checkedProjects = this.tableData.filter(project => project.checked === true);
    if (checkedProjects.length === emptyCount) {
        this.showToast('Warning', 'Please select at least one project to assign template', 'warning');
        return false;
    }
    return true;
}

checkServiceSelected() {
    if (!this.adminConfigData?.selectedService) {
        this.showToast('Error', 'Please select a service', 'error');
        return false;
    }
    return true;
}

checkFieldsSelected() {
    if (!this.adminConfigData?.selectedFields || this.adminConfigData.selectedFields.length === emptyCount) {
        this.showToast('Error', 'Please select at least one field', 'error');
        return false;
    }
    return true;
}

checkAssigneeSelected() {
    if (this.adminConfigData?.showAssignee) {
        if (!this.adminConfigData?.lookUpId || !this.adminConfigData?.selectedUserName) {
            this.showToast('Error', 'Please select an assignee', 'error');
            return false;
        }
    }
    return true;
}

validateAssignToAllFields() {
    return this.checkTableData() &&
           this.checkCheckedProjects() &&
           this.checkServiceSelected() &&
           this.checkFieldsSelected() &&
           this.checkAssigneeSelected();
}

}