import { LightningElement, api, track } from 'lwc';
import convertLead from '@salesforce/apex/SISLeadConversionController.convertLead';
import getLeadConvertDetails from '@salesforce/apex/SISLeadConversionController.getLeadConvertDetails';
import handleIsDuplicate from '@salesforce/apex/SISLeadConversionController.handleIsDuplicate';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class Sis_LeadConversionModalPage extends NavigationMixin(LightningElement) {
    @api recordId;
    @track isLoading;
    @track studentRecordId;
    @track parentLead;
    @track parentAccount;
    @track parentContact;
    @track student;

    connectedCallback(){
        this.isLoading = true;
        setTimeout(()=> {
            if(this.recordId){
                console.log('this.recordId--- inside connected callback', this.recordId);
                this.getLeadDetails();
            }
        }, 500); 
    }

    getLeadDetails() {
        getLeadConvertDetails({ recordId: this.recordId })
            .then(res => {
                console.log('res---', res);
                if (res.parentLead) {
                    this.parentLead = res.parentLead.Id;
                }
                if (res.parentAccount) {
                    this.parentAccount = res.parentAccount.Id;
                }
                if (res.parentContact) {
                    this.parentContact = res.parentContact.Id;
                }
                if (res.student) {
                    this.student = res.student.Id;
                }
                
                console.log('this.parentLead---', this.parentLead);
                console.log('this.parentAccount---', this.parentAccount);
                console.log('this.parentContact---', this.parentContact);
                console.log('this.student---', this.student);
                this.isLoading = false;
            })
            .catch(err => {
                console.error('err---', err.stack);
                this.isLoading = false;
            });
    }

    handleConvertButton(event){
        console.log('this.recordId--', this.recordId);
        let currectRecordId = this.recordId;
        console.log('currectRecordId---', currectRecordId);
        convertLead({recordId: currectRecordId})
        .then(res => {
            console.log('res---', res);
            if(res.hasOwnProperty('error')){
                this.handleToast('Error', res.error, 'error');
            }else if(res.hasOwnProperty('success')){
                this.studentRecordId = res.success;
                console.log('this.studentRecordId---', this.studentRecordId);
                this.handleNavigate();
                this.handleToast('Success', 'Student record created successfully', 'success');
            }else if(res.hasOwnProperty('warning')){
                this.handleToast('Warning', res.warning, 'warning');
            }else{
                this.handleToast('Error', 'Some error has occured', 'error');
            }
        }).catch(err => {
            console.log('err---', err.stack);
            this.handleToast('Error', 'Some error has occured', 'error');
        })
    }

    handleToast(title, message, variant){
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant, //success, error, warning, info
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }

    handleNavigate(){
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                objectApiName: 'Student__c',
                recordId: this.studentRecordId,
                actionName: 'view'  // Options: 'view', 'edit'
            }
        });
    }

    disconnectedCallback(){
        console.log('disconnectedCallback--- called');
        handleIsDuplicate({ recordId: this.recordId })
        .then(res => {
            console.log('res---', res);
            if(res.hasOwnProperty('info')){
                this.handleToast('Info', res.info, 'info');
            }else{
                this.handleToast('Error', 'Some error has occured', 'error');
            }
        }).catch(err => {
            console.log('err---', err.stack);
            this.handleToast('Error', 'Some error has occured', 'error');
        })
    }
}