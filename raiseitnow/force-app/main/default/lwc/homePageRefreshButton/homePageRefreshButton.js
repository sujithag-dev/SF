import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import syncFlagsDebug from '@salesforce/apex/NamedCredentialAlphaSimpleSync.syncFlagsDebug';
 
/**
 * @description HomePageRefreshButton checks if external integrations are configured
 *              for the current user.
 * @author Minuscule Technologies
 * @lastModifiedOn 23-09-2025
 */
 
export default class HomePageRefreshButton extends LightningElement {
    @track configMessage = '';
 
    connectedCallback() {
        this.checkIntegrations();
    }
 
    /**
     * @description Calls Apex to check available integrations for the current user.
     */
    checkIntegrations() {
    syncFlagsDebug()
        .then(({ payloadMap }) => {
            const { anyConfig, message } = payloadMap;

            if (anyConfig) {
                this.configMessage = '';
            } else {
                this.configMessage = message || 'No configuration found. Dashboards not available.';
            }
        })
        .catch((error) => {
            this.showToast('Error', error?.body?.message || 'Error fetching configuration', 'error');
            this.configMessage = 'Error checking configuration.';
        });
  }
    /**
     * @description Displays a toast message.
     * @param {string} title
     * @param {string} message
     * @param {string} variant
     */
    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                message,
                title,
                variant,
            })
        );
    }
}