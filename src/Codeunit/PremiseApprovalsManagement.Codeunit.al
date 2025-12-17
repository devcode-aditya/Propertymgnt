codeunit 33016803 "Premise Approvals Management"
{
    Permissions = TableData 454 = imd,
                  TableData 455 = imd,
                  TableData 456 = imd,
                  TableData 457 = imd,
                  TableData 458 = rimd;

    trigger OnRun()
    begin
    end;

    var
        Text001: Label 'Document can only be released when the approval process is complete.';
        Text002: Label 'Approval Setup not found.';
        ApprovalSetup: Record "Approval Setup";
        Text003: Label 'Approver not found.';
        DispMessage: Boolean;
        Text004: Label '%1 %2 requires further approval.\\Approval request entries have been created.';
        Text005: Label 'No Approval Templates are enabled for document type %1.';
        AddApproversTemp: Record "Approver User Setup" temporary;
        Text006: Label 'User ID %1 does not exist in the User Setup table for %2 %3.';
        ApprovalMgt: Codeunit "439";
        Text007: Label 'Approver ID %1 does not exist in the User Setup table.';
        Text008: Label 'User ID %1 does not exist in the User Setup table.';
        SMTP: Codeunit "400";
        TemplateFile: File;
        SenderName: Text[100];
        SenderAddress: Text[100];
        Recipient: Text[100];
        Subject: Text[100];
        Body: Text[1024];
        InStreamTemplate: InStream;
        InSReadChar: Text[1];
        CharNo: Text[4];
        I: Integer;
        FromUser: Text[100];
        MailCreated: Boolean;
        IsOpenStatusSet: Boolean;
        Text009: Label '%1 %2 has been automatically approved and released.';
        Text010: Label 'requires your approval.';
        Text011: Label 'has been cancelled.';
        Text012: Label 'has been rejected.';
        Text013: Label 'has been delegated.';
        Text014: Label 'To view your documents for approval, please use the following link:';
        Text015: Label 'To view the cancelled document, please use the following link:';
        Text016: Label 'To view the rejected document, please use the following link:';
        Text017: Label 'To view the delegated document, please use the following link:';
        Text018: Label 'Client';
        Text019: Label 'Request Amount (LCY)';
        Text020: Label 'You must import an Approval Template in Approval Setup.';
        Text021: Label 'Microsoft Dynamics NAV: %1 Mail';
        Text022: Label 'Cancellation';
        Text023: Label 'Microsoft Dynamics NAV Document Approval System';
        Text024: Label 'Rejection';
        Text025: Label 'Rejection comments:';
        Text026: Label 'Delegation';
        Text027: Label 'The approval process must be cancelled or completed to reopen this document.';
        Text028: Label '%1 %2 approval request cancelled.';
        Text029: Label 'Approval';
        Text030: Label '%1 for %2  does not exist in the User Setup table.';
        Text031: Label 'No Payment Schedule Lines found for Agreement Type %1 No. %2';
        Text032: Label 'No line exists for Work Order %1';

    procedure PerformManualAgreementRelease(var AgreementHeader: Record "Agreement Header")
    var
        ApprovalEntry: Record "Approval Entry";
        ApprovalManagement: Codeunit "439";
        ApprovedOnly: Boolean;
    begin
        ValidateAgreementDetails(AgreementHeader);
        ValidateAgreementPaySchedule(AgreementHeader);
        WITH AgreementHeader DO BEGIN
            IF CheckAgreementApprovalTemplate(AgreementHeader) THEN BEGIN
                CASE "Approval Status" OF
                    "Approval Status"::"Pending Approval":
                        ERROR(Text001);
                    "Approval Status"::Open:
                        BEGIN
                            ApprovedOnly := TRUE;
                            ApprovalEntry.SETCURRENTKEY("Table ID", "Document Type", "Document No.", "Sequence No.");
                            ApprovalEntry.SETRANGE("Table ID", DATABASE::"Agreement Header");
                            IF "Agreement Type" = "Agreement Type"::Lease THEN
                                ApprovalEntry.SETRANGE("Document Type", ApprovalEntry."Document Type"::Lease)
                            ELSE
                                IF "Agreement Type" = "Agreement Type"::Sale THEN
                                    ApprovalEntry.SETRANGE("Document Type", ApprovalEntry."Document Type"::Sale);
                            ApprovalEntry.SETRANGE("Document No.", "No.");
                            ApprovalEntry.SETFILTER(Status, '<>%1&<>%2', ApprovalEntry.Status::Rejected, ApprovalEntry.Status::Canceled);
                            IF ApprovalEntry.FINDFIRST THEN BEGIN
                                REPEAT
                                    IF (ApprovedOnly = TRUE) AND (ApprovalEntry.Status <> ApprovalEntry.Status::Approved) THEN
                                        ApprovedOnly := FALSE;
                                UNTIL ApprovalEntry.NEXT = 0;

                                IF ApprovedOnly = TRUE AND TestAgreementApprovalLimit(AgreementHeader) THEN
                                    UpdateAgreementApprovalStatus(AgreementHeader)
                                ELSE
                                    ERROR(Text001);
                            END ELSE
                                ERROR(Text001);
                        END;
                END;
            END ELSE
                UpdateAgreementApprovalStatus(AgreementHeader);
        END;
    end;

    procedure PerformManualWORelease(var WorkOrderHeader: Record "Work Order Header")
    var
        ApprovalEntry: Record "Approval Entry";
        ApprovalManagement: Codeunit "439";
        ApprovedOnly: Boolean;
    begin
        WITH WorkOrderHeader DO BEGIN
            IF CheckWOApprovalTemplate(WorkOrderHeader) THEN BEGIN
                CASE "Approval Status" OF
                    "Approval Status"::"Pending Approval":
                        ERROR(Text001);
                    "Approval Status"::Open:
                        BEGIN
                            ApprovedOnly := TRUE;
                            ApprovalEntry.SETCURRENTKEY("Table ID", "Document Type", "Document No.", "Sequence No.");
                            ApprovalEntry.SETRANGE("Table ID", DATABASE::"Work Order Header");
                            ApprovalEntry.SETRANGE("Document Type", ApprovalEntry."Document Type"::"Work Order");
                            ApprovalEntry.SETRANGE("Document No.", "Premise/Facility No.");
                            ApprovalEntry.SETFILTER(Status, '<>%1&<>%2', ApprovalEntry.Status::Rejected, ApprovalEntry.Status::Canceled);
                            IF ApprovalEntry.FINDFIRST THEN BEGIN
                                REPEAT
                                    IF (ApprovedOnly = TRUE) AND (ApprovalEntry.Status <> ApprovalEntry.Status::Approved) THEN
                                        ApprovedOnly := FALSE;
                                UNTIL ApprovalEntry.NEXT = 0;

                                IF ApprovedOnly = TRUE AND TestWOApprovalLimit(WorkOrderHeader) THEN
                                    UpdateWOApprovalStatus(WorkOrderHeader)
                                ELSE
                                    ERROR(Text001);
                            END ELSE
                                ERROR(Text001);
                        END;
                END;
            END ELSE
                UpdateWOApprovalStatus(WorkOrderHeader);
        END;
    end;

    procedure CheckAgreementApprovalTemplate(AgreementHeader: Record "Agreement Header"): Boolean
    var
        ApprovalTemplate: Record "Approval Template";
    begin
        ApprovalTemplate.RESET;
        ApprovalTemplate.SETCURRENTKEY("Table ID", "Document Type", Enabled);
        ApprovalTemplate.SETRANGE("Table ID", DATABASE::"Agreement Header");
        ApprovalTemplate.SETRANGE(Enabled, TRUE);
        IF AgreementHeader."Agreement Type" = AgreementHeader."Agreement Type"::Lease THEN
            ApprovalTemplate.SETRANGE("Document Type", ApprovalTemplate."Document Type"::Lease)
        ELSE
            IF AgreementHeader."Agreement Type" = AgreementHeader."Agreement Type"::Sale THEN
                ApprovalTemplate.SETRANGE("Document Type", ApprovalTemplate."Document Type"::Sale);

        IF ApprovalTemplate.FINDFIRST THEN
            EXIT(TRUE)
        ELSE
            EXIT(FALSE);
    end;

    procedure CheckWOApprovalTemplate(WorkOrderHeader: Record "Work Order Header"): Boolean
    var
        ApprovalTemplate: Record "Approval Template";
    begin
        ApprovalTemplate.RESET;
        ApprovalTemplate.SETCURRENTKEY("Table ID", "Document Type", Enabled);
        ApprovalTemplate.SETRANGE("Table ID", DATABASE::"Work Order Header");
        ApprovalTemplate.SETRANGE(Enabled, TRUE);
        ApprovalTemplate.SETRANGE("Document Type", ApprovalTemplate."Document Type"::"Work Order");
        IF ApprovalTemplate.FINDFIRST THEN
            EXIT(TRUE)
        ELSE
            EXIT(FALSE);
    end;

    procedure TestAgreementApprovalLimit(AgreementHeader: Record "Agreement Header"): Boolean
    var
        UserSetup: Record "User Setup";
        AppManagement: Codeunit "439";
        AppAmount: Decimal;
        AppAmountLCY: Decimal;
    begin
        SendAgreementApprovalRequest(AgreementHeader);
        UserSetup.GET(USERID);
        IF UserSetup."Unlimited Agreement Approval" THEN
            EXIT(TRUE)
        ELSE BEGIN
            IF AppAmountLCY > UserSetup."Agreement Amt. App. Limit" THEN
                ERROR(Text001)
            ELSE
                EXIT(TRUE);
        END;
    end;

    procedure TestWOApprovalLimit(WorkOrderHeader: Record "Work Order Header"): Boolean
    var
        UserSetup: Record "User Setup";
        AppManagement: Codeunit "439";
        AppAmount: Decimal;
        AppAmountLCY: Decimal;
    begin
        SendWOApprovalRequest(WorkOrderHeader);
        UserSetup.GET(USERID);
        IF UserSetup."Unlimited Work Order Approval" THEN
            EXIT(TRUE)
        ELSE BEGIN
            IF AppAmountLCY > UserSetup."Work Order Amt. App. Limit" THEN
                ERROR(Text001)
            ELSE
                EXIT(TRUE);
        END;
    end;

    procedure SendAgreementApprovalRequest(var AgreementHeader: Record "Agreement Header"): Boolean
    var
        TemplateRec: Record "Approval Template";
    begin
        TestSetup;
        ValidateAgreementDetails(AgreementHeader);
        ValidateAgreementPaySchedule(AgreementHeader);
        WITH AgreementHeader DO BEGIN
            IF "Long Term Agreement" THEN
                TESTFIELD("LT Agreement Expiry Date");
            IF "Approval Status" <> "Approval Status"::Open THEN
                EXIT(FALSE);
            TemplateRec.RESET;
            TemplateRec.SETCURRENTKEY("Table ID", "Document Type", Enabled);
            TemplateRec.SETRANGE("Table ID", DATABASE::"Agreement Header");
            TemplateRec.SETRANGE(Enabled, TRUE);
            IF AgreementHeader."Agreement Type" = AgreementHeader."Agreement Type"::Lease THEN
                TemplateRec.SETRANGE("Document Type", TemplateRec."Document Type"::Lease)
            ELSE
                IF AgreementHeader."Agreement Type" = AgreementHeader."Agreement Type"::Sale THEN
                    TemplateRec.SETRANGE("Document Type", TemplateRec."Document Type"::Sale);
            IF TemplateRec.FINDFIRST THEN BEGIN
                REPEAT
                    IF NOT FindAgreementApprover(AgreementHeader, ApprovalSetup, TemplateRec) THEN
                        ERROR(Text003);
                UNTIL TemplateRec.NEXT = 0;
                IF DispMessage THEN
                    MESSAGE(Text004, FORMAT("Agreement Type"), "No.");
            END ELSE
                ERROR(STRSUBSTNO(Text005, "Agreement Type"));
        END;
    end;

    procedure SendWOApprovalRequest(var WorkOrderHeader: Record "Work Order Header"): Boolean
    var
        TemplateRec: Record "Approval Template";
        WOLine: Record "Work Order Line";
    begin
        TestSetup;
        WITH WorkOrderHeader DO BEGIN
            WOLine.SETRANGE("Document Type", WorkOrderHeader."Document Type");
            WOLine.SETRANGE("Document No.", WorkOrderHeader."No.");
            WOLine.SETFILTER(Code, '<>%1', '');
            IF NOT WOLine.FINDFIRST THEN
                ERROR(Text032, WorkOrderHeader."No.");
            IF "Approval Status" <> "Approval Status"::Open THEN
                EXIT(FALSE);
            TemplateRec.RESET;
            TemplateRec.SETCURRENTKEY("Table ID", "Document Type", Enabled);
            TemplateRec.SETRANGE("Table ID", DATABASE::"Work Order Header");
            TemplateRec.SETRANGE(Enabled, TRUE);
            TemplateRec.SETRANGE("Document Type", TemplateRec."Document Type"::"Work Order");
            IF TemplateRec.FINDFIRST THEN BEGIN
                REPEAT
                    IF NOT FindWOApprover(WorkOrderHeader, ApprovalSetup, TemplateRec) THEN
                        ERROR(Text003);
                UNTIL TemplateRec.NEXT = 0;
                IF DispMessage THEN
                    MESSAGE(Text004, FORMAT("Document Type"), "No.");
            END ELSE
                ERROR(STRSUBSTNO(Text005, "Document Type"));
        END;
    end;

    procedure TestSetup()
    begin
        IF NOT ApprovalSetup.GET THEN
            ERROR(Text002);
    end;

    procedure FindAgreementApprover(AgreementHeader: Record "Agreement Header"; ApprovalSetup: Record "Approval Setup"; AppTemplate: Record "Approval Template"): Boolean
    var
        UserSetup: Record "User Setup";
        ApprovalEntry: Record "Approval Entry";
        ApprovalMgtNotification: Codeunit "440";
        ApproverId: Code[20];
        EntryApproved: Boolean;
        DocReleased: Boolean;
        ApprovalAmount: Decimal;
        ApprovalAmountLCY: Decimal;
        AgreementLine: Record "Agreement Line";
        DocType: Integer;
    begin
        AddApproversTemp.RESET;
        AddApproversTemp.DELETEALL;

        CLEAR(DocType);
        IF AgreementHeader."Agreement Type" = AgreementHeader."Agreement Type"::Lease THEN
            DocType := 6
        ELSE
            IF AgreementHeader."Agreement Type" = AgreementHeader."Agreement Type"::Sale THEN
                DocType := 7;

        CalcAgreementDocAmount(AgreementHeader, ApprovalAmount, ApprovalAmountLCY);

        CASE AppTemplate."Approval Type" OF
            AppTemplate."Approval Type"::"Sales Pers./Purchaser":
                BEGIN
                    IF AgreementHeader."Salesperson Code" <> '' THEN BEGIN
                        CASE AppTemplate."Limit Type" OF

                            AppTemplate."Limit Type"::"Approval Limits":
                                BEGIN
                                    UserSetup.RESET;
                                    UserSetup.SETCURRENTKEY("Salespers./Purch. Code");
                                    UserSetup.SETRANGE("Salespers./Purch. Code", AgreementHeader."Salesperson Code");
                                    IF NOT UserSetup.FINDFIRST THEN
                                        ERROR(Text006, UserSetup."User ID", UserSetup.FIELDCAPTION("Salespers./Purch. Code"), UserSetup."Salespers./Purch. Code")
                                    ELSE BEGIN
                                        ApproverId := UserSetup."User ID";
                                        ApprovalMgt.MakeApprovalEntry(DATABASE::"Agreement Header", DocType, AgreementHeader."No.",
                                          AgreementHeader."Salesperson Code", ApprovalSetup, ApproverId, AppTemplate."Approval Code", UserSetup,
                                          ApprovalAmount, ApprovalAmountLCY, '', AppTemplate, 0);

                                        ApproverId := UserSetup."Approver ID";
                                        IF NOT UserSetup."Unlimited Agreement Approval" AND
                                         ((ApprovalAmountLCY > UserSetup."Agreement Amt. App. Limit") OR
                                         (UserSetup."Agreement Amt. App. Limit" = 0))
                                        THEN BEGIN
                                            UserSetup.RESET;
                                            UserSetup.SETCURRENTKEY("User ID");
                                            UserSetup.SETRANGE("User ID", ApproverId);
                                            REPEAT
                                                IF NOT UserSetup.FINDFIRST THEN
                                                    ERROR(Text007, ApproverId);
                                                ApproverId := UserSetup."User ID";
                                                ApprovalMgt.MakeApprovalEntry(
                                                  DATABASE::"Agreement Header", DocType, AgreementHeader."No.", '',
                                                  ApprovalSetup, ApproverId, AppTemplate."Approval Code", UserSetup, ApprovalAmount, ApprovalAmountLCY,
                                                  '', AppTemplate, 0);
                                                UserSetup.SETRANGE("User ID", UserSetup."Approver ID");
                                            UNTIL UserSetup."Unlimited Agreement Approval" OR
                                                  ((ApprovalAmountLCY <= UserSetup."Agreement Amt. App. Limit") AND
                                                  (UserSetup."Agreement Amt. App. Limit" <> 0)) OR
                                                  (UserSetup."User ID" = UserSetup."Approver ID")
                                        END;
                                    END;

                                    CheckAddApprovers(AppTemplate);
                                    IF AddApproversTemp.FINDFIRST THEN
                                        REPEAT
                                            ApproverId := AddApproversTemp."Approver ID";
                                            ApprovalMgt.MakeApprovalEntry(
                                              DATABASE::"Agreement Header", DocType, AgreementHeader."No.", '',
                                              ApprovalSetup, ApproverId, AppTemplate."Approval Code", UserSetup, ApprovalAmount, ApprovalAmountLCY,
                                              '', AppTemplate, 0);
                                        UNTIL AddApproversTemp.NEXT = 0;
                                END;

                            AppTemplate."Limit Type"::"No Limits":
                                BEGIN
                                    UserSetup.RESET;
                                    UserSetup.SETCURRENTKEY("Salespers./Purch. Code");
                                    UserSetup.SETRANGE("Salespers./Purch. Code", AgreementHeader."Salesperson Code");
                                    IF NOT UserSetup.FINDFIRST THEN
                                        ERROR(Text006, UserSetup."User ID", UserSetup.FIELDCAPTION("Salespers./Purch. Code"),
                                         UserSetup."Salespers./Purch. Code")
                                    ELSE BEGIN
                                        ApproverId := UserSetup."User ID";
                                        ApprovalMgt.MakeApprovalEntry(
                                          DATABASE::"Agreement Header", DocType, AgreementHeader."No.",
                                          AgreementHeader."Salesperson Code", ApprovalSetup, ApproverId, AppTemplate."Approval Code",
                                          UserSetup, ApprovalAmount, ApprovalAmountLCY, '', AppTemplate, 0);

                                        CheckAddApprovers(AppTemplate);
                                        IF AddApproversTemp.FINDFIRST THEN
                                            REPEAT
                                                ApproverId := AddApproversTemp."Approver ID";
                                                ApprovalMgt.MakeApprovalEntry(
                                                  DATABASE::"Agreement Header", DocType, AgreementHeader."No.", '',
                                                  ApprovalSetup, ApproverId, AppTemplate."Approval Code", UserSetup, ApprovalAmount, ApprovalAmountLCY,
                                                  '', AppTemplate, 0);
                                            UNTIL AddApproversTemp.NEXT = 0;
                                    END;
                                END;
                        END;
                    END;
                END;

            AppTemplate."Approval Type"::Approver:
                BEGIN
                    UserSetup.SETRANGE("User ID", USERID);
                    IF NOT UserSetup.FINDFIRST THEN
                        ERROR(Text008, USERID);

                    CASE AppTemplate."Limit Type" OF
                        AppTemplate."Limit Type"::"Approval Limits":
                            BEGIN
                                ApproverId := UserSetup."User ID";
                                ApprovalMgt.MakeApprovalEntry(
                                  DATABASE::"Agreement Header", DocType, AgreementHeader."No.", '',
                                  ApprovalSetup, ApproverId, AppTemplate."Approval Code", UserSetup, ApprovalAmount, ApprovalAmountLCY,
                                  '', AppTemplate, 0);

                                IF NOT UserSetup."Unlimited Agreement Approval" AND
                                   ((ApprovalAmountLCY > UserSetup."Agreement Amt. App. Limit") OR
                                   (UserSetup."Agreement Amt. App. Limit" = 0))
                                THEN
                                    REPEAT
                                        UserSetup.SETRANGE("User ID", UserSetup."Approver ID");
                                        IF NOT UserSetup.FINDFIRST THEN
                                            ERROR(Text008, USERID);
                                        ApproverId := UserSetup."User ID";
                                        ApprovalMgt.MakeApprovalEntry(
                                          DATABASE::"Agreement Header", DocType, AgreementHeader."No.", '',
                                          ApprovalSetup, ApproverId, AppTemplate."Approval Code", UserSetup, ApprovalAmount, ApprovalAmountLCY,
                                          '', AppTemplate, 0);
                                    UNTIL UserSetup."Unlimited Agreement Approval" OR
                                 ((ApprovalAmountLCY <= UserSetup."Agreement Amt. App. Limit") AND
                                 (UserSetup."Agreement Amt. App. Limit" <> 0)) OR
                                 (UserSetup."User ID" = UserSetup."Approver ID");

                                CheckAddApprovers(AppTemplate);
                                IF AddApproversTemp.FINDFIRST THEN
                                    REPEAT
                                        ApproverId := AddApproversTemp."Approver ID";
                                        ApprovalMgt.MakeApprovalEntry(
                                          DATABASE::"Agreement Header", DocType, AgreementHeader."No.", '',
                                          ApprovalSetup, ApproverId, AppTemplate."Approval Code", UserSetup, ApprovalAmount, ApprovalAmountLCY,
                                          '', AppTemplate, 0);
                                    UNTIL AddApproversTemp.NEXT = 0;
                            END;
                    END;
                END;

            AppTemplate."Limit Type"::"No Limits":
                BEGIN
                    ApproverId := UserSetup."Approver ID";
                    IF ApproverId = '' THEN
                        ApproverId := UserSetup."User ID";
                    ApprovalMgt.MakeApprovalEntry(
                      DATABASE::"Agreement Header", DocType, AgreementHeader."No.", '',
                      ApprovalSetup, ApproverId, AppTemplate."Approval Code", UserSetup, ApprovalAmount, ApprovalAmountLCY,
                      '', AppTemplate, 0);

                    CheckAddApprovers(AppTemplate);
                    IF AddApproversTemp.FINDFIRST THEN
                        REPEAT
                            ApproverId := AddApproversTemp."Approver ID";
                            ApprovalMgt.MakeApprovalEntry(
                              DATABASE::"Agreement Header", DocType, AgreementHeader."No.", '',
                              ApprovalSetup, ApproverId, AppTemplate."Approval Code", UserSetup, ApprovalAmount, ApprovalAmountLCY,
                              '', AppTemplate, 0);
                        UNTIL AddApproversTemp.NEXT = 0;
                END;
        END;

        EntryApproved := FALSE;
        DocReleased := FALSE;
        WITH ApprovalEntry DO BEGIN
            INIT;
            SETRANGE("Table ID", DATABASE::"Agreement Header");
            IF AgreementHeader."Agreement Type" = AgreementHeader."Agreement Type"::Lease THEN
                SETRANGE("Document Type", "Document Type"::Lease)
            ELSE
                IF AgreementHeader."Agreement Type" = AgreementHeader."Agreement Type"::Sale THEN
                    SETRANGE("Document Type", "Document Type"::Sale);
            SETRANGE("Document No.", AgreementHeader."No.");
            SETRANGE(Status, Status::Created);
            IF FINDSET(TRUE, FALSE) THEN
                REPEAT
                    IF "Sender ID" = "Approver ID" THEN BEGIN
                        Status := Status::Approved;
                        MODIFY;
                    END ELSE
                        IF NOT IsOpenStatusSet THEN BEGIN
                            Status := Status::Open;
                            MODIFY;
                            IsOpenStatusSet := TRUE;
                            IF ApprovalSetup.Approvals THEN
                                SendApprovalsMail(ApprovalEntry);
                        END;
                UNTIL NEXT = 0;
            SETFILTER(Status, '=%1|%2|%3', Status::Approved, Status::Created, Status::Open);

            IF FINDFIRST THEN
                REPEAT
                    IF Status = Status::Approved THEN
                        EntryApproved := TRUE
                    ELSE
                        EntryApproved := FALSE;
                UNTIL NEXT = 0;

            IF EntryApproved THEN BEGIN
                DocReleased := ApproveApprovalRequest(ApprovalEntry);
                DispMessage := FALSE;
            END;
            IF NOT DocReleased THEN BEGIN
                AgreementHeader."Approval Status" := AgreementHeader."Approval Status"::"Pending Approval";
                AgreementHeader.MODIFY(TRUE);
                DispMessage := TRUE;
                EXIT(TRUE);
            END;
        END;

        IF DocReleased THEN BEGIN
            MESSAGE(Text009, AgreementHeader."Agreement Type", AgreementHeader."No.");
            EXIT(TRUE);
        END;
    end;

    procedure FindWOApprover(WorkOrderHeader: Record "Work Order Header"; ApprovalSetup: Record "Approval Setup"; AppTemplate: Record "Approval Template"): Boolean
    var
        UserSetup: Record "User Setup";
        ApprovalEntry: Record "Approval Entry";
        ApprovalMgtNotification: Codeunit "440";
        ApproverId: Code[20];
        EntryApproved: Boolean;
        DocReleased: Boolean;
        ApprovalAmount: Decimal;
        ApprovalAmountLCY: Decimal;
        WorkOrderLine: Record "Work Order Line";
        DocType: Integer;
    begin
        AddApproversTemp.RESET;
        AddApproversTemp.DELETEALL;

        CLEAR(DocType);
        DocType := 8;
        CalcWODocAmount(WorkOrderHeader, ApprovalAmount, ApprovalAmountLCY);

        CASE AppTemplate."Approval Type" OF
            AppTemplate."Approval Type"::Approver:
                BEGIN
                    UserSetup.SETRANGE("User ID", USERID);
                    IF NOT UserSetup.FINDFIRST THEN
                        ERROR(Text008, USERID);

                    CASE AppTemplate."Limit Type" OF
                        AppTemplate."Limit Type"::"Approval Limits":
                            BEGIN
                                ApproverId := UserSetup."User ID";
                                ApprovalMgt.MakeApprovalEntry(
                                  DATABASE::"Work Order Header", DocType, WorkOrderHeader."No.", '',
                                  ApprovalSetup, ApproverId, AppTemplate."Approval Code", UserSetup, ApprovalAmount, ApprovalAmountLCY,
                                  '', AppTemplate, 0);

                                IF NOT UserSetup."Unlimited Work Order Approval" AND
                                   ((ApprovalAmountLCY > UserSetup."Work Order Amt. App. Limit") OR
                                   (UserSetup."Work Order Amt. App. Limit" = 0))
                                THEN
                                    REPEAT
                                        UserSetup.SETRANGE("User ID", UserSetup."Approver ID");
                                        IF NOT UserSetup.FINDFIRST THEN
                                            ERROR(Text008, USERID);
                                        ApproverId := UserSetup."User ID";
                                        ApprovalMgt.MakeApprovalEntry(
                                          DATABASE::"Work Order Header", DocType, WorkOrderHeader."No.", '',
                                          ApprovalSetup, ApproverId, AppTemplate."Approval Code", UserSetup, ApprovalAmount, ApprovalAmountLCY,
                                          '', AppTemplate, 0);
                                    UNTIL UserSetup."Unlimited Work Order Approval" OR
                                 ((ApprovalAmountLCY <= UserSetup."Work Order Amt. App. Limit") AND
                                 (UserSetup."Work Order Amt. App. Limit" <> 0)) OR
                                 (UserSetup."User ID" = UserSetup."Approver ID");

                                CheckAddApprovers(AppTemplate);
                                IF AddApproversTemp.FINDFIRST THEN
                                    REPEAT
                                        ApproverId := AddApproversTemp."Approver ID";
                                        ApprovalMgt.MakeApprovalEntry(
                                          DATABASE::"Work Order Header", DocType, WorkOrderHeader."No.", '',
                                          ApprovalSetup, ApproverId, AppTemplate."Approval Code", UserSetup, ApprovalAmount, ApprovalAmountLCY,
                                          '', AppTemplate, 0);
                                    UNTIL AddApproversTemp.NEXT = 0;
                            END;
                    END;
                END;

            AppTemplate."Limit Type"::"No Limits":
                BEGIN
                    ApproverId := UserSetup."Approver ID";
                    IF ApproverId = '' THEN
                        ApproverId := UserSetup."User ID";
                    ApprovalMgt.MakeApprovalEntry(
                      DATABASE::"Work Order Header", DocType, WorkOrderHeader."No.", '',
                      ApprovalSetup, ApproverId, AppTemplate."Approval Code", UserSetup, ApprovalAmount, ApprovalAmountLCY,
                      '', AppTemplate, 0);

                    CheckAddApprovers(AppTemplate);
                    IF AddApproversTemp.FINDFIRST THEN
                        REPEAT
                            ApproverId := AddApproversTemp."Approver ID";
                            ApprovalMgt.MakeApprovalEntry(
                              DATABASE::"Work Order Header", DocType, WorkOrderHeader."No.", '',
                              ApprovalSetup, ApproverId, AppTemplate."Approval Code", UserSetup, ApprovalAmount, ApprovalAmountLCY,
                              '', AppTemplate, 0);
                        UNTIL AddApproversTemp.NEXT = 0;
                END;
        END;

        EntryApproved := FALSE;
        DocReleased := FALSE;
        WITH ApprovalEntry DO BEGIN
            INIT;
            SETRANGE("Table ID", DATABASE::"Work Order Header");
            SETRANGE("Document Type", ApprovalEntry."Document Type"::"Work Order");
            SETRANGE("Document No.", WorkOrderHeader."No.");
            SETRANGE(Status, Status::Created);
            IF FINDSET(TRUE, FALSE) THEN
                REPEAT
                    IF "Sender ID" = "Approver ID" THEN BEGIN
                        Status := Status::Approved;
                        MODIFY;
                    END ELSE
                        IF NOT IsOpenStatusSet THEN BEGIN
                            Status := Status::Open;
                            MODIFY;
                            IsOpenStatusSet := TRUE;
                            IF ApprovalSetup.Approvals THEN
                                SendApprovalsMail(ApprovalEntry);
                        END;
                UNTIL NEXT = 0;
            SETFILTER(Status, '=%1|%2|%3', Status::Approved, Status::Created, Status::Open);

            IF FINDFIRST THEN
                REPEAT
                    IF Status = Status::Approved THEN
                        EntryApproved := TRUE
                    ELSE
                        EntryApproved := FALSE;
                UNTIL NEXT = 0;

            IF EntryApproved THEN BEGIN
                DocReleased := ApproveApprovalRequest(ApprovalEntry);
                DispMessage := FALSE;
            END;
            IF NOT DocReleased THEN BEGIN
                WorkOrderHeader."Approval Status" := WorkOrderHeader."Approval Status"::"Pending Approval";
                WorkOrderHeader.MODIFY(TRUE);
                DispMessage := TRUE;
                EXIT(TRUE);
            END;
        END;

        IF DocReleased THEN BEGIN
            MESSAGE(Text009, WorkOrderHeader."Document Type", WorkOrderHeader."No.");
            EXIT(TRUE);
        END;
    end;

    procedure CalcAgreementDocAmount(AgreementHeader: Record "Agreement Header"; var ApprovalAmount: Decimal; var ApprovalAmountLCY: Decimal)
    var
        AgreementLineTmp: Record "33016816" temporary;
        TempAmount: Decimal;
        VAtText: Text[30];
        AgreementLine: Record "Agreement Line";
    begin
        AgreementLine.RESET;
        AgreementLine.SETRANGE("Agreement Type", AgreementHeader."Agreement Type");
        AgreementLine.SETRANGE("Agreement No.", AgreementHeader."No.");
        IF AgreementLine.FINDFIRST THEN
            REPEAT
                ApprovalAmount := ApprovalAmount + AgreementLine."Original Amount";
            UNTIL AgreementLine.NEXT = 0;
        ApprovalAmountLCY := ApprovalAmount;
    end;

    procedure CalcWODocAmount(WorkOrderHeader: Record "Work Order Header"; var ApprovalAmount: Decimal; var ApprovalAmountLCY: Decimal)
    var
        TempAmount: Decimal;
        VAtText: Text[30];
        WorkOrderLine: Record "Work Order Line";
    begin
        WorkOrderLine.RESET;
        WorkOrderLine.SETRANGE("Document Type", WorkOrderHeader."Document Type"::"Work Order");
        WorkOrderLine.SETRANGE("Document No.", WorkOrderHeader."No.");
        IF WorkOrderLine.FINDFIRST THEN
            REPEAT
                ApprovalAmount := ApprovalAmount + WorkOrderLine."Sales Amount";
            UNTIL WorkOrderLine.NEXT = 0;
        ApprovalAmountLCY := ApprovalAmount;
    end;

    procedure CheckAddApprovers(AppTemplate: Record "Approval Template")
    begin
        AppTemplate.CALCFIELDS("Additional Approvers");
        IF AppTemplate."Additional Approvers" THEN
            InsertAddApprovers(AppTemplate);
    end;

    procedure InsertAddApprovers(AppTemplate: Record "Approval Template")
    var
        AddApprovers: Record "Approver User Setup";
    begin
        CLEAR(AddApproversTemp);
        AddApprovers.SETCURRENTKEY("Sequence No.");
        AddApprovers.SETRANGE("Approval Code", AppTemplate."Approval Code");
        AddApprovers.SETRANGE("Approval Type", AppTemplate."Approval Type");
        CASE AppTemplate."Document Type" OF
            AppTemplate."Document Type"::Lease:
                AddApprovers.SETRANGE("Document Type", AddApprovers."Document Type"::Lease);
            AppTemplate."Document Type"::Sale:
                AddApprovers.SETRANGE("Document Type", AddApprovers."Document Type"::Sale);
            AppTemplate."Document Type"::"Work Order":
                AddApprovers.SETRANGE("Document Type", AddApprovers."Document Type"::"Work Order");
        END;
        AddApprovers.SETRANGE("Limit Type", AppTemplate."Limit Type");
        IF AddApprovers.FINDFIRST THEN
            REPEAT
                AddApproversTemp := AddApprovers;
                AddApproversTemp.INSERT;
            UNTIL AddApprovers.NEXT = 0;
    end;

    procedure SendApprovalsMail(ApprovalEntry: Record "Approval Entry")
    begin
        IF ApprovalRecordExist(ApprovalEntry) THEN BEGIN
            SetTemplate(ApprovalEntry);
            Subject := STRSUBSTNO(Text021, Text029);
            Body := Text023;

            SMTP.CreateMessage(SenderName, SenderAddress, Recipient, Subject, Body, TRUE);
            Body := '';

            WHILE InStreamTemplate.READ(InSReadChar, 1) <> 0 DO BEGIN
                IF InSReadChar = '%' THEN BEGIN
                    SMTP.AppendBody(Body);
                    Body := InSReadChar;
                    IF InStreamTemplate.READ(InSReadChar, 1) <> 0 THEN;
                    IF (InSReadChar >= '0') AND (InSReadChar <= '9') THEN BEGIN
                        Body := Body + '1';
                        CharNo := InSReadChar;
                        WHILE (InSReadChar >= '0') AND (InSReadChar <= '9') DO BEGIN
                            IF InStreamTemplate.READ(InSReadChar, 1) <> 0 THEN;
                            IF (InSReadChar >= '0') AND (InSReadChar <= '9') THEN
                                CharNo := CharNo + InSReadChar;
                        END;
                    END ELSE
                        Body := Body + InSReadChar;
                    FillTemplate(Body, CharNo, ApprovalEntry, 0);
                    SMTP.AppendBody(Body);
                    Body := InSReadChar;
                END ELSE BEGIN
                    Body := Body + InSReadChar;
                    I := I + 1;
                    IF I = 500 THEN BEGIN
                        SMTP.AppendBody(Body);
                        Body := '';
                        I := 0;
                    END;
                END;
            END;
            SMTP.AppendBody(Body);
            SMTP.Send;
            TemplateFile.CLOSE;
        END;
    end;

    procedure FillTemplate(var Body: Text[254]; TextNo: Text[30]; AppEntry: Record "Approval Entry"; CalledFrom: Option Approve,Cancel,Reject,Delegate)
    var
        Customer: Record Customer;
        DocumentType: Text[30];
        DocumentNo: Code[20];
        ClientNo: Code[20];
        ClientName: Text[50];
        AgreementRec: Record "Agreement Header";
        WorkOrderRec: Record "Work Order Header";
    begin
        CLEAR(DocumentType);
        CLEAR(DocumentNo);
        CLEAR(ClientNo);
        CLEAR(ClientName);
        CASE AppEntry."Table ID" OF
            DATABASE::"Agreement Header":
                BEGIN
                    IF AppEntry."Document Type" = AppEntry."Document Type"::Sale THEN BEGIN
                        IF AgreementRec.GET(AgreementRec."Agreement Type"::Sale, AppEntry."Document No.") THEN BEGIN
                            DocumentType := 'Sale';
                            DocumentNo := AgreementRec."No.";
                            ClientNo := AgreementRec."Client No.";
                            IF Customer.GET(ClientNo) THEN
                                ClientName := Customer.Name;
                        END;
                    END ELSE
                        IF AppEntry."Document Type" = AppEntry."Document Type"::Lease THEN BEGIN
                            IF AgreementRec.GET(AgreementRec."Agreement Type"::Lease, AppEntry."Document No.") THEN BEGIN
                                DocumentType := 'Lease';
                                DocumentNo := AgreementRec."No.";
                                ClientNo := AgreementRec."Client No.";
                                IF Customer.GET(ClientNo) THEN
                                    ClientName := Customer.Name;
                            END;
                        END;
                END;
            DATABASE::"Work Order Header":
                BEGIN
                    IF WorkOrderRec.GET(WorkOrderRec."Document Type"::"Work Order", AppEntry."Document No.") THEN BEGIN
                        DocumentType := 'Work Order';
                        DocumentNo := WorkOrderRec."Premise/Facility No.";
                        ClientNo := WorkOrderRec."Client No.";
                        IF Customer.GET(ClientNo) THEN
                            ClientName := Customer.Name;
                    END;
                END;
        END;

        CASE TextNo OF
            '1':
                Body := STRSUBSTNO(Text002, DocumentType);
            '2':
                Body := STRSUBSTNO(Body, DocumentNo);
            '3':
                CASE CalledFrom OF
                    CalledFrom::Approve:
                        Body := STRSUBSTNO(Body, Text010);
                    CalledFrom::Cancel:
                        Body := STRSUBSTNO(Body, Text011);
                    CalledFrom::Reject:
                        Body := STRSUBSTNO(Body, Text012);
                    CalledFrom::Delegate:
                        Body := STRSUBSTNO(Body, Text013);
                END;
            '4':
                CASE CalledFrom OF
                    CalledFrom::Approve:
                        Body := STRSUBSTNO(Body, Text014);
                    CalledFrom::Cancel:
                        Body := STRSUBSTNO(Body, Text015);
                    CalledFrom::Reject:
                        Body := STRSUBSTNO(Body, Text016);
                    CalledFrom::Delegate:
                        Body := STRSUBSTNO(Body, Text017);
                END;
            '5':
                Body := STRSUBSTNO(Body, CONTEXTURL + '&target=Form 658');
            '6':
                Body := STRSUBSTNO(Body, APPLICATIONPATH);
            '7':
                Body := STRSUBSTNO(Body, AppEntry.FIELDCAPTION(Amount));
            '8':
                Body := STRSUBSTNO(Body, AppEntry."Currency Code");
            '9':
                Body := STRSUBSTNO(Body, AppEntry.Amount);
            '10':
                Body := STRSUBSTNO(Body, AppEntry.FIELDCAPTION("Amount (LCY)"));
            '11':
                Body := STRSUBSTNO(Body, AppEntry."Amount (LCY)");
            '12':
                Body := STRSUBSTNO(Body, Text018);
            '13':
                Body := STRSUBSTNO(Body, ClientNo);
            '14':
                Body := STRSUBSTNO(Body, ClientName);
            '15':
                Body := STRSUBSTNO(Body, AppEntry.FIELDCAPTION("Due Date"));
            '16':
                Body := STRSUBSTNO(Body, AppEntry."Due Date");
            '17':
                BEGIN
                    IF AppEntry."Limit Type" = AppEntry."Limit Type"::"Request Limits" THEN
                        Body := Text019
                    ELSE
                        Body := ' ';
                END;
            '18':
                BEGIN
                    IF AppEntry."Limit Type" = AppEntry."Limit Type"::"Request Limits" THEN
                        Body := STRSUBSTNO(Body, AppEntry."Amount (LCY)")
                    ELSE
                        Body := ' ';
                END;
        END;
    end;

    procedure SendCancellationsMail(ApprovalEntry: Record "Approval Entry")
    begin
        IF ApprovalRecordExist(ApprovalEntry) THEN BEGIN
            IF MailCreated THEN BEGIN
                GetEmailAddress(ApprovalEntry);
                IF Recipient <> SenderAddress THEN
                    SMTP.AddCC(Recipient);
            END ELSE BEGIN
                SetTemplate(ApprovalEntry);
                Subject := STRSUBSTNO(Text021, Text022);
                Body := Text023;

                SMTP.CreateMessage(SenderName, FromUser, SenderAddress, Subject, Body, TRUE);
                IF Recipient <> SenderAddress THEN
                    SMTP.AddCC(Recipient);
                Body := '';

                WHILE InStreamTemplate.READ(InSReadChar, 1) <> 0 DO BEGIN
                    IF InSReadChar = '%' THEN BEGIN
                        SMTP.AppendBody(Body);
                        Body := InSReadChar;
                        IF InStreamTemplate.READ(InSReadChar, 1) <> 0 THEN;
                        IF (InSReadChar >= '0') AND (InSReadChar <= '9') THEN BEGIN
                            Body := Body + '1';
                            CharNo := InSReadChar;
                            WHILE (InSReadChar >= '0') AND (InSReadChar <= '9') DO BEGIN
                                IF InStreamTemplate.READ(InSReadChar, 1) <> 0 THEN;
                                IF (InSReadChar >= '0') AND (InSReadChar <= '9') THEN
                                    CharNo := CharNo + InSReadChar;
                            END;
                        END ELSE
                            Body := Body + InSReadChar;
                        FillTemplate(Body, CharNo, ApprovalEntry, 1);
                        SMTP.AppendBody(Body);
                        Body := InSReadChar;
                    END ELSE BEGIN
                        Body := Body + InSReadChar;
                        I := I + 1;
                        IF I = 500 THEN BEGIN
                            SMTP.AppendBody(Body);
                            Body := '';
                            I := 0;
                        END;
                    END;
                END;
                SMTP.AppendBody(Body);
                TemplateFile.CLOSE;
                MailCreated := TRUE;
            END;

            IF MailCreated THEN
                SMTP.Send;
        END;
    end;

    procedure SendRejectionsMail(ApprovalEntry: Record "Approval Entry")
    var
        AppCommentLine: Record "Approval Comment Line";
    begin
        IF ApprovalRecordExist(ApprovalEntry) THEN BEGIN
            IF MailCreated THEN BEGIN
                GetEmailAddress(ApprovalEntry);
                IF Recipient <> SenderAddress THEN
                    SMTP.AddCC(Recipient);
            END ELSE BEGIN
                SetTemplate(ApprovalEntry);
                Subject := STRSUBSTNO(Text021, Text024);
                Body := Text023;

                SMTP.CreateMessage(SenderName, FromUser, SenderAddress, Subject, Body, TRUE);
                SMTP.AddCC(Recipient);
                Body := '';

                WHILE InStreamTemplate.READ(InSReadChar, 1) <> 0 DO BEGIN
                    IF InSReadChar = '%' THEN BEGIN
                        SMTP.AppendBody(Body);
                        Body := InSReadChar;
                        IF InStreamTemplate.READ(InSReadChar, 1) <> 0 THEN;
                        IF (InSReadChar >= '0') AND (InSReadChar <= '9') THEN BEGIN
                            Body := Body + '1';
                            CharNo := InSReadChar;
                            WHILE (InSReadChar >= '0') AND (InSReadChar <= '9') DO BEGIN
                                IF InStreamTemplate.READ(InSReadChar, 1) <> 0 THEN;
                                IF (InSReadChar >= '0') AND (InSReadChar <= '9') THEN
                                    CharNo := CharNo + InSReadChar;
                            END;
                        END ELSE
                            Body := Body + InSReadChar;
                        FillTemplate(Body, CharNo, ApprovalEntry, 2);
                        SMTP.AppendBody(Body);
                        Body := InSReadChar;
                    END ELSE BEGIN
                        Body := Body + InSReadChar;
                        I := I + 1;
                        IF I = 500 THEN BEGIN
                            SMTP.AppendBody(Body);
                            Body := '';
                            I := 0;
                        END;
                    END;
                END;
                SMTP.AppendBody(Body);

                //Append Comment Lines
                ApprovalEntry.CALCFIELDS(Comment);
                IF ApprovalEntry.Comment THEN BEGIN
                    AppCommentLine.SETCURRENTKEY("Table ID", "Document Type", "Document No.");
                    AppCommentLine.SETRANGE("Table ID", ApprovalEntry."Table ID");
                    CASE ApprovalEntry."Table ID" OF
                        DATABASE::"Agreement Header":
                            BEGIN
                                IF ApprovalEntry."Document Type" = ApprovalEntry."Document Type"::Sale THEN
                                    AppCommentLine.SETRANGE("Document Type", AppCommentLine."Document Type"::Sale)
                                ELSE
                                    IF ApprovalEntry."Document Type" = ApprovalEntry."Document Type"::Lease THEN
                                        AppCommentLine.SETRANGE("Document Type", AppCommentLine."Document Type"::Lease);
                            END;
                        DATABASE::"Work Order Header":
                            AppCommentLine.SETRANGE("Document Type", AppCommentLine."Document Type"::"Work Order");
                    END;
                    AppCommentLine.SETRANGE("Document No.", ApprovalEntry."Document No.");
                    IF AppCommentLine.FINDFIRST THEN BEGIN
                        Body := STRSUBSTNO('<p class="MsoNormal"><font face="Arial size 2"><b>%1</b></font></p>',
                            Text025);
                        SMTP.AppendBody(Body);
                        REPEAT
                            BuildCommentLine(AppCommentLine);
                        UNTIL AppCommentLine.NEXT = 0;
                    END;
                END;
                TemplateFile.CLOSE;
                MailCreated := TRUE;
            END;

            IF MailCreated THEN
                SMTP.Send;
        END;
    end;

    procedure SendDelegationsMail(ApprovalEntry: Record "Approval Entry")
    begin
        IF ApprovalRecordExist(ApprovalEntry) THEN BEGIN
            SetTemplate(ApprovalEntry);
            Subject := STRSUBSTNO(Text021, Text026);
            Body := Text023;

            SMTP.CreateMessage(SenderName, FromUser, Recipient, Subject, Body, TRUE);
            SMTP.AddCC(SenderAddress);
            Body := '';

            WHILE InStreamTemplate.READ(InSReadChar, 1) <> 0 DO BEGIN
                IF InSReadChar = '%' THEN BEGIN
                    SMTP.AppendBody(Body);
                    Body := InSReadChar;
                    IF InStreamTemplate.READ(InSReadChar, 1) <> 0 THEN;
                    IF (InSReadChar >= '0') AND (InSReadChar <= '9') THEN BEGIN
                        Body := Body + '1';
                        CharNo := InSReadChar;
                        WHILE (InSReadChar >= '0') AND (InSReadChar <= '9') DO BEGIN
                            IF InStreamTemplate.READ(InSReadChar, 1) <> 0 THEN;
                            IF (InSReadChar >= '0') AND (InSReadChar <= '9') THEN
                                CharNo := CharNo + InSReadChar;
                        END;
                    END ELSE
                        Body := Body + InSReadChar;
                    FillTemplate(Body, CharNo, ApprovalEntry, 3);
                    SMTP.AppendBody(Body);
                    Body := InSReadChar;
                END ELSE BEGIN
                    Body := Body + InSReadChar;
                    I := I + 1;
                    IF I = 500 THEN BEGIN
                        SMTP.AppendBody(Body);
                        Body := '';
                        I := 0;
                    END;
                END;
            END;
            SMTP.AppendBody(Body);
            SMTP.Send;
            TemplateFile.CLOSE;
        END;
    end;

    procedure ApproveApprovalRequest(ApprovalEntry: Record "Approval Entry"): Boolean
    var
        ApprovalSetup: Record "Approval Setup";
        NextApprovalEntry: Record "Approval Entry";
        ApprovalMgtNotification: Codeunit "440";
        AgreementHeader: Record "Agreement Header";
        WorkOrderHeader: Record "Work Order Header";
    begin
        IF ApprovalEntry."Table ID" <> 0 THEN BEGIN
            ApprovalEntry.Status := ApprovalEntry.Status::Approved;
            ApprovalEntry."Last Date-Time Modified" := CREATEDATETIME(TODAY, TIME);
            ApprovalEntry."Last Modified By ID" := USERID;
            ApprovalEntry.MODIFY;
            NextApprovalEntry.SETCURRENTKEY("Table ID", "Document Type", "Document No.");
            NextApprovalEntry.SETRANGE("Table ID", ApprovalEntry."Table ID");
            NextApprovalEntry.SETRANGE("Document Type", ApprovalEntry."Document Type");
            NextApprovalEntry.SETRANGE("Document No.", ApprovalEntry."Document No.");
            NextApprovalEntry.SETFILTER(Status, '%1|%2', NextApprovalEntry.Status::Created, NextApprovalEntry.Status::Open);
            IF NextApprovalEntry.FINDFIRST THEN BEGIN
                IF NextApprovalEntry.Status = NextApprovalEntry.Status::Open THEN
                    EXIT(FALSE)
                ELSE BEGIN
                    NextApprovalEntry.Status := NextApprovalEntry.Status::Open;
                    NextApprovalEntry."Date-Time Sent for Approval" := CREATEDATETIME(TODAY, TIME);
                    NextApprovalEntry."Last Date-Time Modified" := CREATEDATETIME(TODAY, TIME);
                    NextApprovalEntry."Last Modified By ID" := USERID;
                    NextApprovalEntry.MODIFY;
                    IF ApprovalSetup.GET THEN
                        IF ApprovalSetup.Approvals THEN
                            SendApprovalsMail(NextApprovalEntry);
                    EXIT(FALSE);
                END;
            END ELSE BEGIN
                IF ApprovalEntry."Table ID" = DATABASE::"Agreement Header" THEN BEGIN
                    IF ApprovalEntry."Document Type" = ApprovalEntry."Document Type"::Lease THEN BEGIN
                        IF AgreementHeader.GET(AgreementHeader."Agreement Type"::Lease, ApprovalEntry."Document No.") THEN
                            UpdateAgreementApprovalStatus(AgreementHeader);
                    END ELSE
                        IF ApprovalEntry."Document Type" = ApprovalEntry."Document Type"::Sale THEN BEGIN
                            IF AgreementHeader.GET(AgreementHeader."Agreement Type"::Sale, ApprovalEntry."Document No.") THEN
                                UpdateAgreementApprovalStatus(AgreementHeader);
                        END;
                END ELSE
                    IF ApprovalEntry."Table ID" = DATABASE::"Work Order Header" THEN BEGIN
                        IF WorkOrderHeader.GET(WorkOrderHeader."Document Type"::"Work Order", ApprovalEntry."Document No.") THEN
                            UpdateWOApprovalStatus(WorkOrderHeader);
                    END;
                EXIT(TRUE);
            END;
        END;
    end;

    procedure GetEmailAddress(AppEntry: Record "Approval Entry")
    var
        UserSetupRec: Record "91";
    begin
        UserSetupRec.GET(AppEntry."Sender ID");
        UserSetupRec.TESTFIELD("E-Mail");
        SenderAddress := UserSetupRec."E-Mail";
        UserSetupRec.GET(AppEntry."Approver ID");
        UserSetupRec.TESTFIELD("E-Mail");
        Recipient := UserSetupRec."E-Mail";
        UserSetupRec.GET(USERID);
        UserSetupRec.TESTFIELD("E-Mail");
        FromUser := UserSetupRec."E-Mail";
    end;

    procedure SetTemplate(AppEntry: Record "Approval Entry")
    var
        AppSetup: Record "Approval Setup";
        TempPath: Text[1000];
    begin
        AppSetup.GET;
        AppSetup.CALCFIELDS("Approval Template");
        IF NOT AppSetup."Approval Template".HASVALUE THEN
            ERROR(Text020)
        ELSE BEGIN
            TempPath := TEMPORARYPATH + 'AppTemplate.HTM';
            AppSetup."Approval Template".EXPORT(TempPath, FALSE);
        END;
        TemplateFile.TEXTMODE(TRUE);
        TemplateFile.OPEN(TempPath);
        TemplateFile.CREATEINSTREAM(InStreamTemplate);
        SenderName := COMPANYNAME;
        CLEAR(SenderAddress);
        CLEAR(Recipient);
        GetEmailAddress(AppEntry);
    end;

    procedure UpdateAgreementApprovalStatus(AgreementHeader: Record "Agreement Header")
    var
        AgreementRec: Record "Agreement Header";
    begin
        AgreementHeader.TESTFIELD("Agreement Status", AgreementHeader."Agreement Status"::New);
        IF AgreementHeader."Approval Status" <> AgreementHeader."Approval Status"::Released THEN BEGIN
            IF AgreementRec.GET(AgreementHeader."Agreement Type", AgreementHeader."No.") THEN BEGIN
                AgreementRec.VALIDATE("Approval Status", AgreementRec."Approval Status"::Released);
                AgreementRec.MODIFY;
            END;
        END;
    end;

    procedure UpdateWOApprovalStatus(WorkOrderHeader: Record "Work Order Header")
    begin
        IF WorkOrderHeader."Approval Status" <> WorkOrderHeader."Approval Status"::Released THEN BEGIN
            WorkOrderHeader.VALIDATE("Approval Status", WorkOrderHeader."Approval Status"::Released);
            WorkOrderHeader.MODIFY(TRUE);
        END;
    end;

    procedure BuildCommentLine(Comments: Record "Approval Comment Line")
    var
        CommentLine: Text[500];
    begin
        CommentLine := '<p class="MsoNormal"><span style="font-family:Arial size 2">' +
          Comments.Comment + '</span></p>';
        SMTP.AppendBody(CommentLine);
    end;

    procedure PerformManualAgreementReopen(var AgreementHeader: Record "Agreement Header")
    var
        ApprovalManagement: Codeunit "439";
    begin
        WITH AgreementHeader DO BEGIN
            IF CheckAgreementApprovalTemplate(AgreementHeader) THEN BEGIN
                CASE "Approval Status" OF
                    "Approval Status"::"Pending Approval":
                        ERROR(Text027);
                    "Approval Status"::Open, "Approval Status"::Released:
                        AgreementReopen(AgreementHeader);
                END;
            END ELSE
                AgreementReopen(AgreementHeader);
        END;
    end;

    procedure PerformManualWOReopen(var WorkOrderHeader: Record "Work Order Header")
    var
        ApprovalManagement: Codeunit "439";
    begin
        WITH WorkOrderHeader DO BEGIN
            WorkOrderHeader.TESTFIELD("WO Status", WorkOrderHeader."WO Status"::New);
            IF CheckWOApprovalTemplate(WorkOrderHeader) THEN BEGIN
                CASE "Approval Status" OF
                    "Approval Status"::"Pending Approval":
                        ERROR(Text027);
                    "Approval Status"::Open, "Approval Status"::Released:
                        WOReopen(WorkOrderHeader);
                END;
            END ELSE
                WOReopen(WorkOrderHeader);
        END;
    end;

    procedure AgreementReopen(var AgreementHeader: Record "Agreement Header")
    begin
        IF AgreementHeader."Approval Status" <> AgreementHeader."Approval Status"::Open THEN BEGIN
            AgreementHeader.VALIDATE("Approval Status", AgreementHeader."Approval Status"::Open);
            AgreementHeader.MODIFY;
        END;
    end;

    procedure WOReopen(var WorkOrderHeader: Record "Work Order Header")
    begin
        IF WorkOrderHeader."Approval Status" <> WorkOrderHeader."Approval Status"::Open THEN BEGIN
            WorkOrderHeader."Approval Status" := WorkOrderHeader."Approval Status"::Open;
            WorkOrderHeader.MODIFY;
        END;
    end;

    procedure CancelAgreementApprovalRequest(var AgreementHeader: Record "Agreement Header"; ShowMessage: Boolean; ManualCancel: Boolean): Boolean
    var
        ApprovalEntry: Record "Approval Entry";
        ApprovalSetup: Record "Approval Setup";
        AppManagement: Codeunit "440";
        SendMail: Boolean;
    begin
        TestSetup;
        AgreementHeader.TESTFIELD("Agreement Status", AgreementHeader."Agreement Status"::New);
        IF AgreementHeader."Approval Status" <> AgreementHeader."Approval Status"::Open THEN
            WITH AgreementHeader DO BEGIN
                ApprovalEntry.RESET;
                ApprovalEntry.SETCURRENTKEY("Table ID", "Document Type", "Document No.", "Sequence No.");
                ApprovalEntry.SETRANGE("Table ID", DATABASE::"Agreement Header");
                CASE AgreementHeader."Agreement Type" OF
                    AgreementHeader."Agreement Type"::Lease:
                        ApprovalEntry.SETRANGE("Document Type", ApprovalEntry."Document Type"::Lease);
                    AgreementHeader."Agreement Type"::Sale:
                        ApprovalEntry.SETRANGE("Document Type", ApprovalEntry."Document Type"::Sale);
                END;
                ApprovalEntry.SETRANGE("Document No.", "No.");
                ApprovalEntry.SETFILTER(Status, '<>%1&<>%2', ApprovalEntry.Status::Rejected, ApprovalEntry.Status::Canceled);
                SendMail := FALSE;
                IF ApprovalEntry.FINDFIRST THEN
                    REPEAT
                        IF (ApprovalEntry.Status = ApprovalEntry.Status::Open) OR
                           (ApprovalEntry.Status = ApprovalEntry.Status::Approved) THEN
                            SendMail := TRUE;
                        ApprovalEntry.Status := ApprovalEntry.Status::Canceled;
                        ApprovalEntry."Last Date-Time Modified" := CREATEDATETIME(TODAY, TIME);
                        ApprovalEntry."Last Modified By ID" := USERID;
                        ApprovalEntry.MODIFY;
                        IF ApprovalSetup.Cancellations AND ShowMessage AND SendMail THEN BEGIN
                            SendCancellationsMail(ApprovalEntry);
                            SendMail := FALSE;
                        END;
                    UNTIL ApprovalEntry.NEXT = 0;

                IF ManualCancel OR (NOT ManualCancel AND NOT ("Approval Status" = "Approval Status"::Released)) THEN
                    "Approval Status" := "Approval Status"::Open;
                MODIFY;
                IF ShowMessage THEN
                    MESSAGE(Text028, AgreementHeader."Agreement Type", AgreementHeader."No.");
            END;
    end;

    procedure CancelWOApprovalRequest(var WorkOrderHeader: Record "Work Order Header"; ShowMessage: Boolean; ManualCancel: Boolean): Boolean
    var
        ApprovalEntry: Record "Approval Entry";
        ApprovalSetup: Record "Approval Setup";
        AppManagement: Codeunit "440";
        SendMail: Boolean;
    begin
        TestSetup;
        WorkOrderHeader.TESTFIELD("WO Status", WorkOrderHeader."WO Status"::New);
        IF WorkOrderHeader."Approval Status" <> WorkOrderHeader."Approval Status"::Open THEN
            WITH WorkOrderHeader DO BEGIN
                ApprovalEntry.RESET;
                ApprovalEntry.SETCURRENTKEY("Table ID", "Document Type", "Document No.", "Sequence No.");
                ApprovalEntry.SETRANGE("Table ID", DATABASE::"Work Order Header");
                ApprovalEntry.SETRANGE("Document Type", ApprovalEntry."Document Type"::"Work Order");
                ApprovalEntry.SETRANGE("Document No.", "Premise/Facility No.");
                ApprovalEntry.SETFILTER(Status, '<>%1&<>%2', ApprovalEntry.Status::Rejected, ApprovalEntry.Status::Canceled);
                SendMail := FALSE;
                IF ApprovalEntry.FINDFIRST THEN
                    REPEAT
                        IF (ApprovalEntry.Status = ApprovalEntry.Status::Open) OR
                           (ApprovalEntry.Status = ApprovalEntry.Status::Approved) THEN
                            SendMail := TRUE;
                        ApprovalEntry.Status := ApprovalEntry.Status::Canceled;
                        ApprovalEntry."Last Date-Time Modified" := CREATEDATETIME(TODAY, TIME);
                        ApprovalEntry."Last Modified By ID" := USERID;
                        ApprovalEntry.MODIFY;
                        IF ApprovalSetup.Cancellations AND ShowMessage AND SendMail THEN BEGIN
                            SendCancellationsMail(ApprovalEntry);
                            SendMail := FALSE;
                        END;
                    UNTIL ApprovalEntry.NEXT = 0;

                IF ManualCancel OR (NOT ManualCancel AND NOT ("Approval Status" = "Approval Status"::Released)) THEN
                    "Approval Status" := "Approval Status"::Open;
                MODIFY;
                IF ShowMessage THEN
                    MESSAGE(Text028, WorkOrderHeader."Document Type", WorkOrderHeader."No.");
            END;
    end;

    procedure DelegateApprovalRequest(ApprovalEntry: Record "Approval Entry")
    var
        UserSetup: Record "User Setup";
        ApprovalSetup: Record "Approval Setup";
        AppManagement: Codeunit "440";
        AgreementHeader: Record "Agreement Header";
    begin
        TestSetup;
        UserSetup.SETRANGE("User ID", ApprovalEntry."Approver ID");
        IF NOT UserSetup.FINDFIRST THEN
            ERROR(Text008, ApprovalEntry."Approver ID");
        IF UserSetup.Substitute <> '' THEN BEGIN
            UserSetup.SETRANGE("User ID", UserSetup.Substitute);
            IF UserSetup.FINDFIRST THEN BEGIN
                ApprovalEntry."Last Modified By ID" := USERID;
                ApprovalEntry."Last Date-Time Modified" := CREATEDATETIME(TODAY, TIME);
                ApprovalEntry."Approver ID" := UserSetup."User ID";
                ApprovalEntry.MODIFY;
                IF ApprovalSetup.Delegations THEN
                    SendDelegationsMail(ApprovalEntry);
            END;
        END ELSE
            ERROR(Text030, UserSetup.FIELDCAPTION(Substitute), UserSetup."User ID");
    end;

    procedure ShowDocument(ApprovalEntryRec: Record "Approval Entry")
    var
        AgreementHeader: Record "Agreement Header";
        WorkOrderHeader: Record "Work Order Header";
    begin
        WITH ApprovalEntryRec DO BEGIN
            IF "Table ID" = DATABASE::"Agreement Header" THEN BEGIN
                AgreementHeader.RESET;
                AgreementHeader.SETRANGE("No.", "Document No.");
                IF AgreementHeader.FINDSET THEN
                    FORM.RUN(FORM::Agreement, AgreementHeader);
            END ELSE
                IF "Table ID" = DATABASE::"Work Order Header" THEN BEGIN
                    IF WorkOrderHeader.GET(WorkOrderHeader."Document Type"::"Work Order", "Document No.") THEN
                        FORM.RUN(FORM::"Work Order Card", WorkOrderHeader);
                END;
        END;
    end;

    procedure RejectApprovalRequest(ApprovalEntry: Record "Approval Entry")
    var
        AgreementHeader: Record "Agreement Header";
        WorkOrderHeader: Record "Work Order Header";
    begin
        CASE ApprovalEntry."Table ID" OF
            DATABASE::"Agreement Header":
                BEGIN
                    IF ApprovalEntry."Document Type" = ApprovalEntry."Document Type"::Sale THEN BEGIN
                        IF AgreementHeader.GET(AgreementHeader."Agreement Type"::Sale, ApprovalEntry."Document No.") THEN BEGIN
                            ProcessRejectApprovalRequest(ApprovalEntry);
                            AgreementReopen(AgreementHeader);
                        END;
                    END ELSE
                        IF ApprovalEntry."Document Type" = ApprovalEntry."Document Type"::Lease THEN BEGIN
                            IF AgreementHeader.GET(AgreementHeader."Agreement Type"::Lease, ApprovalEntry."Document No.") THEN BEGIN
                                ProcessRejectApprovalRequest(ApprovalEntry);
                                AgreementReopen(AgreementHeader);
                            END;
                        END;
                END;
            DATABASE::"Work Order Header":
                BEGIN
                    IF WorkOrderHeader.GET(WorkOrderHeader."Document Type"::"Work Order", ApprovalEntry."Document No.") THEN BEGIN
                        ProcessRejectApprovalRequest(ApprovalEntry);
                        WOReopen(WorkOrderHeader);
                    END;
                END;
        END;
    end;

    procedure ProcessRejectApprovalRequest(var ApprovalEntry: Record "Approval Entry")
    var
        AppManagement: Codeunit "440";
        SendMail: Boolean;
    begin
        TestSetup;
        ApprovalEntry.Status := ApprovalEntry.Status::Rejected;
        ApprovalEntry."Last Date-Time Modified" := CREATEDATETIME(TODAY, TIME);
        ApprovalEntry."Last Modified By ID" := USERID;
        ApprovalEntry.MODIFY;
        IF ApprovalSetup.Rejections THEN
            SendRejectionsMail(ApprovalEntry);
        ApprovalEntry.SETCURRENTKEY("Table ID", "Document Type", "Document No.", "Sequence No.");
        ApprovalEntry.SETRANGE("Table ID", ApprovalEntry."Table ID");
        ApprovalEntry.SETRANGE("Document Type", ApprovalEntry."Document Type");
        ApprovalEntry.SETRANGE("Document No.", ApprovalEntry."Document No.");
        ApprovalEntry.SETFILTER(Status, '<>%1&<>%2', ApprovalEntry.Status::Canceled, ApprovalEntry.Status::Rejected);
        IF ApprovalEntry.FINDFIRST THEN
            REPEAT
                SendMail := FALSE;
                IF (ApprovalEntry.Status = ApprovalEntry.Status::Open) OR
                   (ApprovalEntry.Status = ApprovalEntry.Status::Approved) THEN
                    SendMail := TRUE;

                ApprovalEntry.Status := ApprovalEntry.Status::Rejected;
                ApprovalEntry."Last Date-Time Modified" := CREATEDATETIME(TODAY, TIME);
                ApprovalEntry."Last Modified By ID" := USERID;
                ApprovalEntry.MODIFY;
                IF ApprovalSetup.Rejections AND SendMail THEN
                    SendRejectionsMail(ApprovalEntry);
            UNTIL ApprovalEntry.NEXT = 0;
    end;

    procedure ApprovalRecordExist(AppEntry: Record "Approval Entry"): Boolean
    var
        WorkOrderRec: Record "Work Order Header";
        AgreementRec: Record "Agreement Header";
    begin
        CASE AppEntry."Table ID" OF
            DATABASE::"Agreement Header":
                BEGIN
                    IF AppEntry."Document Type" = AppEntry."Document Type"::Sale THEN BEGIN
                        IF AgreementRec.GET(AgreementRec."Agreement Type"::Sale, AppEntry."Document No.") THEN
                            EXIT(TRUE)
                        ELSE
                            EXIT(FALSE);
                    END ELSE
                        IF AppEntry."Document Type" = AppEntry."Document Type"::Lease THEN BEGIN
                            IF AgreementRec.GET(AgreementRec."Agreement Type"::Lease, AppEntry."Document No.") THEN
                                EXIT(TRUE)
                            ELSE
                                EXIT(FALSE);
                        END;
                END;
            DATABASE::"Work Order Header":
                BEGIN
                    IF WorkOrderRec.GET(WorkOrderRec."Document Type"::"Work Order", AppEntry."Document No.") THEN
                        EXIT(TRUE)
                    ELSE
                        EXIT(FALSE);
                END;
        END;
        EXIT(FALSE);
    end;

    procedure ValidateAgreementDetails(AgreementRec: Record "Agreement Header")
    var
        AgreementLine: Record "Agreement Line";
    begin
        AgreementLine.RESET;
        AgreementLine.SETRANGE("Agreement Type", AgreementRec."Agreement Type");
        AgreementLine.SETRANGE("Agreement No.", AgreementRec."No.");
        AgreementLine.SETFILTER("Element Type", '<>%1', '');
        IF AgreementLine.FINDSET THEN
            REPEAT
                AgreementLine.TESTFIELD("Premise No.");
            //AgreementLine.TESTFIELD("Unit of Measure");
            UNTIL AgreementLine.NEXT = 0;
    end;

    procedure ValidateAgreementPaySchedule(AgreementRec: Record "Agreement Header")
    var
        PaymentScheduleRec: Record "Payment Schedule Lines";
    begin
        PaymentScheduleRec.RESET;
        PaymentScheduleRec.SETRANGE("Agreement Type", AgreementRec."Agreement Type");
        PaymentScheduleRec.SETRANGE("Agreement No.", AgreementRec."No.");
        PaymentScheduleRec.SETFILTER("Agreement Line No.", '>%1', 0);
        PaymentScheduleRec.SETFILTER("Payment Term Code", '<>%1', '');
        PaymentScheduleRec.SETFILTER("Element Type", '<>%1', '');
        IF NOT PaymentScheduleRec.FINDFIRST THEN
            ERROR(Text031, AgreementRec."Agreement Type", AgreementRec."No.");
    end;
}

