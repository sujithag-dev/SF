import { LightningElement, api, track, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getAzureTicketRecord from "@salesforce/apex/TicketRecordPageController.getAzureTicketRecord";
import getBugvalue from "@salesforce/apex/TicketRecordPageController.getBugvalue";
import getJiraTicketRecord from "@salesforce/apex/TicketRecordPageController.getJiraTicketRecord";
import getServiceNowRecord from "@salesforce/apex/TicketRecordPageController.getServiceNowRecord";
import getTicketRecord from "@salesforce/apex/TicketRecordPageController.getTicketRecord";
 
const FIRST_RECORD = 0, TEMPLATE_LIST_COUNT = 7;
let customFields = [];
export default class TicketRecordPage extends LightningElement {
    @api recordId;
    @track availableFields = [];
    @track bugType;
    @track count;
    @track filteredTicketList = [];
    @track isFilterModalOpen = false;
    @track isLoading = true;
    @track jiraTicketHistory = [];
    @track jiraTicketList = [];
    @track orgTimeZone;
    @track selectedFields = [];
    @track uniqueValue;
    @track workItemHistory = [];
    @track WorkItemList = [];

    connectedCallback() {
        if (this.recordId) {
            this.getBugDetails();
        }
    }
 
    @wire(getTicketRecord, { recordId: "$recordId" })
    wiredTicketRecord({ data, error }) {
        if (data) {
            this.ticketRecord = data;
            this.buildJiraTicketList();
        }else if (error) {
       this.showToast("Error", error?.body?.message || "Error loading custom object", "error");
    }
    }
 
    buildJiraTicketList() {
        const customRecord = this.ticketRecord;
        customFields = [
            { label: "S.No", value: customRecord.Name },
            { label: "Project", value: customRecord.Project__c },
            { label: "Bug Type", value: customRecord.Bug_Type__c },
            { label: "Service Template", value: customRecord.Service_Template__r?.Name || "-" },
            { label: "Created By", value: customRecord.CreatedBy?.Name },
            { label: "Owner", value: customRecord.Owner?.Name },
            { label: "Last Modified By", value: customRecord.LastModifiedBy?.Name }
        ];
        this.jiraTicketList = [...customFields];
    }
 
    getBugDetails() {
        getBugvalue({ id: this.recordId }).then((res) => {
            if (res && res.payloadMap) {
                this.bugType = res.payloadMap.BugType;
                this.uniqueValue = res.payloadMap.Unique_Id;
                try {
                    if (this.bugType === "Jira") {
                        this.getJiraTicketDetails();
                    } else if (this.bugType === "Service Now") {
                        this.getServiceNowDetails();
                    } else if (this.bugType === "Azure") {
                        this.getAzureTicketDetails();
                    }
                } catch (error) {
                this.showToast("Error", error?.body?.message || "Expected result is not there", "error");
         }
            }
        });
    }
  
  static buildAndEnrichList(baseFields, record) {
    const existingFields = new Set(baseFields.map(field => field.apiName)),list = baseFields.map(({ apiName, label, format }) => {
        let value = "-";
        if (record && Object.hasOwn(record, apiName)) {
            const rawValue = record[apiName];
            if (rawValue !== null && rawValue !== 'undefined' && rawValue !== "") {
            if (format) { value = TicketRecordPage.formatDateTime(rawValue); } 
            else {value = rawValue;}
            }
        }
        return { apiName, label, value };
    });
  Object.entries(record || {}).forEach(([key, value]) => {
    const alreadyExists = existingFields.has(key);
    if (!alreadyExists) {
        let displayValue = "-";
        if (value !== null && value !== 'undefined' && value !== "") {
            displayValue = value;
        }
        list.push({ apiName: key, label: key, value: displayValue });
    }
});
    return list;
}

  processTicketResponse(response, baseFields, defaultStandardFields) {
    if (!response?.success || !response.payload) {
        this.showToast("Error", response?.message || "Unknown error", "error");
        return;
    }
    const enrichedList = TicketRecordPage.buildAndEnrichList(baseFields, response.payload[FIRST_RECORD]), finalFields = this.resolveSelectedFields(enrichedList, defaultStandardFields);
    this.updateTicketLists(enrichedList, finalFields);
}

  resolveSelectedFields(enrichedList, defaultStandardFields) {
    const saved = localStorage.getItem(`selectedFields_${this.recordId}`),validFields = enrichedList.map(ticket => ticket.apiName);
    let parsedFields = [];
    if (saved) {
        try { parsedFields = JSON.parse(saved);
         }catch {
            parsedFields = [];
            console.warn('Invalid JSON in localStorage');
        }
    }
    const filteredSaved = parsedFields.filter(field => validFields.includes(field));
    if (filteredSaved.length > FIRST_RECORD) {
        return filteredSaved;
    }
    return defaultStandardFields.filter(field => validFields.includes(field));
}
 updateTicketLists(enrichedList, finalFields) {
    this.availableFields = enrichedList.map(ticket => ({ label: ticket.label, value: ticket.apiName }));
    this.jiraTicketList = enrichedList;
    this.selectedFields = finalFields;
    this.filteredTicketList = enrichedList.filter(ticket => this.selectedFields.includes(ticket.apiName));
    this.isLoading = false;
}

    getJiraTicketDetails() {
        getJiraTicketRecord({ id: this.recordId })
            .then((res) => {
                this.processTicketResponse(
                    res,
                    [
                        { apiName: "Assignee__c", label: "Assignee" },
                        { apiName: "Created_By__c", label: "Created By" },
                        { apiName: "Created_Date__c", format: true, label: "Created Date" },
                        { apiName: "Description__c", label: "Description" },
                        { apiName: "Environment__c", label: "Environment" },
                        { apiName: "Issue_Type__c", label: "Issue Type" },
                        { apiName: "Key__c", label: "Key" },
                        { apiName: "Label__c", label: "Labels" },
                        { apiName: "Last_Modified_By__c", label: "Last Modified By" },
                        { apiName: "Last_Modified_Date__c", format: true, label: "Last Modified Date" },
                        { apiName: "Priority__c", label: "Priority" },
                        { apiName: "Project__c", label: "Project" },
                        { apiName: "Reporter__c", label: "Reporter" },
                        { apiName: "Status__c", label: "Status" },
                        { apiName: "Summary__c", label: "Summary" },
                        { apiName: "Unique_Id__c", label: "Unique Id" }
                    ],
                    ["Unique_Id__c", "Key__c", "Created_By__c", "Created_Date__c", "Project__c", "Assignee__c", "Summary__c"]
                );
            })
            .catch((error) => {this.showToast("Error", error?.body?.message || "Unexpected error occurred", "error");});
    }
 
    getServiceNowDetails() {
        getServiceNowRecord({ id: this.recordId })
            .then((res) => {
                this.processTicketResponse(
                    res,
                    [
                        { apiName: "Assignee__c", label: "Assignee" },
                        { apiName: "Category__c", label: "Category" },
                        { apiName: "Configuration_item__c", label: "Configuration Item" },
                        { apiName: "Created_By__c", label: "Created By" },
                        { apiName: "Created_Date__c", format: true, label: "Created Date" },
                        { apiName: "Description__c", label: "Description" },
                        { apiName: "Impact__c", label: "Impact" },
                        { apiName: "Key__c", label: "Key" },
                        { apiName: "Last_Modified_By__c", label: "Last Modified By" },
                        { apiName: "Last_Modified_Date__c", format: true, label: "Last Modified Date" },
                        { apiName: "Priority__c", label: "Priority" },
                        { apiName: "Project__c", label: "Project" },
                        { apiName: "Short_Description__c", label: "Short Description" },
                        { apiName: "Status__c", label: "Status" },
                        { apiName: "Subcategory__c", label: "Subcategory" },
                        { apiName: "Unique_Id__c", label: "Unique Id" },
                        { apiName: "Urgency__c", label: "Urgency" }
                    ],
                    ["Unique_Id__c", "Key__c", "Created_By__c", "Created_Date__c", "Project__c", "Assignee__c", "Status__c", "Short_Description__c", "Description__c"]
                );
            })
            .catch((error) => {this.showToast("Error", error?.body?.message || "Unexpected error occurred", "error");});
    }
 
    getAzureTicketDetails() {
        getAzureTicketRecord({ id: this.recordId })
            .then((res) => {
                this.processTicketResponse(
                    res,
                    [
                        { apiName: "Assignee__c", label: "Assignee" },
                        { apiName: "Comment__c", label: "Comment" },
                        { apiName: "Created_By__c", label: "Created By" },
                        { apiName: "Created_Date__c", format: true, label: "Created Date" },
                        { apiName: "Description__c", label: "Description" },
                        { apiName: "Effort__c", label: "Effort" },
                        { apiName: "Key__c", label: "Key" },
                        { apiName: "Last_Modified_By__c", label: "Last Modified By" },
                        { apiName: "Last_Modified_Date__c", format: true, label: "Last Modified Date" },
                        { apiName: "Priority__c", label: "Priority" },
                        { apiName: "Project__c", label: "Project" },
                        { apiName: "Reason__c", label: "Reason" },
                        { apiName: "Sprint__c", label: "Sprint" },
                        { apiName: "Status__c", label: "Status" },
                        { apiName: "Title__c", label: "Title" },
                        { apiName: "Unique_Id__c", label: "Unique Id" },
                        { apiName: "Work_Item_Type__c", label: "Work Item Type" }
                    ],
                    ["Id", "Unique_Id__c", "Title__c", "Created_By__c", "Created_Date__c", "Assignee__c", "Description__c"]
                );
            })
            .catch((error) => {this.showToast("Error", error?.body?.message || "Unexpected error occurred", "error");});
    }
 
    static formatDateTime(dateTime) {
        return new Intl.DateTimeFormat("en-US", {
            day: "numeric",
            hour: "numeric",
            hour12: true,
            minute: "numeric",
            month: "short",
            weekday: "short",
            year: "numeric"
        }).format(new Date(dateTime));
    }
 
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            message,
            title,
            variant
        });
        this.dispatchEvent(event);
    }
 
    renderedCallback() {
        const mainDiv = this.template.querySelector('[data-name="mainDiv"]'),
              style = document.createElement("style");
        style.innerText = `.slds-modal__content { overflow: hidden;}
            .closeIcon { display: none !important; }`;
        if (mainDiv && !mainDiv.querySelector("style")) {
            mainDiv.appendChild(style);
        }
    }
 
    get templateDetailsList() {
        return this.jiraTicketList.slice(FIRST_RECORD, TEMPLATE_LIST_COUNT);
    }
 
    get bugDetailsList() {
        return this.jiraTicketList.slice(TEMPLATE_LIST_COUNT);
    }
 
    handleFilterClick() {
        this.isFilterModalOpen = true;
    }
    closeFilterModal() {
        this.isFilterModalOpen = false;
    }
    handleFieldChange(event) {
        this.selectedFields = event.detail.value;
    }
    submitFilter() {
        this.filteredTicketList = this.jiraTicketList.filter((item) =>
            this.selectedFields.includes(item.apiName)
        );
        localStorage.setItem(`selectedFields_${this.recordId}`, JSON.stringify(this.selectedFields));
        this.closeFilterModal();
    }
}