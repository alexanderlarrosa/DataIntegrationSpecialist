public class ProjectCalloutService {
    //Complete the implementation for business and callout logic
    @InvocableMethod
	public static void postOpportunityToPMS(List<Id> listOfId){
        if(listOfId.size()>0){
            System.enqueueJob(new QueueablePMSCall(listOfId));
        }
        
    }

    public static String generateJson(Opportunity opp){
        JSONGenerator json = JSON.createGenerator(true);
        json.writeStartObject();
        json.writeStringField('opportunityId ', opp.Id);
        json.writeStringField('opportunityName', opp.Name);
        json.writeStringField('accountName', opp.Account.Name);
        json.writeStringField('closeDate', String.valueOf(opp.CloseDate));
        json.writeStringField('amount', String.valueOf(opp.Amount.intValue()));
        json.writeEndObject();
        return json.getAsString();
    }

    public class QueueablePMSCall implements System.Queueable, Database.AllowsCallouts{
        Opportunity opp = new Opportunity();
        public QueueablePMSCall(List<Id> listOfId) {
            opp = [SELECT Id, Name, Account.Name, CloseDate, Amount FROM Opportunity WHERE Id=:listOfId.get(0) LIMIT 1] ;
                
        }

        public void execute(QueueableContext context) {
            String body = generateJson(opp);
            String projectServiceToken = ServiceTokens__c.getValues('ProjectServiceToken').Token__c;
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint('callout:ProjectService');
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json;charset=UTF-8');
            request.setHeader('token', projectServiceToken);
            // Set the body as a JSON object
            request.setBody(body);
            HttpResponse response = http.send(request);
            // Parse the JSON response
            if(response.getStatusCode() != 201) {
                opp.StageName = 'Submitted Project';
            } else {
                opp.StageName = 'Resubmit Project';
            }
        }

    }
}