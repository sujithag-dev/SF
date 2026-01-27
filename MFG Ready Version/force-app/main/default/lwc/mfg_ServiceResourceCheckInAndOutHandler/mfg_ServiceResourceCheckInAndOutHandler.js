import { LightningElement, api,track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';


export default class Mfg_ServiceResourceCheckInAndOutHandler extends LightningElement {

    @api recordId;

    latitude;
    longitude;
    formattedTime;
    isLoading = true;

    connectedCallback() {
        this.getCurrentLocation();
    }

    getCurrentLocation() {
        if (navigator.geolocation) {
            navigator.geolocation.getCurrentPosition(
                (position) => {
                    this.latitude = position.coords.latitude.toFixed(6);
                    this.longitude = position.coords.longitude.toFixed(6);

                    const now = new Date();
                    this.formattedTime = now.toLocaleString();

                    this.isLoading = false;
                },
                () => {
                    this.isLoading = false;
                    this.showToast('Error', 'Location access denied', 'error');
                }
            );
        }
    }

    handleConfirm() {
        this.isLoading = true;
        this.dispatchEvent(new CloseActionScreenEvent());

        // updateDistanceAndCheckIn({
        //     serviceAppointmentId: this.recordId,
        //     currentLatitude: this.latitude,
        //     currentLongitude: this.longitude
        // })
        // .then(() => {
        //     this.isLoading = false;
        //     this.showToast('Success', 'Check In completed successfully', 'success');
        // })
        // .catch(error => {
        //     this.isLoading = false;
        //     this.showToast('Error', error.body.message, 'error');
        // });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }
}