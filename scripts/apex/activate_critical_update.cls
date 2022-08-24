/**
 * Enables Fonteva Critical Updates
*/

String updateName = '%%%PARAM_1%%%';
if(!Framework.AppUpdate.isActivated(updateName)){
    Framework.AppUpdate.activateAppUpdate(updateName);
}
