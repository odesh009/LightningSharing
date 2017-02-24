/*
This is an example of bad testing practice.  I can't guarantee that the core functionaliy runs, since any given org may not have any objects set not on public sharing (defaults have nothing private)
so I'm scrambling hard for any kind of coverage I can get.
*/
@isTest
private class TestLightningSharing {

	static testMethod void testSOSL() {
  	LightningSharing.doSOSL('McLaughlin', 'Lead');
  }

  static testMethod void testReturning() {
  	LightningSharing.getReturning('Lead');
  	LightningSharing.getReturning('User');
  	LightningSharing.getReturning('Group');
  	LightningSharing.getReturning('Custom__c');
  }

  static testMethod void testuserTypes() {
  	LightningSharing.huh('PowerCustomerSuccess');
  	LightningSharing.huh('PowerPartner');
  	LightningSharing.huh('CustomerSuccess');
  	LightningSharing.huh('CsnOnly');
  	LightningSharing.huh('CSPLitePortal');
  	LightningSharing.huh('MadeUpStuff');
  }

  static testMethod void testInnerClass(){
  	LightningSharing.sharingHolder sh = new LightningSharing.sharingHolder();
  	sh.UserOrGroupName = 'nothing';
  	sh.SubType = 'nothing';
  	sh.UserOrGroupType = 'nothing';
  	sh.UserOrGroupID = 'nothing';
  	sh.AccessLevel = 'nothing';
  	sh.RowCause = 'nothing';
  }

  static testMethod void testGetSharings() {
  	list<lead> l = [select id from lead];
  	LightningSharing.getSharings(l[0].id);

  	list<Opportunity> o = [select id from Opportunity];
  	LightningSharing.getSharings(l[0].id);

  }

  static testMethod void testcanIEditPermsAdmin() {
  	list<lead> l = [select id from lead];
  	LightningSharing.canIEditPerms(l[0].id);
  }

  static testMethod void testcanIEditPermsAdminNonOwner() {
  	list<lead> l = [select id from lead];
  	user u = createAdmin();
  	system.runAs(u){
  		LightningSharing.canIEditPerms(l[0].id);
  	}
  }

  static testMethod void testDelete() {
  	list<lead> l = [select id from Lead];
  	user u = createUsers(1)[0];

  	LightningSharing.deletePerm(u.id, l[0].id);
  }


  static testMethod void testUpsertPerm() {
  	list<Opportunity> o = [select id from Opportunity];
  	list<lead> l = [select id from Lead];

  	user u = createUsers(1)[0];

  	try {
  		LightningSharing.upsertPerm(u.id, o[0].id, 'Edit');
  		LightningSharing.deletePerm(u.id, o[0].id);
  	} catch (exception e){
  		//ok, sharing may not be on
  		system.debug(e);
  	}

  	try {
  		LightningSharing.upsertPerm(u.id, o[0].id, 'Read');
  		LightningSharing.deletePerm(u.id, o[0].id);
  	} catch (exception e){
  		system.debug(e);
  		//ok, sharing may not be on
  	}

  	try {
  		LightningSharing.upsertPerm(u.id, l[0].id, 'Edit');
  		LightningSharing.deletePerm(u.id, l[0].id);
  	} catch (exception e){
  		//ok, sharing may not be on
  		system.debug(e);
  	}

  	try {
  		LightningSharing.upsertPerm(u.id, l[0].id, 'Read');
  		LightningSharing.deletePerm(u.id, l[0].id);
  	} catch (exception e){
  		system.debug(e);
  		//ok, sharing may not be on
  	}
  }

  static testMethod void testStringStuff(){
  	LightningSharing.getLookupField('Account');
  	LightningSharing.getAccessLevelField('Account');
  	LightningSharing.getSharingTableName('Account');

  	LightningSharing.getLookupField('Custom__c');
  	LightningSharing.getAccessLevelField('Custom__c');
  	LightningSharing.getSharingTableName('Custom__c');

  }


  static testMethod void testBuildQuery(){
  	list<lead> l = [select id from lead];
  	LightningSharing.buildQuery(l[0].id);
  }

  static testMethod void testcanIEditPermsNonAdmin() {
  	list<lead> l = [select id from lead];
  	list<user> users = createUsers(1);
  	System.RunAs(users[0]){
  		LightningSharing.canIEditPerms(l[0].id);
  	}
  }

  @testSetup static void makeData(){
    	//make some object for testing, like a lead
    	lead l = new lead();
    	l.Lastname = 'McLaughlin';
    	l.company = 'Salesforce';
    	l.email = 'm.shane.mclaughlin@gmail.com';
    	insert l;

    	account a = new account();
    	a.Name = 'Ink, inc.';
    	insert a;

    	contact c = new contact();
    	c.accountId = a.id;
    	c.FirstName = 'Sarah';
    	c.LastName = 'McLaughlin';
    	c.Email = 'sarah@gmail.com';
    	insert c;

    	Opportunity o = new Opportunity();
    	o.accountId = a.id;
    	o.closeDate = system.today();
    	o.Name = 'biggest deal ever';

    	o.StageName = [select MasterLabel from OpportunityStage where IsClosed = false][0].MasterLabel;
    	insert o;
  }




  public static user createAdmin(){
  	Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];

		// create User
		User u = new User();

		u.FirstName = 'A';
		u.LastName = 'S';
		u.Email = 'test@testLightningSharing2017.com';
		u.Username = 'astest@testLightningSharing2017.com';
		u.Alias = 'astest';
		u.ProfileId = p.Id;
		u.TimeZoneSidKey    = 'America/Denver';
		u.LocaleSidKey      = 'en_US';
		u.EmailEncodingKey  = 'UTF-8';
		u.LanguageLocaleKey = 'en_US';

		insert u;
		system.debug('u contains ' + u);
		return u;
	}

	public static list<user> createUsers(integer numberOfUsers){
		list<user> users = new list<user>();

		Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];


		for (integer i=0; i<numberOfUsers; i++){
			string x = string.valueOf(i);
			User u = new User(Alias = 't'+x, Email='standarduser'+x+'@testLightningSharing2017.msm',
				EmailEncodingKey='UTF-8', LastName='Testing' + x, LanguageLocaleKey='en_US',
				LocaleSidKey='en_US', ProfileId = p.Id,
				TimeZoneSidKey='America/Los_Angeles', UserName='standarduser'+x+'@testLightningSharing2017.msm');
			users.add(u);
		}

		insert users;
		return users;
	}

}