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

                if (res && Object.keys(res).length > 0) {
                    this.handleResult(res);
                } else {
                    this.error = 'No conversion data available.';
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
                   this.conversionData = null;
                   this.accountToInsert = null;
                   this.contactToInsert = null;
                   this.opportunityToInsert = null;
                   const leadId = Object.keys(res)[0];
                    this.conversionData = res[leadId];
                    this.resultMap = res;
                    this.accountToInsert = this.conversionData.accountToInsert || null;
                    this.contactToInsert = this.conversionData.ContactToInsert || null;
                    this.opportunityToInsert = this.conversionData.OpportunityToInsert || null;
                    this.error = null;

                    this.hasAccountId = this.accountToInsert && this.accountToInsert.Id ? true : false;
                    this.hasContactId = this.contactToInsert && this.contactToInsert.Id ? true : false;
                    this.hasOpportunityId = this.opportunityToInsert && this.opportunityToInsert.Id ? true : false;

                    
                    if (this.hasAccountId && this.hasContactId && this.opportunityToInsert==null) {
                    this.isConverted = true;
                    } 

                               
    }

 
    // handleConvert() {
    //     console.log('Record Id:', this.recordId);
    //     console.log('Sending payload:', JSON.stringify(this.resultMap, null, 2));

    //     this.isLoading = true;

    //     saveRecords({ convertedMap: JSON.stringify(this.resultMap) })
    //         .then((result) => {
    //             console.log('Result:', result);
    //             console.log('Success:', JSON.stringify(result, null, 2));

    //             if (result && Object.keys(result).length > 0) {
    //                 this.handleResult(result);

    //                 this.handleToast('Success', 'Lead Converted Successfully', 'success');
                    
    //             }
    //             this.isConverted = true;
    //             this.isLoading = false;
    //         })
    //         .catch((error) => {
    //             console.error('Error:', JSON.stringify(error, null, 2));
    //             this.handleToast('Error', 'Error converting lead', 'error');
    //             this.isLoading = false;
    //             this.isConverted = false;
                
    //         });
    // }

    handleConvert() {
        this.isLoading = true;
        console.log('Record Id:', this.recordId);
        console.log('Sending payload:', JSON.stringify(this.resultMap, null, 2));

    saveRecords({ convertedMap: JSON.stringify(this.resultMap) })
        .then(result => {
            console.log('Result:', result);
            console.log('Success:', JSON.stringify(result, null, 2));

            if (result.success) {
                this.handleToast('Success', result.message, 'success');
                this.handleResult(result.payload);
                console.log('Result Payload:', result.payload);
                this.isConverted = true;
            } else {
                this.handleToast('Error', result.message, 'error');
                this.isConverted = false;
            }
        })
        .catch(err => {
            this.handleToast('Error', err.body?.message || err.message, 'error');
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
            variant: variant, // success, error, warning, info
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }

 
    handleNavigate(event) {
        let recordId = event.currentTarget.dataset.recordid; 
        let objectApiName = event.currentTarget.dataset.objectapiname; 
        console.log('Record:', recordId, 'Object:', objectApiName);
        this.isConverted = true;
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