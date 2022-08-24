def get_urls(base_url):
    urls = {}
    urls.update(dict(
        profile_url = "{0}".format(base_url +
            "/00e?setupid=EnhancedProfiles&retURL=%2Fui%2Fsetup%2FSetup%3Fsetupid%3DUsers"),

        translation_settings_url = "{0}".format(base_url +
            "/i18n/TranslationSplash.apexp?retURL=%2Fui%2Fsetup%2FSetup%3Fsetupid%3DLabelWorkbench&setupid=LabelWorkbenchSetup"),

        chatter_settings_url = "{0}".format(base_url +
            "/collaboration/collaborationSettings.apexp?retURL=%2Fui%2Fsetup%2FSetup%3Fsetupid%3DCollaboration&setupid=CollaborationSettings"),

        case_assignment_rules_url = "{0}".format(base_url +
            "/setup/own/entityrulelist.jsp?rtype=1&entity=Case&setupid=CaseRules&retURL=%2Fui%2Fsetup%2FSetup%3Fsetupid%3DCase"),

        case_escalation_rules_url = "{0}".format(base_url +
            "/setup/own/entityrulelist.jsp?rtype=3&entity=Case&setupid=CaseEscRules&retURL=%2Fui%2Fsetup%2FSetup%3Fsetupid%3DCase"),

        create_apps = "{0}".format(base_url +
            "/02u?retURL=%2Fui%2Fsetup%2FSetup%3Fsetupid%3DDevTools&setupid=TabSet"),

        ui_preferences = "{0}".format(base_url +
            "/ui/setup/org/UserInterfaceUI?setupid=UserInterface&retURL=%2Fui%2Fsetup%2FSetup%3Fsetupid%3DCustomize"),

        social_accounts_contacts_url = "{0}".format(base_url +
            "/ui/setup/socialcrm/SocialProfilesOrgSettingsPage?retURL=%2Fui%2Fsetup%2FSetup%3Fsetupid%3DSocialProfilesOrg&setupid=SocialProfileOrgSettings"),

        packages_url = "{0}".format(base_url +
            "/0A2?setupid=Package&retURL=%2Fui%2Fsetup%2FSetup%3Fsetupid%3DDevTools")
        
               ))
    return urls
