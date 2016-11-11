/**
 * Allows auto-conversion of Leads based on criteria.
 * For example, this class can be invoked by Flow, Process Builder, or even Apex Trigger.
 *
 * https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_dml_convertLead.htm
 * https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_classes_annotation_InvocableVariable.htm
 *
 * Developed by Doug Ayers, douglascayers.com
 */
public with sharing class ConvertLeadsInvocable {

    /**
     * Represents the required and optional configuration parameters to a single lead convert request.
     * https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_dml_convertLead.htm
     */
    public class LeadConvertRequest {

        @InvocableVariable(
            label = 'Lead ID'
            description = 'ID of the Lead to convert'
            required = true
        )
        public ID leadId;

        @InvocableVariable(
            label = 'Converted Status'
            description = 'Lead Status picklist value that indicates this Lead is converted'
            required = true
        )
        public String convertedStatus;

        @InvocableVariable(
            label = 'Account ID'
            description = 'The specific Account to convert Lead into. If blank then creates new Account.'
        )
        public ID accountId;

        @InvocableVariable(
            label = 'Contact ID'
            description = 'The specific Contact to convert Lead into. If blank then creates new Contact.'
        )
        public ID contactId;

        @InvocableVariable(
            label = 'Overwrite Lead Source?'
            description = 'Overwrite the LeadSource field on the target Contact with the LeadSource field from the Lead? Default is false. If true then must also specify "Contact ID".'
        )
        public Boolean overwriteLeadSource = false;

        @InvocableVariable(
            label = 'Create Opportunity?'
            description = 'Create an Opportunity? Default is true.'
        )
        public Boolean createOpportunity = true;

        @InvocableVariable(
            label = 'Opportunity Name'
            description = 'If "Create Opportunity" is true then this is the name of the new opportunity. If blank then defaults to Company field from the Lead.'
        )
        public String opportunityName;

        @InvocableVariable(
            label = 'Owner ID'
            description = 'Specific user to own the new Account, Contact, and Opportunity records created. Default is the Lead owner.'
        )
        public ID ownerId;

        @InvocableVariable(
            label = 'Send Email to Owner?'
            description = 'Send an email notification to owner specified in "Owner ID"? Default is false.'
        )
        public Boolean sendEmailToOwner = false;

    }

    /**
     * Represents the successful results of a single lead convert.
     * https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_class_database_leadconvertresult.htm
     */
    public class LeadConvertResult {

        @InvocableVariable( label = 'Lead ID' )
        public ID leadId;

        @InvocableVariable( label = 'Account ID' )
        public ID accountId;

        @InvocableVariable( label = 'Contact ID' )
        public ID contactId;

        @InvocableVariable( label = 'Opportunity ID' )
        public ID opportunityId;

    }

    // --------------------------------------------------------------------------------

    @InvocableMethod(
        label = 'Convert Leads'
    )
    public static List<LeadConvertResult> convertLeads( List<LeadConvertRequest> requests ) {

        // transform the invocable request to database convert request
        List<Database.LeadConvert> convertRequests = new List<Database.LeadConvert>();
        for ( LeadConvertRequest request : requests ) {
            convertRequests.add( transform( request ) );
        }

        // convert leads, all or none
        // if any has error then exception is thrown automatically and changes rolled back
        List<Database.LeadConvertResult> convertResults = Database.convertLead( convertRequests, true );

        // transform the database convert results to invocable result
        List<LeadConvertResult> results = new List<LeadConvertResult>();
        for ( Database.LeadConvertResult convertResult : convertResults ) {
            results.add( transform( convertResult ) );
        }

        return results;
    }

    // --------------------------------------------------------------------------------

    private static Database.LeadConvert transform( LeadConvertRequest request ) {

        Database.LeadConvert convertRequest = new Database.LeadConvert();

        convertRequest.setLeadId( request.leadId );
        convertRequest.setConvertedStatus( request.convertedStatus );

        if ( request.accountId != null ) {
            convertRequest.setAccountId( request.accountId );
        }

        if ( request.contactId != null ) {
            convertRequest.setContactId( request.contactId );
        }

        if ( request.overwriteLeadSource != null && request.overwriteLeadSource ) {
            convertRequest.setOverwriteLeadSource( request.overwriteLeadSource );
        }

        if ( request.createOpportunity != null && !request.createOpportunity ) {
            convertRequest.setDoNotCreateOpportunity( !request.createOpportunity );
        }

        if ( request.opportunityName != null ) {
            convertRequest.setOpportunityName( request.opportunityName );
        }

        if ( request.ownerId != null ) {
            convertRequest.setOwnerId( request.ownerId );
        }

        if ( request.sendEmailToOwner != null && request.sendEmailToOwner ) {
            convertRequest.setSendNotificationEmail( request.sendEmailToOwner );
        }

        return convertRequest;
    }

    private static LeadConvertResult transform( Database.LeadConvertResult convertResult ) {

        LeadConvertResult result = new LeadConvertResult();

        result.leadId = convertResult.getLeadId();
        result.accountId = convertResult.getAccountId();
        result.contactId = convertResult.getContactId();
        result.opportunityId = convertResult.getOpportunityId();

        return result;
    }

    public class ConvertLeadException extends Exception {}

}