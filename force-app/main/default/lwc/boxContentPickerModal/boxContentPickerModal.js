import { LightningElement, api, wire } from 'lwc';
import { publish, MessageContext } from 'lightning/messageService';
import BOX_CONTENT_PICKER from '@salesforce/messageChannel/BoxContentPicker__c';

import downscopeToken from '@salesforce/apex/BoxElementsController.downscopeToken';

export default class BoxContentPickerModal extends LightningElement {
    @wire(MessageContext)
    messageContext;

    @api recordId;
    @api buieURL;
    @api isLoading = false

    error;

    connectedCallback() {    
        this.isLoading = true;
        // Bind the handleVFResonse function to the message events from the VF Page
        window.addEventListener('message' , this.handleVFResponse.bind(this));

        // Call apex method to get downscoped token
        downscopeToken({
            recordId: this.recordId
        })
        .then(responseMap => {
            const downscopedToken = responseMap.accessToken;      
            const ltnOrigin = responseMap.ltnOrigin;
            const folderId = responseMap.folderId;

            // Set the buieURL used in the iframe src param
            this.buieURL = `${ltnOrigin}/apex/ContentPicker?recId=${this.recordId}&folderId=${folderId}&downscopedToken=${downscopedToken}`;

            this.isLoading = false;
        })
        .catch(error => {
            this.error = error;
        });
    }

    // Publish response from VF Page to Message Channel 
    handleVFResponse(message) {
        publish(this.messageContext, BOX_CONTENT_PICKER, {
            selectedFiles: message.data
        });
    }
}