codeunit 33016801 "Premise Management"
{

    trigger OnRun()
    begin
    end;

    var
        ProfileQuestionTmp: Record "Profile Questionnaire Header" temporary;
        Text001: Label 'No Profile Questionnaire is created for this Contact.';
        ProfileQuestnHeaderTemp: Record "Profile Questionnaire Header" temporary;

    procedure ShowAttributeQuestionnaire(PremiseRec: Record Premise; ProfileQuestnLineCode: Code[10]; ProfileQuestnLineLineNo: Integer)
    var
        ProfileQuestnLine: Record "Profile Questionnaire Line";
        ContProfileAnswers: Form "5114";
        ProfileAnswersForm: Form "33016816";
    begin
        ProfileAnswersForm.SetParameters(PremiseRec,
        ProfileQuestionnaireAllowed(PremiseRec, ''), ProfileQuestnLineCode, ProfileQuestnLineLineNo);
        IF ProfileQuestionTmp.GET(ProfileQuestnLineCode) THEN
            ProfileAnswersForm.SETRECORD(ProfileQuestnLine);
        ProfileAnswersForm.LOOKUPMODE(TRUE);
        ProfileAnswersForm.RUN;
    end;

    procedure ProfileQuestionnaireAllowed(PremiseRec: Record Premise; ProfileQuestnHeaderCode: Code[10]): Code[10]
    begin
        FindLegalProfileQuestionnaire(PremiseRec);
        IF ProfileQuestionTmp.GET(ProfileQuestnHeaderCode) THEN
            EXIT(ProfileQuestnHeaderCode)
        ELSE
            IF ProfileQuestionTmp.FINDFIRST THEN
                EXIT(ProfileQuestionTmp.Code)
            ELSE
                ERROR(Text001, ProfileQuestionTmp.TABLECAPTION);
    end;

    procedure FindLegalProfileQuestionnaire(PremiseRec: Record Premise)
    var
        ProfileQuestnHeader: Record "Profile Questionnaire Header";
        ContProfileAnswer: Record "Contact Profile Answer";
        Valid: Boolean;
        ContBusRel: Record "Contact Business Relation";
    begin
        ProfileQuestionTmp.DELETEALL;
        WITH ProfileQuestnHeader DO BEGIN
            RESET;
            IF FINDFIRST THEN
                REPEAT
                    Valid := TRUE;
                    IF Valid THEN BEGIN
                        ProfileQuestionTmp := ProfileQuestnHeader;
                        ProfileQuestionTmp.INSERT;
                    END;
                UNTIL NEXT = 0;
        END;
    end;

    procedure ShowClientQuestionnaireCard(Client: Record Customer; ProfileQuestnLineCode: Code[10]; ProfileQuestnLineLineNo: Integer)
    var
        ProfileQuestnLine: Record "Profile Questionnaire Line";
        ClientProfileAnswers: Form "33016868";
    begin
        ClientProfileAnswers.SetClientParameters(Client, ClientProfileQuestionAllowed(Client, '')
        , ProfileQuestnLineCode, ProfileQuestnLineLineNo);
        IF ProfileQuestnHeaderTemp.GET(ProfileQuestnLineCode) THEN BEGIN
            ProfileQuestnLine.GET(ProfileQuestnLineCode, ProfileQuestnLineLineNo);
            ClientProfileAnswers.SETRECORD(ProfileQuestnLine);
        END;

        ClientProfileAnswers.RUNMODAL;
    end;

    procedure ClientProfileQuestionAllowed(ClientRec: Record Customer; ProfileQuestnHeaderCode: Code[10]): Code[10]
    begin
        FindClientLegalProfileQuestion(ClientRec);
        IF ProfileQuestionTmp.GET(ProfileQuestnHeaderCode) THEN
            EXIT(ProfileQuestnHeaderCode)
        ELSE
            IF ProfileQuestionTmp.FINDFIRST THEN
                EXIT(ProfileQuestionTmp.Code)
            ELSE
                ERROR(Text001, ProfileQuestionTmp.TABLECAPTION);
    end;

    procedure FindClientLegalProfileQuestion(ClientRec: Record Customer)
    var
        ProfileQuestnHeader: Record "Profile Questionnaire Header";
        ContProfileAnswer: Record "Contact Profile Answer";
        Valid: Boolean;
        ContBusRel: Record "Contact Business Relation";
    begin
        ProfileQuestionTmp.DELETEALL;
        WITH ProfileQuestnHeader DO BEGIN
            RESET;
            IF FINDFIRST THEN
                REPEAT
                    Valid := TRUE;
                    IF Valid THEN BEGIN
                        ProfileQuestionTmp := ProfileQuestnHeader;
                        ProfileQuestionTmp.INSERT;
                    END;
                UNTIL NEXT = 0;
        END;
    end;

    procedure CheckName(CurrentQuestionsChecklistCode: Code[10]; var Client: Record Customer)
    begin
        FindClientLegalProfileQuestion(Client);
        ProfileQuestnHeaderTemp.GET(CurrentQuestionsChecklistCode);
    end;

    procedure SetName(ProfileQuestnHeaderCode: Code[10]; var ProfileQuestnLine: Record "Profile Questionnaire Line"; ClientProfileAnswerLine: Integer)
    begin
        ProfileQuestnLine.FILTERGROUP := 2;
        ProfileQuestnLine.SETRANGE("Profile Questionnaire Code", ProfileQuestnHeaderCode);
        ProfileQuestnLine.FILTERGROUP := 0;
        IF ClientProfileAnswerLine = 0 THEN
            IF ProfileQuestnLine.FIND('-') THEN;
    end;

    procedure LookupName(var ProfileQuestnHeaderCode: Code[10]; var ProfileQuestnLine: Record "Profile Questionnaire Line"; var Client: Record Customer)
    begin
        COMMIT;
        FindClientLegalProfileQuestion(Client);
        IF ProfileQuestionTmp.GET(ProfileQuestnHeaderCode) THEN;
        IF FORM.RUNMODAL(FORM::"Profile Questionnaire List", ProfileQuestionTmp) = ACTION::LookupOK THEN
            ProfileQuestnHeaderCode := ProfileQuestionTmp.Code;
        SetName(ProfileQuestnHeaderCode, ProfileQuestnLine, 0);
    end;

    procedure ShowAttributeQuestionnairePage(PremiseRec: Record Premise; ProfileQuestnLineCode: Code[10]; ProfileQuestnLineLineNo: Integer)
    var
        ProfileQuestnLine: Record "Profile Questionnaire Line";
        ContProfileAnswers: Page "5114";
        ProfileAnswersPage: Form "33016816";
    begin
        ProfileAnswersPage.SetParameters(PremiseRec,
        ProfileQuestionnaireAllowed(PremiseRec, ''), ProfileQuestnLineCode, ProfileQuestnLineLineNo);
        IF ProfileQuestionTmp.GET(ProfileQuestnLineCode) THEN
            ProfileAnswersPage.SETRECORD(ProfileQuestnLine);
        ProfileAnswersPage.LOOKUPMODE(TRUE);
        ProfileAnswersPage.RUN;
    end;
}

