global with sharing class LightningSharing {

	global class SharingPermsException extends Exception{}

	@AuraEnabled
	global static boolean canIEditPerms(id recordId){
		//if you're the owner, you're cool
		string query = 'select ownerId from ' + objectTypeFromId(recordId) + ' where id = \'' + string.valueOf(recordId) + '\'';
		sobject o = database.query(query);
		if (o.get('ownerId') == userInfo.getUserID()){
			system.debug('edit allowed because owner');
			return true;
		}

		//if you have modify allData, you're also cool
		list<PermissionSetAssignment> modifiers = [SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSet.PermissionsModifyAllData = true];
		for (PermissionSetAssignment psa:modifiers){
			if (psa.AssigneeId == userInfo.getUserID()){
				system.debug('edit allowed because admin');
				return true;
			}
		}

		return false;
	}

	@AuraEnabled
	global static void deletePerm(id UserOrGroupID, id recordId){
		string query = buildQuery(recordId);
		query = query + ' and UserOrGroupID =\''+UserOrGroupID+'\'';
		system.debug(query);

		list<sobject> existing = database.query(query);
		system.debug(existing);
		delete existing;

	}

	@AuraEnabled
	global static string upsertPerm (id UserOrGroupID, id recordId, string level){

		level = String.escapeSingleQuotes(level);

		if (!canIEditPerms(recordId)){
			throw new SharingPermsException('Only the record owner or administers can modify permissions');
		}
		system.debug('doing perm upsert');

		string query = buildQuery(recordId);
		query = query + ' and UserOrGroupID =\''+UserOrGroupID+'\'';
		system.debug(query);

		list<sobject> existing = database.query(query);
		string sobj = objectTypeFromId(recordId);

		if (existing.size() > 0){
			system.debug('already existing. will update');

			existing[0].put(getAccessLevelField(sobj), level);
			update existing;
			return JSON.serialize(existing);
			} else {
				system.debug('not already existing. will create');

			//create a new SObject dynamically and insert
			Schema.SObjectType newObj = Schema.getGlobalDescribe().get(getSharingTableName(sobj));
			sobject share = newObj.newSObject();

			share.put(getAccessLevelField(sobj),  level);
			share.put(getLookupField(sobj), recordId);
			share.put('UserOrGroupId', UserOrGroupID);

			if (objectTypeFromId(recordId)=='Account'){
				//share.put('ContactAccessLevel', level);
				share.put('CaseAccessLevel', level);
				share.put('OpportunityAccessLevel', level);
			}

			insert share;
			return JSON.serialize(share);
		}
		return null;
	}

	@AuraEnabled
	global static string doSOSL(String searchString, string objectType){
		//Bobby Tables says always sanitize your inputs.
		searchString = String.escapeSingleQuotes(searchString);
		objectType = String.escapeSingleQuotes(objectType);

		string sosl = 'FIND \'*' + searchString + '*\' IN NAME FIELDS RETURNING ' + getReturning(objectType) ;
		list<list<sobject>> results = search.query(sosl);

		list<sobject> output = new list<sobject>();
		for (list<sobject> result:results){
			output.addAll(result);
		}

		return JSON.serialize(output);
	}

	@TestVisible
	private static string getReturning (string objectType){
		//filter out user types that don't have sharing!
		if (objectType == 'User'){
			return 'User(Id, Name, UserType WHERE UserType in (\'Standard\', \'PowerCustomerSuccess\', \'PowerPartner\'))';
		}
		if (objectType == 'Group'){
			return objectType + '(Id, Name, Type)';
		} else {
			return objectType + '(Id, Name)';
		}
	}



@AuraEnabled
global static string objectTypeFromId(id recordId){
	Schema.SObjectType token = recordId.getSObjectType();
	Schema.DescribeSObjectResult dr = token.getDescribe();
	return dr.getName();
}

@AuraEnabled
global static string getSharings(id recordId){
	if (!canIEditPerms(recordId)){
		throw new SharingPermsException('Only the record owner or administers can access permissions');
	}
	list<sobject> results = database.query(buildQuery(recordId));
	list<sharingHolder> output = new list<sharingHolder>();

	set<id> groupAndUserIDs = new set<id>();

	for (sobject so:results){
		sharingHolder sh = new sharingHolder();
		sh.RowCause = string.valueOf(so.get('RowCause'));
		sh.AccessLevel = string.valueOf(so.get(getAccessLevelField(objectTypeFromId(recordId))));
		sh.UserOrGroupID = string.valueOf(so.get('UserOrGroupID'));
		groupAndUserIDs.add(sh.UserOrGroupID);
		output.add(sh);
	}

	map<id, user> UserMap = new map<id, user>([select Name, UserType from User where id in: groupAndUserIDs]);
	map<id, group> GroupMap = new map<id, group>([select Name, Type from Group where id in: groupAndUserIDs]);

	for (sharingHolder sh:output){
		if (UserMap.get(sh.UserOrGroupID)!=null){
			//it's a user
			sh.UserOrGroupType = 'User';
			sh.UserOrGroupName = UserMap.get(sh.UserOrGroupID).Name;
			sh.SubType = huh(UserMap.get(sh.UserOrGroupID).UserType);
			} else if (GroupMap.get(sh.UserOrGroupID)!=null){
				sh.UserOrGroupType = 'Group';
				sh.SubType = GroupMap.get(sh.UserOrGroupID).Type;
				sh.UserOrGroupName = GroupMap.get(sh.UserOrGroupID).Name;
			}
		}

		return JSON.serialize(output);
	}

	@TestVisible private static string buildQuery(id recordId){
		string sobj = objectTypeFromId(recordId);
		string query = 'select Id, RowCause, UserOrGroupId, ' +getAccessLevelField(sobj)+ ' from ' +getSharingTableName(sobj)+ ' where ' + getLookupField(sobj)+ ' = \'' + recordId + '\'';
		system.debug(query);
		return query;
	}

	@TestVisible private static string huh(string userType){
		if (userType == 'PowerCustomerSuccess') {return 'Customer Plus (with Sharing)';}
		else if (userType == 'PowerPartner') {return 'Partner';}
		else if (userType == 'CustomerSuccess') {return 'Customer';}
		else if (userType == 'CsnOnly') {return 'Chatter';}
		else if (userType == 'CSPLitePortal') {return 'High Volume Customer';}
		else {return userType;}
	}

	global class sharingHolder {
		global string UserOrGroupName {get;set;}
		global string SubType {get;set;}
		global string UserOrGroupType {get;set;}
		global string UserOrGroupID {get;set;}
		global string AccessLevel {get;set;}
		global string RowCause {get;set;}
	}

	private static boolean isStandard (string sobj){
		if (sobj=='Account' || sobj=='Asset' || sobj=='Campaign' || sobj =='Case' || sobj=='Contact' || sobj=='Lead' || sobj=='Opportunity' || sobj=='User' ){
			return true;
		}
		return false;
	}

	@TestVisible
	private static string getLookupField (string sobj){
		if (isStandard(sobj)){
			return sobj + 'Id';
		} else {
			return 'ParentId';
		}
	}

	@TestVisible
	private static string getAccessLevelField (string sobj){
		system.debug('accesslevelField received sobject type :' + sobj);
		if (isStandard(sobj)){
			system.debug('is a special object');
			return sobj + 'AccessLevel';
		} else {
			system.debug('is not a special object');
			return 'AccessLevel';
		}
	}

	@TestVisible
	private static string getSharingTableName (string sobj){
		if (sobj.contains('__c')){
			return sobj.replace('__c','__Share');
		} else {
			return sobj+'Share';
		}
	}


}