public with sharing class ServiceManagement {

    public class ServiceManagementException extends Exception {}

    private map<String, String> params = ApexPages.CurrentPage().getParameters();

    public Class ClientCheckin {
        public Id clientId { get; private set; }
        public Id clientContactId { get; private set; }
        public String clientName { get; private set; }
        public Decimal pointsRemaining { get; private set; }
        public String boxSize { get; private set; }
        public DateTime checkInTime { get; private set; }
        public Boolean checkinNotToday { get; private set; }
    }

    @RemoteAction
    public static list<ClientCheckin> getCheckedInList() {
        list<ClientCheckin> chkList = new list<ClientCheckin>();
        for (Service_Management_Checkin__c fbc : Service_Management_Checkin__c.getAll().values()) {
            ClientCheckin cc = new ClientCheckin();
            cc.clientId = fbc.name;
            cc.clientContactId = fbc.Visitor__c;
            cc.clientName = fbc.Client_Name__c;
            cc.pointsRemaining = fbc.Points_Remaining__c;
            cc.boxSize = fbc.Box_Size__c;
            cc.checkInTime = fbc.Check_In_Time__c;
            cc.checkinNotToday = (cc.checkInTime != null && cc.checkInTime.date() != system.today());
            chkList.add( cc );
        }

        // Sort List
        for (Integer i =0; i < chkList.size(); i++) {
            for (Integer j = i; j > 0; j--) {
                if (chkList[j-1].checkInTime < chkList[j].checkInTime){
                    ClientCheckin temp = chkList[j];
                    chkList[j] = chkList[j-1];
                    chkList[j-1] = temp;
                }
            }
        }

        return chkList;
    }

    @RemoteAction
    public static Account getHouseholdDetail( Id hhid ) {
        Account hh =
            [select Id, Name, CreatedDate, LastModifiedDate, First_Visit__c, Most_Recent_Visit__c,
                Total_Visits__c, Homeless__c, Out_Of_Area__c, Address__c, City__c, State__c, Postal_Code__c,
                Inactive__c, Notes__c, Source__c, External_ID__c, Adults__c,
                Children__c, Infants__c, Seniors__c, Client_Names__c, Full_Address__c, Tags__c,
                Staff_Notes__c, Phone__c, Proof_of_Address__c, Proof_of_Address_Date__c,
                (select Id, Name, FirstName, LastName, Age_Group__c, Age__c, Birthdate, Proof_of_Infant__c, Gender__c, Id_Number__c
                    from Contacts),
                (select Points_Used__c, Commodity_Usage_JSON__c from Visits__r where Visit_Date__c = THIS_MONTH)
                from Account where id = :hhid];

        if (ServiceManagementSettings.general.Track_Points__c)
            hh.Monthly_Points_Available__c = getMonthlyPoints( hh );

        /*
        // if last visit date is not this month, recalculate points
        if (ServiceManagementSettings.general.Track_Points__c) {
            hh.Monthly_Points_Available__c = getMonthlyPoints( hh );
            if (hh.Most_Recent_Visit__c == null) {
                hh.Current_Points_Used__c = 0;
            } else if (hh.Current_Points_Used__c == null || hh.Most_Recent_Visit__c.year() != system.today().year() || hh.Most_Recent_Visit__c.month() != system.today().month()) {
                AggregateResult ar = [SELECT SUM(Points_Used__c) TotalPoints FROM Client_Visit__c WHERE Id = : hh.id AND Visit_Date__c = THIS_MONTH];
                Decimal pu = (Decimal)(ar.get('TotalPoints'));
                hh.Current_Points_Used__c = (pu == null) ? 0 : pu;
            }
        }
        */
        return hh;
    }

    @RemoteAction
    public static list<Client_Visit__c> getVisitHistory( Id hhid ) {
        return
            [select Id, Visit_Date__c, Box_Type__c, Points_Used__c, Checkout_Weight__c, Notes__c
                from Client_Visit__c
                where Household__c = :hhid
                order by Visit_Date__c DESC limit 20];
    }

    @RemoteAction
    public static Account saveHousehold( Account hh ) {

        if (hh.Name == null)
            hh.Name = 'Household';

        if (hh.Id == null)
            insert hh;
        else
            update hh;

        hh = getHouseholdDetail( hh.Id );
        return hh;
    }

    @RemoteAction
    public static Account saveHouseholdAndMembers( Account hh, list<Contact> clients) {

        if (hh.Name == null)
            hh.Name = 'Household';

        hh.Monthly_Points_Available__c = getMonthlyPoints( hh );  // is this by trigger?  how about the name?
        if (hh.Id == null)
            insert hh;
        else
            update hh;

        return saveHouseholdMembers( hh.id, clients );
    }

    @RemoteAction
    public static Account saveHouseholdMembers( Id hhid, list<Contact> clients ) {

        if (clients != null) {
            list<Contact> clientsToInsert = new list<Contact>();
            list<Contact> clientsToUpdate = new list<Contact>();
            set<Id> clientIds = new set<Id>();

            for (Contact client : clients) {
                if (client.LastName != null) {
                    client.AccountId = hhid;
                    if (client.Id == null) {
                        clientsToInsert.add(client.clone());
                    } else {
                        clientsToUpdate.add(client);
                        clientIds.add(client.Id);
                    }
                }
            }
            list<Contact> clientsToDelete = [select id from Contact where AccountId = : hhid
                and Id not in :clientIds];

            if (!clientsToDelete.isEmpty())
                delete clientsToDelete;
            if (!clientsToUpdate.isEmpty())
                update clientsToUpdate;
            if (!clientsToInsert.isEmpty())
                insert clientsToInsert;
        }

        // TODO: recalculation needed?
        return getHouseholdDetail( hhid );
    }

    static Decimal getMonthlyPoints( Account hh ) {
        Decimal pts = 0;
        if (hh != null) {
            if (ServiceManagementSettings.general.Monthly_Base_Points__c != null)
                pts += ServiceManagementSettings.general.Monthly_Base_Points__c;
            if (ServiceManagementSettings.general.Monthly_points_per_Adult__c != null && hh.Adults__c != null)
                pts += (ServiceManagementSettings.general.Monthly_points_per_Adult__c * hh.Adults__c);
            if (ServiceManagementSettings.general.Monthly_points_per_Adult__c != null && hh.Seniors__c != null)
                pts += (ServiceManagementSettings.general.Monthly_points_per_Adult__c * hh.Seniors__c);
            if (ServiceManagementSettings.general.Monthly_points_per_Child__c != null && hh.Children__c != null)
                pts += (ServiceManagementSettings.general.Monthly_points_per_Child__c * hh.Children__c);
            if (ServiceManagementSettings.general.Monthly_points_per_Child__c != null && hh.Infants__c != null)
                pts += (ServiceManagementSettings.general.Monthly_points_per_Child__c * hh.Infants__c);
        }
        return pts;
    }

    @RemoteAction
    public static Account createNewHousehold( Account hhData, list<Contact> clientData ) {
        Account hh;

        // calculate points and commodity data and save

        return hh;
    }

    @RemoteAction
    public static void checkIn( Id hhid, Id contactid) {

        Service_Management_Checkin__c fbc = new Service_Management_Checkin__c();

        Account hh =
            [select id, client_names__c, Adults__c, Seniors__c, Children__c, Infants__c,
                (select Points_Used__c from Visits__r where Visit_Date__c = THIS_MONTH)
                from Account where id = :hhid];

        if (Service_Management_Checkin__c.getInstance( hhid ) != null) {
            throw new ServiceManagementException('Already checked in.');
        } else {
            fbc.name = hhid;
            fbc.Client_Name__c = hh.client_names__c;
            fbc.Points_Remaining__c = getMonthlyPoints( hh );
            for (Client_Visit__c cv : hh.Visits__r)
                if (cv.Points_Used__c != null) fbc.Points_Remaining__c -= cv.Points_Used__c;

            fbc.Check_In_Time__c = system.now();
            fbc.Visitor__c = contactid;

            insert fbc;
        }
    }

    @RemoteAction
    public static void cancelCheckIn( Id hhid ) {
        Service_Management_Checkin__c fbc = Service_Management_Checkin__c.getInstance( hhid );
        if (fbc != null) delete fbc;
    }

    @RemoteAction
    public static ServiceManagementStats getStats( String timeframe ) {

        ServiceManagementStats s = new ServiceManagementStats();
        s.queryStats(timeframe);
        return s;
    }

    @RemoteAction
    public static String getCustomLabel( String label ) {

        if (label == 'Box_Type__c')
            return System.Label.Service_Management_Box_Type;

        return 'Undefined';
    }

// TODO: REFACTOR FOR CONSISTENCY????
    public Class ClientHousehold {
        public String id;
        public String contactid;
        public String value;
        public String name;
        public String addr;
        //public list<String> tags;
    }

    @RemoteAction
    public static list<ClientHousehold> queryHouseholds( String query){//, Boolean includeInactive ) {
        list<ClientHousehold> hhRet = new list<ClientHousehold>();
        List<List<SObject>> resultList =
            //(includeInactive) ?
            //  [FIND :(query + '*') RETURNING Account( Id, Client_Names__c, Address__c, Full_Address__c
   //               WHERE Client_Names__c != null ORDER BY Client_Names__c )] :

            // Return Account based on Client_Names which has all the Clients
/*            [FIND :(query + '*') 
                RETURNING Account( Id, Client_Names__c, Address__c, Full_Address__c
                WHERE Client_Names__c != null
                    AND Inactive__c != true
                ORDER BY Client_Names__c )];
*/

            // Expand to return all Clients for a household
            [FIND :('*' + query + '*') 
                RETURNING Contact( 
                    Name, Id_Number__c,
                    Account.Name, Account.Id, Account.Address__c, Account.Full_Address__c
                WHERE Account.Inactive__c != true 
                ORDER BY Name)];


// TODO: should not need to translate here
        for (sObject obj : resultList[0]) {
            Contact rec = (Contact)obj;
            ClientHousehold chh = new ClientHousehold();
            chh.id = rec.Account.Id;
            chh.contactid = rec.Id;
            chh.name = rec.Name + ' at ' + rec.Account.Name;
            chh.addr = rec.Account.Full_Address__c;

            // value is the search field
            chh.value = 
                ((rec.Id_Number__c != null) ? (' (' + rec.Id_Number__c + ')') : '')
                + ((rec.Account.Address__c != null) ? (' (' + rec.Account.Address__c + ')') : '');

            hhRet.add( chh );
        }
        return hhRet;
    }

    // custom class allows us to return all settings in a single remote call
    public class AppSettings {
        public Service_Management_Settings__c general { get; set; }
        public List<Service_Management_Commodity__c> commodities { get; set; }
        public List<Service_Management_Box_Settings__c> boxes { get; set; }
    }

    @RemoteAction
    public static AppSettings getAppSettings() {
        AppSettings s = new AppSettings();
        s.general = ServiceManagementSettings.general;
        s.commodities = ServiceManagementSettings.commodities;
        s.boxes = ServiceManagementSettings.boxes;
        return s;
    }

    @RemoteAction
    public static Id logVisit( Id hhId, Id contactId, String boxType, Decimal checkoutWeight, Integer pointsUsed, Map<String, Integer> commodityUsage, String visitNotes ) {

        // get the HH detail
        Account[] hhs =
            [select Id, Name, Adults__c, Children__c, Infants__c, Seniors__c, Homeless__c, Out_Of_Area__c, Inactive__c
                from Account where id = :hhid];

        if ( hhs.isEmpty() ) {
            throw new ServiceManagementException('Household not found.');
            return null;
        }

        Account hh = hhs[0];

        // TODO: validate remaining points? non-negative and under limit (unless setting allows exception)

        // TODO: activate inactive client? or disallow visit?

        // remove the client from checkin list
        Service_Management_Checkin__c fbc = Service_Management_Checkin__c.getInstance( hhid );
        if (fbc != null) delete fbc;

        // log the visit
        Client_Visit__c cv = new Client_Visit__c(
            Household__c = hh.Id,
            Adults__c = hh.Adults__c,
            Seniors__c = hh.Seniors__c,
            Children__c = hh.Children__c,
            Infants__c = hh.Infants__c,
            Homeless__c = hh.Homeless__c,
            Out_Of_Area__c = hh.Out_Of_Area__c,
            Points_Used__c = pointsUsed,
            Checkout_Weight__c = checkoutWeight,
            Box_Type__c = boxType,
            Notes__c = visitNotes,
            Visit_Date__c = (fbc != null && fbc.Check_In_Time__c != null) ? fbc.Check_In_Time__c : system.now(),
            Visitor__c = (fbc != null && fbc.Visitor__c != null) ? fbc.Visitor__c : contactid
        );
        if (commodityUsage != null && !commodityUsage.isEmpty())
            cv.Commodity_Usage_JSON__c = JSON.serializePretty(commodityUsage);
        insert cv;

        // TODO: recalc and save the remaining points on household
        if (pointsUsed != null && pointsUsed > 0) {}

        return cv.id;
    }
}
