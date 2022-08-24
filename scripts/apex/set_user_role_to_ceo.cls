/**
 * Sets the User Role to CEO
*/
delete [SELECT Id FROM UserRole];
UserRole ur = new UserRole(Name = 'CEO');
insert ur;
if(UserInfo.getUserRoleId() == null){
    User currentUser = new User();
    currentUser.Id = UserInfo.getUserId();
    currentUser.UserRoleId = [Select Id from UserRole WHERE Name = 'CEO'][0].Id;
    if(User.getSobjectType().getDescribe().fields.getMap().keySet().contains('countrycode')){
        currentUser.put('CountryCode','US');
    }
    update currentUser;
}