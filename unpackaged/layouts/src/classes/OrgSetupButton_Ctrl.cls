public class OrgSetupButton_Ctrl {

   public Boolean setupComplete { get; set; }
   public Boolean orderApiInstallScripts { get; set; }

   public OrgSetupButton_Ctrl() {
      setupComplete = false;
      orderApiInstallScripts = false;
   }

   public void runReplace() {
      if (OrgSetup_Init.setupOrg()) {
         setupComplete = true;
      }
      else {
         orderApiInstallScripts = true;
      }
   }

}
