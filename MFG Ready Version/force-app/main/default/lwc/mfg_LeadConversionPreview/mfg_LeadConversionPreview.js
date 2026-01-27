import { LightningElement, api, track } from 'lwc';
import getLead from '@salesforce/apex/mfg_LeadHandler.getLead';
import saveRecords from '@salesforce/apex/MFG_LeadConversion.saveRecords';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

export default class MfgLeadConversionPreview extends NavigationMixin(LightningElement) {
    @api recordId;
    @track isLoading = true;
    @track conversionData;
    @track accountToInsert;
    @track contactToInsert;
    @track opportunityToInsert;
    @track error;
    resultMap;
    @track isConverted = false;

  
    connectedCallback() {
        this.isLoading = true;
        setTimeout(() => {
            if (this.recordId) {
                console.log('RecordId inside connected callback:', this.recordId);
                this.loadConversionPreview();
            }
        }, 500);
    }

  
    loadConversionPreview() {
        this.isLoading = true;
        getLead({ leadIds: [this.recordId] })
            .then((res) => {
                console.log('Conversion Preview Result:', res);
                console.log('Conversion Preview Raw Result:', JSON.stringify(res, null, 2));

                if (res && res.success && res.payload && Object.keys(res.payload).length > 0) {
                    this.handleResult(res.payload);
                    if(res.info && res.info[this.recordId]){
                        this.handleToast('Info', res.info[this.recordId], 'info');
                    }
                } else {
                    this.error = res && res.message ? res.message : 'No conversion data available.';
                }
            })
            .catch((err) => {
                console.error('Error fetching conversion preview:', err);
                this.error = err.body ? err.body.message : err.message;
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleResult(res){
        if (!res || Object.keys(res).length === 0) {
            this.error = 'No conversion data received';
            return;
        }

        this.conversionData = null;
        this.accountToInsert = null;
        this.contactToInsert = null;
        this.opportunityToInsert = null;
        
        const leadId = Object.keys(res)[0];
        this.conversionData = res[leadId];

        if (!this.conversionData) {
            this.error = 'Invalid conversion data structure';
            return;
        }
        
        this.resultMap = res;
        this.accountToInsert = this.conversionData.accountToInsert || null;
        this.contactToInsert = this.conversionData.ContactToInsert || null;
        this.opportunityToInsert = this.conversionData.OpportunityToInsert || null;
        this.error = null;

        this.hasAccountId = this.accountToInsert && this.accountToInsert.Id ? true : false;
        this.hasContactId = this.contactToInsert && this.contactToInsert.Id ? true : false;
        this.hasOpportunityId = this.opportunityToInsert && this.opportunityToInsert.Id ? true : false;

    }

 
    handleConvert() {
        if (!this.resultMap || Object.keys(this.resultMap).length === 0) {
            this.handleToast('Error', 'No data to convert', 'error');
            return;
        }

        if (this.isConverted) {
            this.handleToast('Warning', 'Lead is already converted', 'warning');
            return;
        }

        this.isLoading = true;
        console.log('Record Id:', this.recordId);
        console.log('Sending payload:', JSON.stringify(this.resultMap, null, 2));

        saveRecords({ convertedMap: JSON.stringify(this.resultMap) })
            .then(result => {
                console.log('Result:', result);
                console.log('Success:', JSON.stringify(result, null, 2));

                if (result && result.success) {
                    this.handleToast('Success', result.message, 'success');
                    this.handleResult(result.payload);
                    console.log('Result Payload:', result.payload);

                    this.isConverted = true;
                } else {
                    this.handleToast('Error', result && result.message ? result.message : 'Conversion failed', 'error');
                    this.isConverted = false;
                }
            })
            .catch(err => {
                console.error('Conversion error:', err);
                this.handleToast('Error', err.body?.message || err.message || 'An error occurred', 'error');
                this.isConverted = false;
            })
            .finally(() => {
                this.isLoading = false;
            });
    }



    handleToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant, 
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }

 
    handleNavigate(event) {
        let recordId = event.currentTarget.dataset.recordid; 
        let objectApiName = event.currentTarget.dataset.objectapiname; 
        console.log('Record:', recordId, 'Object:', objectApiName);

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: objectApiName,
                actionName: 'view'
            }
        });
    }
}