import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import { encodeDefaultFieldValues } from "lightning/pageReferenceUtils";
import { getRecord } from "lightning/uiRecordApi";
import { subscribe, MessageContext } from 'lightning/messageService';
import BOX_CONTENT_PICKER from '@salesforce/messageChannel/BoxContentPicker__c';
import { CloseActionScreenEvent } from 'lightning/actions';



export default class BoxEmailSharedLinksRecordAction extends NavigationMixin(LightningElement) {
    subscription = null;

    @wire(MessageContext)
    messageContext;

    @api isPickerOpen = false;
    @api recordId;

    // Wire the getRecord function so we can get the recordId for the current record
    @wire(getRecord, { recordId: "$recordId", layoutTypes: ["Compact"] })
    wiredRecord({ error, data }) {
      if (error) {
        // handle error
      } 
      else if (data) {
        this.isPickerOpen = true;
        this.subscribeToMessageChannel();
      }
    }

    // Subscribe to the message channel so we can get the response from the Child LWC and VF Page
    subscribeToMessageChannel() {
        if(!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                BOX_CONTENT_PICKER,
                (message) => this.handleMessage(message)
            );
        }
    }

    handleMessage(message) {
        // Check for the files_selected operation
        if(message.selectedFiles.operation === 'files_selected') {
            
            // Create the beginning of the html email body
            let htmlBody =`
            <div>
                <p>
                    <br />
                    Please use the following Box Shared Links: <br />
                    <br />
            `;

            // Loop through the files in the message and create a list of Box Shared Links
            const files = message.selectedFiles.files;
            files.forEach(file => {
                htmlBody += `
                    <a href="${file.shared_link}">${file.name}</a>
                    <br />`;
            });

            // Add the end html tags
            htmlBody +=`
                </p>
            </div>
            `;

            // Instantiate the page reference for the SendEmail quick action
            var pageRef = {
                type: "standard__quickAction",
                attributes: {
                    apiName: "Global.SendEmail",
                },
                state: {
                    recordId: this.recordId,
                    defaultFieldValues: encodeDefaultFieldValues({
                        HtmlBody: htmlBody,
                        Subject: "Box Shared Links Example",
                    }), 
                },
            };
            this.dispatchEvent(new CloseActionScreenEvent());
            this[NavigationMixin.Navigate](pageRef);
        }        
        else if(message.selectedFiles.operation === 'cancel') {
            // Dispatch the close action screen event when the cancel button is used
            this.dispatchEvent(new CloseActionScreenEvent());
        }
    }

    handleClose() {
        // Dispatch the close action screen event when the cancel button is used
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}