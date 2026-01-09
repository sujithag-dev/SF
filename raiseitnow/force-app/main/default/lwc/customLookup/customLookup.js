import { LightningElement, api, track } from "lwc";
const NO_RECORDS_FOUND_MESSAGE = "No Records Found",ONE = 1, RECORD_LIMIT_DEFAULT = 6, RESET_DELAY = 500, TIMEOUT_DELAY = 800, ZERO = 0;
export default class LwcLookup extends LightningElement {
  @api additionalFields = "";
  @api disabled = false;
  @api fieldsToFetch;
  @api iconName;
  @api isOverride = false;
  @api isRequired = false;
  @api lookupLabel;
  @api name = "";
  @api needToSearchDataBase = false;
  @api objectApiName;
  @api recordLimit = RECORD_LIMIT_DEFAULT;
  @api secondaryFields;
  @api selectedRecordId;
  @api selectedValue;
  @api showAdditionalFields = false;
  @api showAdditionalInfo = false;
  @api showFullName = false;
  @api staticData;
  @api whereClause = "";
  @track data = [];
  @track event;
  @track hasFocus = false;
  @track message;
  @track query;
  @track recordsList;
  @track searchKey = "";
  @track timeout = null;

  get showRecordsList() {
    return (this.recordsList || this.message) && this.hasFocus;
  }

  connectedCallback() {
    if (
      this.needToSearchDataBase === "false" &&
      this.staticData &&
      Array.isArray(this.staticData)
    ) {
      this.data = [...this.staticData];
    }
    window.addEventListener("click", (evt) => {
      this.handlingOutsideClick(evt);
    });
    this.template.addEventListener("click", (evt) => {
      evt.stopPropagation();
    });
  }

  handlingOutsideClick(event) {
    if (this.template.querySelector('div[data-style="someElementID"]')) {
      this.onLeave(event);
    }
  }

  searchInStaticData(searchKey) {
    const regex = new RegExp(searchKey, "iu");
    this.data = this.staticData.filter((row) => regex.test(row.Name));
    if (this.data && this.data.length !== ZERO) {
      this.recordsList = this.data;
      this.message = "";
    } else {
      this.message = NO_RECORDS_FOUND_MESSAGE;
      this.recordsList = [];
    }
  }

  onLeave(event) {
    this.event = event;
    setTimeout(() => {
      this.message = "";
      this.searchKey = "";
      this.recordsList = null;
    }, RESET_DELAY);
  }

  onRecordSelection(event) {
    const { key, name } = event.currentTarget.dataset;
    this.selectedRecordId = key;
    this.selectedValue = name;
    this.searchKey = "";
    this.onSeletedRecordUpdate();
    this.hasFocus = false;
  }

  handleKeyChange(event) {
    this.hasFocus = true;
    clearTimeout(this.timeout);
    this.searchKey = event.target.value;
    this.timeout = setTimeout(() => {
      this.search();
    }, TIMEOUT_DELAY);
  }

  search() {
    const { searchKey } = this;
    this.searchInStaticData(searchKey);
  }

  @api removeRecordOnLookup(event) {
    this.event = event;
    this.searchKey = "";
    this.selectedValue = null;
    this.selectedRecordId = null;
    this.recordsList = null;
    this.onSeletedRecordUpdate();
  }

  setAdditonalFieldsInformation(recordsList) {
    recordsList.forEach((record) => {
      if (this.showAdditionalFields) {
        const addtionalFields = this.additionalFields
          .split(",")
          .map((fieldExp) => {
            const [label, path] = fieldExp.split("="),
                  value = LwcLookup.extractFieldValue(record, path);


            return { label, value };
          });
        record.displayAddionalFields = addtionalFields;
      }
      return record;
    });
    this.recordsList = recordsList;
  }

  setNameWithMatchings(recordsList) {
    recordsList.forEach((record) => {
      if (this.searchKey && this.secondaryFields) {
        const secondaryFields = this.secondaryFields.split(", ");
        secondaryFields.forEach((secField) => {
          if (record[secField]) {
            if (record.FullName) {
              record.FullName = `${record.FullName} | ${record[secField]}`;
            } else {
              record.FullName = record[secField];
            }
          }
        });
      } else {
        record.FullName = record.Name;
      }
      return record;
    });
    this.recordsList = recordsList;
  }

  setAdditionalFieldInfo(recordsList) {
    recordsList.forEach((record) => {
      if (this.fieldsToFetch) {
        const fieldsToFetch = this.fieldsToFetch.split(", ");
        fieldsToFetch.forEach((additionalInfo) => {
          let addtionalLookUp = [];

          if (additionalInfo.includes(".")) {
            addtionalLookUp = additionalInfo.split(".");
          } else {
            addtionalLookUp = [additionalInfo];
          }

          LwcLookup.updateAdditionalInfo(record, addtionalLookUp);
        });
      } else {
        record.additionalInfo = record.Name;
      }
      return record;
    });
    return recordsList;
  }

  onSeletedRecordUpdate() {
    let selection = { Id: this.selectedRecordId, Name: this.selectedValue }, selectionList = [];

    if (this.recordsList) {
      selectionList = this.recordsList.filter(
        (result) => result.Id === this.selectedRecordId
      );
    }

    if (selectionList && selectionList.length === ONE) {
      selection = selectionList[ZERO];
    }

    const passEventr = new CustomEvent("recordselection", {
      detail: {
        name: this.name,
        placeholder: this.placeholder,
        selection: JSON.stringify(selection),
      },
    });

    this.dispatchEvent(passEventr);
  }

  static extractFieldValue(record, path) {
    const fieldNameParts = path.split(".");
    return fieldNameParts.reduce((value, field, index) => {
        if (index === ZERO) {
            return record[field];
        }
        return value[field];
    }, null);
}

  static updateAdditionalInfo(record, addtionalLookUp) {
    if (addtionalLookUp.length === ONE) {
        if (record.additionalInfo) {
            record.additionalInfo += ` | ${record[addtionalLookUp[ZERO]]}`;
        } else {
            record.additionalInfo = record[addtionalLookUp[ZERO]];
        }
    } else {
        const [parent, child] = addtionalLookUp;
        if (record.additionalInfo) {
            record.additionalInfo += ` | ${record[parent][child]}`;
        } else {
            record.additionalInfo = record[parent][child];
        }
    }
}
}