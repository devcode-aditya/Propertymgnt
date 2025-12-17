codeunit 33016800 "Work Order Management"
{
    // DP6.01.02 08APR2013 Code modify for validate of USERID(For windows login error)
    // DP6.01.03 16JUN2013 Code Added to update Balance Amount on Renewal of Agreement
    // DVS01012014 010114 Code modified for renewed agreement


    trigger OnRun()
    begin
    end;

    var
        PremiseMgtSetup: Record "Premise Management Setup";
        NoSeriesMgt: Codeunit "396";
        Text001: Label 'Call Register %1 has been successfully converted to Work Order %2';
        Text002: Label 'Do you want to convert Call Register %1 into Work Order?';
        Text003: Label 'Field Selection should be set to True in Work Order Line for Work Order %1';
        Text004: Label 'No Work Order Lines does exists for Work Order %1';
        Text005: Label 'All Lines of Work Order %1 have already been converted into Purchase Document.';
        GLSetup: Record "General Ledger Setup";
        Text006: Label '%1 Purchase Document successfully created from Work Order %2';
        Text007: Label '%1 Sales Document successfully created from Work Order %2';
        Text008: Label 'All Lines of Work Order %1 have already been converted into Sales Document.';
        Text009: Label 'Do you want to create Work Order from Event %1?';
        Text010: Label 'Work Order %1 successfully created from Event %2';
        Text011: Label 'Renewed Agreement %1  successfully created from Agreement %2';
        Text012: Label 'Agreement Status in Agreement %1 is already Closed';
        Text013: Label 'Agreement Status in Agreement %1 is already Cancelled';
        Text014: Label 'No Client/Tenant selected for the New Agreement.';
        Text015: Label 'No Task Code defined for Event %1';
        Text016: Label 'Field Selection should be set to True in Work Order Line for Work Order %1 having Converted Sales. Doc No. equal to ''''';
        Text017: Label 'Unposted Agreement Invoice exists for Agreement No. %1. These unposted Invoice will also transfer.Do you want to continue?';
        Text018: Label 'Agreement No. %1 transferred successfully to Agreement No. %2';
        Text019: Label 'Sales Invoice %1 %2 successfully created.';
        Text020: Label 'Event %1 is not linked with any Premise';

    procedure MakeWorkOrder(CallRegisterRec: Record "Call Register")
    var
        WorkOrderRec: Record "Work Order Header";
        WorkOrderComment: Record "Premise Comment";
        CallRegisterComment: Record "Premise Comment";
        PremiseRec: Record Premise;
    begin
        CallRegisterRec.TESTFIELD(Converted, FALSE);
        PremiseMgtSetup.GET;
        PremiseMgtSetup.TESTFIELD("Work Order");
        CLEAR(NoSeriesMgt);
        IF CallRegisterRec."Request From Type" = CallRegisterRec."Request From Type"::Premise THEN BEGIN
            IF PremiseRec.GET(CallRegisterRec."Premise/Facility No.") THEN
                PremiseRec.TESTFIELD(PremiseRec.Blocked, FALSE);
        END;
        IF CONFIRM(Text002, FALSE, CallRegisterRec."No.") THEN
            WITH WorkOrderRec DO BEGIN
                INIT;
                VALIDATE("Document Type", "Document Type"::"Work Order");
                IF NOT PremiseMgtSetup."Same No. Series" THEN
                    "No." := NoSeriesMgt.GetNextNo(PremiseMgtSetup."Work Order", WORKDATE, TRUE)
                ELSE
                    "No." := CallRegisterRec."No.";
                INSERT(TRUE);
                VALIDATE("Request From", CallRegisterRec."Request From Type");
                VALIDATE("Premise/Facility No.", CallRegisterRec."Premise/Facility No.");
                VALIDATE("Premise/Sub Premise", CallRegisterRec."Premise/Sub-Premise");
                VALIDATE("Subunit No.", CallRegisterRec."Subunit Code");
                VALIDATE("Floor No.", CallRegisterRec."Floor No.");
                VALIDATE("Contact No.", CallRegisterRec.Contact);
                VALIDATE("Call Back No.", CallRegisterRec."Call Back No.");
                VALIDATE("Contact Method", CallRegisterRec."Contact Method");
                VALIDATE(Description, CallRegisterRec.Description);
                VALIDATE("Priority Code", CallRegisterRec."Priority Code");
                VALIDATE("WO Status", "WO Status"::New);
                VALIDATE("Date Created", TODAY);
                VALIDATE("Time Created", TIME);
                VALIDATE("Document Date", TODAY);
                //DP6.01.02 START
                //VALIDATE("User ID",USERID);
                "User ID" := USERID;
                //DP6.01.02 STOP
                VALIDATE(Name, CallRegisterRec.Name);
                VALIDATE(City, CallRegisterRec.City);
                VALIDATE("Subunit Description", CallRegisterRec."Subunit Description");
                VALIDATE("Contact Name", CallRegisterRec."Contact Name");
                VALIDATE("Priorty Description", CallRegisterRec."Priority Description");
                VALIDATE("Converted From", CallRegisterRec."No.");
                VALIDATE("Conversion Date Time", CREATEDATETIME(TODAY, TIME));
                VALIDATE("Client No.", CallRegisterRec."Client No.");

                VALIDATE("Shortcut Dimension 1 Code", CallRegisterRec."Shortcut Dimension 1 Code");
                VALIDATE("Shortcut Dimension 2 Code", CallRegisterRec."Shortcut Dimension 2 Code");
                MODIFY(TRUE);

                CallRegisterComment.RESET;
                CallRegisterComment.SETRANGE("Table Name", CallRegisterComment."Table Name"::"Call Register");
                CallRegisterComment.SETRANGE("No.", CallRegisterRec."No.");
                IF CallRegisterComment.FINDSET THEN
                    REPEAT
                        WorkOrderComment.TRANSFERFIELDS(CallRegisterComment);
                        WorkOrderComment."Table Name" := CallRegisterComment."Table Name"::"Work Order";
                        WorkOrderComment."No." := WorkOrderRec."No.";
                        WorkOrderComment.INSERT;
                    UNTIL CallRegisterComment.NEXT = 0;

                CallRegisterRec.VALIDATE(Converted, TRUE);
                CallRegisterRec.VALIDATE("Conversion Date Time", CREATEDATETIME(TODAY, TIME));
                CallRegisterRec.VALIDATE(Status, "WO Status"::Closed);
                CallRegisterRec.MODIFY(TRUE);
                MESSAGE(Text001, CallRegisterRec."No.", WorkOrderRec."No.");
            END;
    end;

    procedure CreatePurchaseDocument(WorkOrder: Record "Work Order Header")
    var
        PurchaseSetup: Record "Purchases & Payables Setup";
        WorkOrderLine: Record "Work Order Line";
        DocumentNo: Code[20];
        DocumentType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order";
        NoSeriesMgt: Codeunit "396";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        NextLineNo: Integer;
        TaskCodeRec: Record "Task Code";
        i: Integer;
        PremiseRec: Record Premise;
    begin
        PurchaseSetup.GET;

        IF WorkOrder."Request From" = WorkOrder."Request From"::Premise THEN BEGIN
            IF PremiseRec.GET(WorkOrder."Premise/Facility No.") THEN
                PremiseRec.TESTFIELD(PremiseRec.Blocked, FALSE);
        END;

        WorkOrderLine.RESET;
        WorkOrderLine.SETRANGE("Document Type", WorkOrder."Document Type");
        WorkOrderLine.SETRANGE("Document No.", WorkOrder."No.");
        WorkOrderLine.SETFILTER(Code, '<>%1', '');
        WorkOrderLine.SETFILTER("Converted Purch. Doc No.", '%1', '');
        IF WorkOrderLine.COUNT <> 0 THEN BEGIN
            WorkOrderLine.SETRANGE(Selection, TRUE);
            IF WorkOrderLine.FINDSET THEN BEGIN
                CLEAR(DocumentNo);
                CLEAR(DocumentType);
                CLEAR(i);
                REPEAT
                    CASE WorkOrderLine."Convert to Purch. Doc Type" OF
                        WorkOrderLine."Convert to Purch. Doc Type"::" ":
                            WorkOrderLine.FIELDERROR(WorkOrderLine."Convert to Purch. Doc Type");
                        WorkOrderLine."Convert to Purch. Doc Type"::Quote:
                            BEGIN
                                PurchaseSetup.TESTFIELD(PurchaseSetup."Quote Nos.");
                                DocumentNo := NoSeriesMgt.GetNextNo(PurchaseSetup."Quote Nos.", TODAY, TRUE);
                                DocumentType := DocumentType::Quote;
                            END;
                        WorkOrderLine."Convert to Purch. Doc Type"::Order:
                            BEGIN
                                PurchaseSetup.TESTFIELD(PurchaseSetup."Order Nos.");
                                DocumentNo := NoSeriesMgt.GetNextNo(PurchaseSetup."Order Nos.", TODAY, TRUE);
                                DocumentType := DocumentType::Order;
                            END;
                        WorkOrderLine."Convert to Purch. Doc Type"::Invoice:
                            BEGIN
                                PurchaseSetup.TESTFIELD(PurchaseSetup."Invoice Nos.");
                                DocumentNo := NoSeriesMgt.GetNextNo(PurchaseSetup."Invoice Nos.", TODAY, TRUE);
                                DocumentType := DocumentType::Invoice;
                            END;
                    END;

                    //PurchaseHeader
                    WorkOrderLine.TESTFIELD("Vendor No.");
                    PurchaseHeader.INIT;
                    PurchaseHeader.VALIDATE("Document Type", DocumentType);
                    PurchaseHeader."No." := DocumentNo;
                    PurchaseHeader.INSERT(TRUE);
                    PurchaseHeader.VALIDATE("Document Date", WorkOrder."Document Date");
                    PurchaseHeader.VALIDATE("Buy-from Vendor No.", WorkOrderLine."Vendor No.");
                    PurchaseHeader.MODIFY(TRUE);

                    i += 1;
                    UpdatePurchaseHeaderDimension(PurchaseHeader, WorkOrder);

                    //PurchaseLine
                    CLEAR(NextLineNo);
                    PurchaseLine.RESET;
                    PurchaseLine.SETRANGE("Document Type", PurchaseHeader."Document Type");
                    PurchaseLine.SETRANGE("Document No.", PurchaseHeader."No.");
                    IF PurchaseLine.FINDLAST THEN
                        NextLineNo := PurchaseLine."Line No.";
                    NextLineNo += 10000;

                    PurchaseLine.RESET;
                    PurchaseLine.INIT;
                    PurchaseLine.VALIDATE("Document Type", PurchaseHeader."Document Type");
                    PurchaseLine.VALIDATE("Document No.", PurchaseHeader."No.");
                    PurchaseLine.VALIDATE("Line No.", NextLineNo);
                    CASE WorkOrderLine.Type OF
                        WorkOrderLine.Type::Task:
                            BEGIN
                                PurchaseLine.VALIDATE(Type, PurchaseLine.Type::"G/L Account");
                                TaskCodeRec.GET(WorkOrderLine.Code);
                                PurchaseLine.VALIDATE("No.", TaskCodeRec."Expense Account");
                                PurchaseLine.VALIDATE(Quantity, WorkOrderLine.Quantity);
                                PurchaseLine.VALIDATE("Unit of Measure", WorkOrderLine."Unit of Measure Code");
                                PurchaseLine.VALIDATE("Direct Unit Cost", WorkOrderLine."Unit Cost");
                                PurchaseLine.VALIDATE(Amount, WorkOrderLine."Cost Amount");
                                PurchaseLine.VALIDATE("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
                            END;
                        WorkOrderLine.Type::"Fixed Asset":
                            BEGIN
                                PurchaseLine.VALIDATE(Type, PurchaseLine.Type::"Fixed Asset");
                                PurchaseLine.VALIDATE("No.", WorkOrderLine.Code);
                                PurchaseLine.VALIDATE(Quantity, WorkOrderLine.Quantity);
                                PurchaseLine.VALIDATE("Unit of Measure", WorkOrderLine."Unit of Measure Code");
                                PurchaseLine.VALIDATE("Direct Unit Cost", WorkOrderLine."Unit Cost");
                                PurchaseLine.VALIDATE(Amount, WorkOrderLine."Cost Amount");
                                PurchaseLine.VALIDATE("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
                            END;
                    END;
                    PurchaseLine.INSERT(TRUE);

                    UpdatePurchaseLineDimension(PurchaseLine, WorkOrderLine);
                    WorkOrderLine."Converted Purch. Doc Type" := PurchaseHeader."Document Type";
                    WorkOrderLine."Converted Purch. Doc No." := PurchaseHeader."No.";
                    WorkOrderLine."Converted Purch. Doc Line No." := PurchaseLine."Line No.";
                    WorkOrderLine."Converted Purch. Doc Datetime" := CURRENTDATETIME;
                    WorkOrderLine.MODIFY(TRUE);
                UNTIL WorkOrderLine.NEXT = 0;
                IF i <> 0 THEN
                    MESSAGE(Text006, i, WorkOrder."No.");
            END ELSE
                ERROR(Text003, WorkOrder."No.");
        END ELSE BEGIN
            WorkOrderLine.SETRANGE("Converted Purch. Doc No.");
            IF WorkOrderLine.COUNT = 0 THEN
                ERROR(Text004, WorkOrder."No.")
            ELSE
                ERROR(Text005, WorkOrder."No.")
        END;
    end;

    procedure UpdatePurchaseHeaderDimension(var PurchaseHeader: Record "Purchase Header"; WorkOrder: Record "Work Order Header")
    var
        DocumentDimension: Record "Document Dimension";
        DocDim: Record "Document Dimension";
    begin
        DocumentDimension.RESET;
        DocumentDimension.SETRANGE("Table ID", DATABASE::"Work Order Header");
        DocumentDimension.SETRANGE("Document Type", DocumentDimension."Document Type"::Quote);
        DocumentDimension.SETRANGE("Document No.", WorkOrder."No.");
        DocumentDimension.SETRANGE("Line No.", 0);
        IF DocumentDimension.FINDSET THEN BEGIN
            GLSetup.GET;
            REPEAT
                IF DocumentDimension."Dimension Code" = GLSetup."Shortcut Dimension 1 Code" THEN BEGIN
                    PurchaseHeader.VALIDATE("Shortcut Dimension 1 Code", DocumentDimension."Dimension Value Code");
                    PurchaseHeader.MODIFY;
                END ELSE
                    IF DocumentDimension."Dimension Code" = GLSetup."Shortcut Dimension 2 Code" THEN BEGIN
                        PurchaseHeader.VALIDATE("Shortcut Dimension 2 Code", DocumentDimension."Dimension Value Code");
                        PurchaseHeader.MODIFY;
                    END;

                IF DocDim.GET(DATABASE::"Purchase Header", PurchaseHeader."Document Type", PurchaseHeader."No.", 0,
                DocumentDimension."Dimension Code") THEN BEGIN
                    DocDim."Dimension Value Code" := DocumentDimension."Dimension Value Code";
                    DocDim.MODIFY;
                END ELSE BEGIN
                    DocDim.INIT;
                    DocDim."Table ID" := DATABASE::"Purchase Header";
                    DocDim."Document Type" := PurchaseHeader."Document Type";
                    DocDim."Document No." := PurchaseHeader."No.";
                    DocDim."Line No." := 0;
                    DocDim."Dimension Code" := DocumentDimension."Dimension Code";
                    DocDim."Dimension Value Code" := DocumentDimension."Dimension Value Code";
                    IF NOT DocDim.INSERT(TRUE) THEN
                        DocDim.MODIFY;
                END;
            UNTIL DocumentDimension.NEXT = 0;
        END;
    end;

    procedure UpdatePurchaseLineDimension(var PurchaseLine: Record "Purchase Line"; WorkOrderLine: Record "Work Order Line")
    var
        DocumentDimensionRec: Record "Document Dimension";
        DocDimRec: Record "Document Dimension";
    begin
        DocumentDimensionRec.RESET;
        DocumentDimensionRec.SETRANGE("Table ID", DATABASE::"Work Order Line");
        DocumentDimensionRec.SETRANGE("Document No.", WorkOrderLine."Document No.");
        DocumentDimensionRec.SETRANGE("Line No.", WorkOrderLine."Document Line No.");
        IF DocumentDimensionRec.FINDSET THEN BEGIN
            GLSetup.GET;
            REPEAT
                IF DocumentDimensionRec."Dimension Code" = GLSetup."Shortcut Dimension 1 Code" THEN BEGIN
                    PurchaseLine."Shortcut Dimension 1 Code" := DocumentDimensionRec."Dimension Value Code";
                    PurchaseLine.MODIFY;
                END ELSE
                    IF DocumentDimensionRec."Dimension Code" = GLSetup."Shortcut Dimension 2 Code" THEN BEGIN
                        PurchaseLine."Shortcut Dimension 2 Code" := DocumentDimensionRec."Dimension Value Code";
                        PurchaseLine.MODIFY;
                    END;
                DocDimRec.INIT;
                DocDimRec."Table ID" := DATABASE::"Purchase Line";
                DocDimRec."Document Type" := PurchaseLine."Document Type";
                DocDimRec."Document No." := PurchaseLine."Document No.";
                DocDimRec."Line No." := PurchaseLine."Line No.";
                DocDimRec."Dimension Code" := DocumentDimensionRec."Dimension Code";
                DocDimRec."Dimension Value Code" := DocumentDimensionRec."Dimension Value Code";
                IF NOT DocDimRec.INSERT(TRUE) THEN
                    DocDimRec.MODIFY;
            UNTIL DocumentDimensionRec.NEXT = 0;
        END;
    end;

    procedure CreateSalesDocument(WorkOrder: Record "Work Order Header")
    var
        SalesSetup: Record "Sales & Receivables Setup";
        WorkOrderLine: Record "Work Order Line";
        DocumentNo: Code[20];
        DocumentType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order";
        NoSeriesMgt: Codeunit "396";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        NextLineNo: Integer;
        TaskCodeRec: Record "Task Code";
        i: Integer;
        PremiseRec: Record Premise;
    begin
        SalesSetup.GET;

        IF WorkOrder."Request From" = WorkOrder."Request From"::Premise THEN BEGIN
            IF PremiseRec.GET(WorkOrder."Premise/Facility No.") THEN
                PremiseRec.TESTFIELD(PremiseRec.Blocked, FALSE);
        END;

        WorkOrderLine.RESET;
        WorkOrderLine.SETRANGE("Document Type", WorkOrder."Document Type");
        WorkOrderLine.SETRANGE("Document No.", WorkOrder."No.");
        WorkOrderLine.SETFILTER(Code, '<>%1', '');
        WorkOrderLine.SETFILTER("Converted Sales. Doc No.", '%1', '');
        IF NOT WorkOrderLine.FINDSET THEN BEGIN
            WorkOrderLine.SETRANGE("Converted Sales. Doc No.");
            IF WorkOrderLine.FINDFIRST THEN
                ERROR(Text008, WorkOrder."No.")
            ELSE
                ERROR(Text004, WorkOrder."No.")
        END ELSE BEGIN
            WorkOrderLine.SETRANGE(Selection, TRUE);
            IF WorkOrderLine.FINDSET THEN BEGIN
                CLEAR(DocumentNo);
                CLEAR(DocumentType);
                CLEAR(i);
                REPEAT
                    CASE WorkOrderLine."Convert to Sales Doc Type" OF
                        WorkOrderLine."Convert to Sales Doc Type"::" ":
                            WorkOrderLine.FIELDERROR(WorkOrderLine."Convert to Sales Doc Type");
                        WorkOrderLine."Convert to Sales Doc Type"::Quote:
                            BEGIN
                                SalesSetup.TESTFIELD("Quote Nos.");
                                DocumentNo := NoSeriesMgt.GetNextNo(SalesSetup."Quote Nos.", TODAY, TRUE);
                                DocumentType := DocumentType::Quote;
                            END;
                        WorkOrderLine."Convert to Sales Doc Type"::Order:
                            BEGIN
                                SalesSetup.TESTFIELD("Order Nos.");
                                DocumentNo := NoSeriesMgt.GetNextNo(SalesSetup."Order Nos.", TODAY, TRUE);
                                DocumentType := DocumentType::Order;
                            END;
                        WorkOrderLine."Convert to Sales Doc Type"::Invoice:
                            BEGIN
                                SalesSetup.TESTFIELD("Invoice Nos.");
                                DocumentNo := NoSeriesMgt.GetNextNo(SalesSetup."Invoice Nos.", TODAY, TRUE);
                                DocumentType := DocumentType::Invoice;
                            END;
                    END;

                    //SalesHeader
                    WorkOrderLine.TESTFIELD("Client No.");
                    SalesHeader.INIT;
                    SalesHeader.VALIDATE("Document Type", DocumentType);
                    SalesHeader."No." := DocumentNo;
                    SalesHeader.INSERT(TRUE);
                    SalesHeader.VALIDATE("Document Date", WorkOrder."Document Date");
                    SalesHeader.VALIDATE("Sell-to Customer No.", WorkOrderLine."Client No.");
                    SalesHeader.MODIFY(TRUE);
                    i += 1;
                    UpdateSalesHeaderDimension(SalesHeader, WorkOrder);

                    //SalesLine
                    CLEAR(NextLineNo);
                    SalesLine.RESET;
                    SalesLine.SETRANGE("Document Type", SalesHeader."Document Type");
                    SalesLine.SETRANGE("Document No.", SalesHeader."No.");
                    IF SalesLine.FINDLAST THEN
                        NextLineNo := SalesLine."Line No.";
                    NextLineNo += 10000;

                    SalesLine.RESET;
                    SalesLine.INIT;
                    SalesLine.VALIDATE("Document Type", SalesHeader."Document Type");
                    SalesLine.VALIDATE("Document No.", SalesHeader."No.");
                    SalesLine.VALIDATE("Line No.", NextLineNo);
                    CASE WorkOrderLine.Type OF
                        WorkOrderLine.Type::Task:
                            BEGIN
                                SalesLine.VALIDATE(Type, SalesLine.Type::"G/L Account");
                                TaskCodeRec.GET(WorkOrderLine.Code);
                                SalesLine.VALIDATE("No.", TaskCodeRec."Revenue Account");
                                SalesLine.VALIDATE(Quantity, 1);
                                SalesLine.VALIDATE("Unit of Measure", WorkOrderLine."Unit of Measure Code");
                                //SalesLine.VALIDATE("Unit Price",WorkOrderLine."Unit Price");
                                SalesLine.VALIDATE("Unit Price", WorkOrderLine."Sales Amount");
                                SalesLine.VALIDATE(Amount, WorkOrderLine."Sales Amount");
                                SalesLine.VALIDATE("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
                            END;
                        WorkOrderLine.Type::"Fixed Asset":
                            BEGIN
                                SalesLine.VALIDATE(Type, SalesLine.Type::"Fixed Asset");
                                SalesLine.VALIDATE("No.", WorkOrderLine.Code);
                                SalesLine.VALIDATE(Quantity, 1);
                                SalesLine.VALIDATE("Unit of Measure", WorkOrderLine."Unit of Measure Code");
                                //SalesLine.VALIDATE("Unit Price",WorkOrderLine."Unit Price");
                                SalesLine.VALIDATE("Unit Price", WorkOrderLine."Sales Amount");
                                SalesLine.VALIDATE(Amount, WorkOrderLine."Sales Amount");
                                SalesLine.VALIDATE("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
                            END;
                    END;
                    SalesLine.INSERT(TRUE);
                    UpdateSalesLineDimension(SalesLine, WorkOrderLine);
                    WorkOrderLine."Converted Sales. Doc Type" := SalesHeader."Document Type";
                    WorkOrderLine."Converted Sales. Doc No." := SalesHeader."No.";
                    WorkOrderLine."Converted Sales. Doc Line No." := SalesLine."Line No.";
                    WorkOrderLine."Converted Sales. Doc Datetime" := CURRENTDATETIME;
                    WorkOrderLine.Selection := FALSE;
                    WorkOrderLine.MODIFY(TRUE);
                UNTIL WorkOrderLine.NEXT = 0;
                IF i <> 0 THEN
                    MESSAGE(Text007, i, WorkOrder."No.");
            END ELSE
                ERROR(Text016, WorkOrder."No.");
        END;
    end;

    procedure UpdateSalesHeaderDimension(var SalesHeader: Record "Sales Header"; WorkOrder: Record "Work Order Header")
    var
        DocumentDimension: Record "Document Dimension";
        DocDim: Record "Document Dimension";
    begin
        DocumentDimension.RESET;
        DocumentDimension.SETRANGE("Table ID", DATABASE::"Work Order Header");
        DocumentDimension.SETRANGE("Document Type", DocumentDimension."Document Type"::Quote);
        DocumentDimension.SETRANGE("Document No.", WorkOrder."No.");
        DocumentDimension.SETRANGE("Line No.", 0);
        IF DocumentDimension.FINDSET THEN BEGIN
            GLSetup.GET;
            REPEAT
                IF DocumentDimension."Dimension Code" = GLSetup."Shortcut Dimension 1 Code" THEN BEGIN
                    SalesHeader.VALIDATE("Shortcut Dimension 1 Code", DocumentDimension."Dimension Value Code");
                    SalesHeader.MODIFY;
                END ELSE
                    IF DocumentDimension."Dimension Code" = GLSetup."Shortcut Dimension 2 Code" THEN BEGIN
                        SalesHeader.VALIDATE("Shortcut Dimension 2 Code", DocumentDimension."Dimension Value Code");
                        SalesHeader.MODIFY;
                    END;

                IF DocDim.GET(DATABASE::"Sales Header", SalesHeader."Document Type", SalesHeader."No.", 0,
                DocumentDimension."Dimension Code") THEN BEGIN
                    DocDim."Dimension Value Code" := DocumentDimension."Dimension Value Code";
                    DocDim.MODIFY;
                END ELSE BEGIN
                    DocDim.INIT;
                    DocDim."Table ID" := DATABASE::"Sales Header";
                    DocDim."Document Type" := SalesHeader."Document Type";
                    DocDim."Document No." := SalesHeader."No.";
                    DocDim."Line No." := 0;
                    DocDim."Dimension Code" := DocumentDimension."Dimension Code";
                    DocDim."Dimension Value Code" := DocumentDimension."Dimension Value Code";
                    IF NOT DocDim.INSERT(TRUE) THEN
                        DocDim.MODIFY;
                END;
            UNTIL DocumentDimension.NEXT = 0;
        END;
    end;

    procedure UpdateSalesLineDimension(var SalesLine: Record "Sales Line"; WorkOrderLine: Record "Work Order Line")
    var
        DocumentDimensionRec: Record "Document Dimension";
        DocDimRec: Record "Document Dimension";
    begin
        DocumentDimensionRec.RESET;
        DocumentDimensionRec.SETRANGE("Table ID", DATABASE::"Work Order Line");
        DocumentDimensionRec.SETRANGE("Document No.", WorkOrderLine."Document No.");
        DocumentDimensionRec.SETRANGE("Line No.", WorkOrderLine."Document Line No.");
        IF DocumentDimensionRec.FINDSET THEN BEGIN
            GLSetup.GET;
            REPEAT
                IF DocumentDimensionRec."Dimension Code" = GLSetup."Shortcut Dimension 1 Code" THEN BEGIN
                    SalesLine."Shortcut Dimension 1 Code" := DocumentDimensionRec."Dimension Value Code";
                    SalesLine.MODIFY;
                END ELSE
                    IF DocumentDimensionRec."Dimension Code" = GLSetup."Shortcut Dimension 2 Code" THEN BEGIN
                        SalesLine."Shortcut Dimension 2 Code" := DocumentDimensionRec."Dimension Value Code";
                        SalesLine.MODIFY;
                    END;
                DocDimRec.INIT;
                DocDimRec."Table ID" := DATABASE::"Sales Line";
                DocDimRec."Document Type" := SalesLine."Document Type";
                DocDimRec."Document No." := SalesLine."Document No.";
                DocDimRec."Line No." := SalesLine."Line No.";
                DocDimRec."Dimension Code" := DocumentDimensionRec."Dimension Code";
                DocDimRec."Dimension Value Code" := DocumentDimensionRec."Dimension Value Code";
                IF NOT DocDimRec.INSERT(TRUE) THEN
                    DocDimRec.MODIFY;
            UNTIL DocumentDimensionRec.NEXT = 0;
        END;
    end;

    procedure ReopenWorkOrder(WorkOrder: Record "Work Order Header")
    var
        WorkOrderRec: Record "Work Order Header";
    begin
        IF WorkOrderRec.GET(WorkOrder."Document Type", WorkOrder."No.") THEN BEGIN
            WorkOrderRec.TESTFIELD(WorkOrderRec."WO Status", WorkOrderRec."WO Status"::New);
            WorkOrderRec."Completion Code" := '';
            WorkOrderRec."Completion Description" := '';
            WorkOrderRec."Completion Date" := 0D;
            WorkOrderRec."Completion Time" := 0T;
            WorkOrderRec."Approval Status" := WorkOrderRec."Approval Status"::Open;
            WorkOrderRec.MODIFY;
        END;
    end;

    procedure CreateWOFromEvents(EventNo: Code[20])
    var
        WorkHeaderRec: Record "Work Order Header";
        EventRec: Record "Event Detail";
        PremiseEventRec: Record "Premise Events";
        PremiseRec: Record Premise;
        CheckFlag: Boolean;
        EventTaskRec: Record "Event Tasks";
    begin
        PremiseMgtSetup.GET;
        EventRec.GET(EventNo);

        EventTaskRec.RESET;
        EventTaskRec.SETRANGE("Event No.", EventRec."No.");
        EventTaskRec.SETFILTER("Task Code", '<>%1', '');
        IF NOT EventTaskRec.FINDFIRST THEN
            ERROR(Text015, EventRec."No.");

        IF CONFIRM(Text009, FALSE, EventRec."No.") THEN BEGIN
            PremiseMgtSetup.TESTFIELD("Work Order");
            CLEAR(NoSeriesMgt);
            CLEAR(CheckFlag);
            PremiseEventRec.RESET;
            PremiseEventRec.SETRANGE("Event Code", EventRec."No.");
            PremiseEventRec.SETFILTER("Premises Code", '<>%1', '');
            IF NOT PremiseEventRec.FINDFIRST THEN
                ERROR(Text020, EventRec."No.")
            ELSE
                PremiseRec.GET(PremiseEventRec."Premises Code");

            WITH WorkHeaderRec DO BEGIN
                INIT;
                VALIDATE("Document Type", "Document Type"::"Work Order");
                "No." := NoSeriesMgt.GetNextNo(PremiseMgtSetup."Work Order", WORKDATE, TRUE);
                INSERT(TRUE);
                VALIDATE("Request From", WorkHeaderRec."Request From"::Premise);
                VALIDATE("Premise/Facility No.", PremiseRec."No.");
                VALIDATE("Premise/Sub Premise", PremiseRec."Premise/Sub-Premise"::Premise);
                VALIDATE("Floor No.", PremiseRec."Floor No.");
                VALIDATE("Date Created", TODAY);
                VALIDATE("Time Created", TIME);
                VALIDATE("Document Date", TODAY);
                //DP6.01.02 START
                //VALIDATE("User ID",USERID);
                "User ID" := USERID;
                //DP6.01.02 STOP
                VALIDATE("WO Status", "WO Status"::New);

                VALIDATE("Shortcut Dimension 1 Code", EventRec."Global Dimension 1 Code");
                VALIDATE("Shortcut Dimension 2 Code", EventRec."Global Dimension 2 Code");
                MODIFY(TRUE);

                //WO Lines creation
                CreateWOLineFromEvents(WorkHeaderRec, EventRec);
                MESSAGE(Text010, WorkHeaderRec."No.", EventRec."No.");
            END;
        END;
    end;

    procedure CreateWOLineFromEvents(WorkHeaderRec: Record "Work Order Header"; EventRec: Record "Event Detail")
    var
        WorkLineRec: Record "Work Order Line";
        EventTask: Record "Event Tasks";
        NextLine: Integer;
        TaskCodeRec: Record "Task Code";
    begin
        EventTask.RESET;
        EventTask.SETRANGE("Event No.", EventRec."No.");
        EventTask.SETFILTER("Task Code", '<>%1', '');
        IF EventTask.FINDSET THEN BEGIN
            //WO Lines
            WorkLineRec.RESET;
            WorkLineRec.SETRANGE("Document Type", WorkHeaderRec."Document Type");
            WorkLineRec.SETRANGE("Document No.", WorkHeaderRec."No.");
            IF WorkLineRec.FINDLAST THEN
                NextLine := WorkLineRec."Document Line No.";

            REPEAT
                NextLine += 10000;
                WorkLineRec.RESET;
                WorkLineRec.INIT;
                WorkLineRec.VALIDATE("Document Type", WorkHeaderRec."Document Type");
                WorkLineRec."Document No." := WorkHeaderRec."No.";
                WorkLineRec."Document Line No." := NextLine;
                WorkLineRec.VALIDATE(Type, WorkLineRec.Type::Task);
                WorkLineRec.VALIDATE(Code, EventTask."Task Code");
                WorkLineRec.VALIDATE(Description, EventTask."Task Name");
                TaskCodeRec.GET(EventTask."Task Code");
                WorkLineRec.VALIDATE("Unit of Measure Code", TaskCodeRec."Unit of Measure");
                WorkLineRec.VALIDATE("Unit Cost", TaskCodeRec."Task Cost");
                WorkLineRec.VALIDATE("Unit Price", TaskCodeRec."Task Price");
                WorkLineRec.VALIDATE("Cost Amount", WorkLineRec."Unit Cost" * WorkLineRec.Quantity);
                WorkLineRec.VALIDATE("Sales Amount", WorkLineRec."Unit Price" * WorkLineRec.Quantity);
                WorkLineRec.VALIDATE("Event No.", EventTask."Event No.");
                WorkLineRec.VALIDATE("Document Date", WorkHeaderRec."Document Date");
                WorkLineRec.INSERT(TRUE);

                WorkLineRec.VALIDATE("Shortcut Dimension 1 Code", WorkHeaderRec."Shortcut Dimension 1 Code");
                WorkLineRec.VALIDATE("Shortcut Dimension 2 Code", WorkHeaderRec."Shortcut Dimension 2 Code");
                WorkLineRec.MODIFY(TRUE);
            UNTIL EventTask.NEXT = 0;
        END;
    end;

    procedure RenewAgreement(AgreementRec: Record "Agreement Header")
    begin
        CreateRenewedAgreement(AgreementRec);
    end;

    procedure CancelAgreement(AgreementRec: Record "Agreement Header")
    var
        AgrmtHdr: Record "Agreement Header";
    begin
        IF AgreementRec."Agreement Status" <> AgreementRec."Agreement Status"::Cancelled THEN BEGIN
            AgreementRec.VALIDATE("Agreement Status", AgreementRec."Agreement Status"::Cancelled);
            AgreementRec.Closed := TRUE;
            AgreementRec.MODIFY;
            AgrmtHdr.UpdatePremisesStatus(AgreementRec);
        END ELSE
            ERROR(Text013, AgreementRec."No.");
    end;

    procedure CreateRenewedAgreement(AgreementRec: Record "Agreement Header")
    var
        AgreementMaster: Record "Agreement Header";
        AgreementLineMaster: Record "Agreement Line";
        AgreementCode: Code[20];
        AgreementLineRec: Record "Agreement Line";
    begin
        AgreementRec.TESTFIELD("Agreement Renewed", FALSE);
        PremiseMgtSetup.GET;
        PremiseMgtSetup.TESTFIELD(Agreement);
        CLEAR(AgreementCode);

        //Agreement Header
        AgreementMaster.INIT;
        AgreementMaster.TRANSFERFIELDS(AgreementRec);
        AgreementCode := NoSeriesMgt.GetNextNo(PremiseMgtSetup.Agreement, TODAY, TRUE);
        AgreementMaster."No." := AgreementCode;
        AgreementMaster.VALIDATE("Agreement Status", AgreementMaster."Agreement Status"::New);
        AgreementMaster."Renewed Agreement" := TRUE;
        AgreementMaster.VALIDATE("Approval Status", AgreementMaster."Approval Status"::Open);
        AgreementMaster."Agreement Status" := AgreementMaster."Agreement Status"::New;
        AgreementMaster."Original Agreement No." := AgreementRec."No.";
        AgreementMaster."Original Agreement Type" := AgreementRec."Agreement Type";
        IF AgreementRec."Agreement End Date" <> 0D THEN
            AgreementMaster."Agreement Start Date" := CALCDATE('1D', AgreementRec."Agreement End Date");
        IF (FORMAT(AgreementRec."Agreement Period") <> '') AND (AgreementMaster."Agreement Start Date" <> 0D) THEN BEGIN
            AgreementMaster."Agreement End Date" := CALCDATE(AgreementRec."Agreement Period", AgreementMaster."Agreement Start Date");
            AgreementMaster."Agreement End Date" := CALCDATE('-1D', AgreementMaster."Agreement End Date");
        END;
        AgreementMaster.INSERT(TRUE);

        //AgreementRec."Agreement Renewed" := TRUE;//DVS01012014
        //AgreementRec.MODIFY;//DVS01012014
        //Header Dimensions
        UpdateRenewedAgreemenDim(AgreementRec, AgreementMaster);

        //AgreementPremiseRelation
        UpdateAgreementPremiseRelation(AgreementRec, AgreementMaster);

        //Agreement Line
        AgreementLineRec.RESET;
        AgreementLineRec.SETRANGE("Agreement Type", AgreementRec."Agreement Type");
        AgreementLineRec.SETRANGE("Agreement No.", AgreementRec."No.");
        IF AgreementLineRec.FINDSET THEN
            REPEAT
                AgreementLineMaster.INIT;
                AgreementLineMaster.TRANSFERFIELDS(AgreementLineRec);
                AgreementLineMaster."Agreement No." := AgreementCode;
                AgreementLineMaster."Start Date" := AgreementMaster."Agreement Start Date";
                AgreementLineMaster."End Date" := AgreementMaster."Agreement End Date";
                AgreementLineMaster."Balanced Amount" := AgreementLineMaster."Original Amount"; //DP6.01.03
                AgreementLineMaster.INSERT(TRUE);
                //Line Dimensions
                UpdateRenewedAgreemenLineDim(AgreementLineRec, AgreementLineMaster);
            UNTIL AgreementLineRec.NEXT = 0;

        MESSAGE(Text011, AgreementMaster."No.", AgreementRec."No.");
    end;

    procedure UpdateRenewedAgreemenDim(AgreementRec: Record "Agreement Header"; AgreementMaster: Record "Agreement Header")
    var
        DocumentDimension: Record "Document Dimension";
        DocDim: Record "Document Dimension";
    begin
        DocumentDimension.RESET;
        DocumentDimension.SETRANGE("Table ID", DATABASE::"Agreement Header");
        DocumentDimension.SETRANGE("Document Type", DocumentDimension."Document Type"::Quote);
        DocumentDimension.SETRANGE("Document No.", AgreementRec."No.");
        DocumentDimension.SETRANGE("Line No.", 0);
        IF DocumentDimension.FINDSET THEN BEGIN
            GLSetup.GET;
            REPEAT
                IF DocumentDimension."Dimension Code" = GLSetup."Shortcut Dimension 1 Code" THEN BEGIN
                    AgreementMaster.VALIDATE("Global Dimension 1 Code", DocumentDimension."Dimension Value Code");
                    AgreementMaster.MODIFY;
                END ELSE
                    IF DocumentDimension."Dimension Code" = GLSetup."Shortcut Dimension 2 Code" THEN BEGIN
                        AgreementMaster.VALIDATE("Global Dimension 2 Code", DocumentDimension."Dimension Value Code");
                        AgreementMaster.MODIFY;
                    END;

                IF DocDim.GET(DATABASE::"Agreement Header", DocDim."Document Type"::Quote, AgreementRec."No.", 0,
                  DocumentDimension."Dimension Code") THEN BEGIN
                    DocDim."Dimension Value Code" := DocumentDimension."Dimension Value Code";
                    DocDim.MODIFY;
                END ELSE BEGIN
                    DocDim.INIT;
                    DocDim."Table ID" := DATABASE::"Agreement Header";
                    DocDim."Document Type" := DocDim."Document Type"::Quote;
                    DocDim."Document No." := AgreementMaster."No.";
                    DocDim."Line No." := 0;
                    DocDim."Dimension Code" := DocumentDimension."Dimension Code";
                    DocDim."Dimension Value Code" := DocumentDimension."Dimension Value Code";
                    IF NOT DocDim.INSERT(TRUE) THEN
                        DocDim.MODIFY;
                END;
            UNTIL DocumentDimension.NEXT = 0;
        END;
    end;

    procedure UpdateRenewedAgreemenLineDim(AgreementLineRec: Record "Agreement Line"; AgreementLineMaster: Record "Agreement Line")
    var
        DocumentDimensionRec: Record "Document Dimension";
        DocDimRec: Record "Document Dimension";
    begin
        DocumentDimensionRec.RESET;
        DocumentDimensionRec.SETRANGE("Table ID", DATABASE::"Agreement Line");
        DocumentDimensionRec.SETRANGE("Document No.", AgreementLineRec."Agreement No.");
        DocumentDimensionRec.SETRANGE("Line No.", AgreementLineRec."Line No.");
        IF DocumentDimensionRec.FINDSET THEN BEGIN
            GLSetup.GET;
            REPEAT
                IF DocumentDimensionRec."Dimension Code" = GLSetup."Shortcut Dimension 1 Code" THEN BEGIN
                    AgreementLineMaster."Global Dimension 1 Code" := DocumentDimensionRec."Dimension Value Code";
                    AgreementLineMaster.MODIFY;
                END ELSE
                    IF DocumentDimensionRec."Dimension Code" = GLSetup."Shortcut Dimension 2 Code" THEN BEGIN
                        AgreementLineMaster."Global Dimension 2 Code" := DocumentDimensionRec."Dimension Value Code";
                        AgreementLineMaster.MODIFY;
                    END;
                DocDimRec.INIT;
                DocDimRec."Table ID" := DATABASE::"Agreement Line";
                DocDimRec."Document Type" := DocDimRec."Document Type"::Quote;
                DocDimRec."Document No." := AgreementLineMaster."Agreement No.";
                DocDimRec."Line No." := AgreementLineMaster."Line No.";
                DocDimRec."Dimension Code" := DocumentDimensionRec."Dimension Code";
                DocDimRec."Dimension Value Code" := DocumentDimensionRec."Dimension Value Code";
                IF NOT DocDimRec.INSERT(TRUE) THEN
                    DocDimRec.MODIFY;
            UNTIL DocumentDimensionRec.NEXT = 0;
        END;
    end;

    procedure TransferAgreement(AgreementRec: Record "Agreement Header")
    var
        CustomerRec: Record Customer;
        CustomerListForm: Form "22";
        CustomerNo: Code[20];
        AgreementMaster: Record "Agreement Header";
        AgreementLineMaster: Record "Agreement Line";
        AgreementCode: Code[20];
        AgreementLineRec: Record "Agreement Line";
        UnpostedRecord: Boolean;
        SalesRec: Record "Sales Header";
        SalesLineRec: Record "Sales Line";
        HeaderRec: Record "Sales Header";
        LineRec: Record "Sales Line";
        NoSeriesMgt: Codeunit "396";
        SalesSetup: Record "Sales & Receivables Setup";
        GLSetup: Record "General Ledger Setup";
        DocDim: Record "Document Dimension";
        DocDimRec: Record "Document Dimension";
    begin
        AgreementRec.TESTFIELD("Agreement Transferred", FALSE);
        IF AgreementRec."Agreement Status" <> AgreementRec."Agreement Status"::Closed THEN BEGIN
            AgreementLineMaster.RESET;
            AgreementLineMaster.SETRANGE("Agreement Type", AgreementRec."Agreement Type");
            AgreementLineMaster.SETRANGE("Agreement No.", AgreementRec."No.");
            IF AgreementLineMaster.FINDSET THEN
                REPEAT
                    AgreementLineMaster.CALCFIELDS("Unposted Invoice");
                    IF AgreementLineMaster."Unposted Invoice" > 0 THEN
                        UnpostedRecord := TRUE;
                UNTIL (AgreementLineMaster.NEXT = 0) OR UnpostedRecord;

            IF UnpostedRecord THEN BEGIN
                IF NOT CONFIRM(Text017, FALSE, AgreementRec."No.") THEN
                    EXIT;
            END;

            CustomerRec.RESET;
            CLEAR(CustomerListForm);
            CustomerRec.SETFILTER("Client Type", '%1|%2', CustomerRec."Client Type"::Tenant, CustomerRec."Client Type"::Client);
            CustomerListForm.SETTABLEVIEW(CustomerRec);
            CustomerListForm.SETRECORD(CustomerRec);
            CustomerListForm.LOOKUPMODE(TRUE);
            IF CustomerListForm.RUNMODAL = ACTION::LookupOK THEN BEGIN
                CustomerListForm.GETRECORD(CustomerRec);
                CustomerNo := CustomerRec."No.";
            END;

            IF CustomerNo = '' THEN
                ERROR(Text014);

            PremiseMgtSetup.GET;
            PremiseMgtSetup.TESTFIELD(Agreement);
            CLEAR(AgreementCode);

            //Agreement Header
            AgreementMaster.INIT;
            AgreementMaster.TRANSFERFIELDS(AgreementRec);
            AgreementCode := NoSeriesMgt.GetNextNo(PremiseMgtSetup.Agreement, TODAY, TRUE);
            AgreementMaster."No." := AgreementCode;
            AgreementMaster.VALIDATE("Approval Status", AgreementMaster."Approval Status"::Open);
            AgreementMaster.VALIDATE("Client No.", CustomerNo);
            AgreementMaster.VALIDATE("Agreement Status", AgreementMaster."Agreement Status"::New);
            AgreementMaster."Transferred Agreement" := TRUE;
            AgreementMaster."Original Agreement No." := AgreementRec."No.";
            AgreementMaster."Original Agreement Type" := AgreementRec."Agreement Type";
            AgreementMaster."Store Opening Date" := AgreementRec."Store Opening Date";
            AgreementMaster."LT Agreement Expiry Date" := AgreementRec."LT Agreement Expiry Date";
            AgreementMaster."Long Term Agreement" := AgreementRec."Long Term Agreement";
            AgreementMaster.INSERT(TRUE);

            IF AgreementRec.GET(AgreementRec."Agreement Type", AgreementRec."No.") THEN BEGIN
                AgreementRec."Agreement Transferred" := TRUE;
                AgreementRec.MODIFY;
            END;

            //Header Dimensions
            UpdateRenewedAgreemenDim(AgreementRec, AgreementMaster);

            //AgreementPremiseRelation
            UpdateAgreementPremiseRelation(AgreementRec, AgreementMaster);

            //Agreement Line
            AgreementLineRec.RESET;
            AgreementLineRec.SETRANGE("Agreement Type", AgreementRec."Agreement Type");
            AgreementLineRec.SETRANGE("Agreement No.", AgreementRec."No.");
            IF AgreementLineRec.FINDSET THEN
                REPEAT
                    AgreementLineMaster.INIT;
                    AgreementLineMaster.TRANSFERFIELDS(AgreementLineRec);
                    AgreementLineMaster."Agreement No." := AgreementCode;
                    AgreementLineMaster.VALIDATE("Original Amount", AgreementLineRec."Original Amount" - AgreementLineRec."Posted Invoice Amt.");
                    AgreementLineMaster.VALIDATE("To be Invoice Amount",
                      AgreementLineRec."Original Amount" - AgreementLineRec."Posted Invoice Amt.");
                    AgreementLineMaster."Posted Invoice Amt." := 0;
                    AgreementLineMaster."Posted Invoice" := 0;
                    AgreementLineMaster.INSERT(TRUE);

                    //Line Dimensions
                    UpdateRenewedAgreemenLineDim(AgreementLineRec, AgreementLineMaster);
                UNTIL AgreementLineRec.NEXT = 0;

            SalesRec.RESET;
            SalesRec.SETRANGE("Ref. Document Type", AgreementRec."Agreement Type");
            SalesRec.SETRANGE("Ref. Document No.", AgreementRec."No.");
            IF SalesRec.FINDSET THEN BEGIN
                SalesSetup.GET;
                GLSetup.GET;
                SalesSetup.TESTFIELD("Invoice Nos.");
                SalesSetup.TESTFIELD("Credit Memo Nos.");
                REPEAT
                    HeaderRec.INIT;
                    IF SalesRec."Document Type" = SalesRec."Document Type"::Invoice THEN BEGIN
                        HeaderRec.VALIDATE("Document Type", HeaderRec."Document Type"::Invoice);
                        HeaderRec."No." := NoSeriesMgt.GetNextNo(SalesSetup."Invoice Nos.", TODAY, TRUE);
                    END ELSE
                        IF SalesRec."Document Type" = SalesRec."Document Type"::"Credit Memo" THEN BEGIN
                            HeaderRec.VALIDATE("Document Type", HeaderRec."Document Type"::"Credit Memo");
                            HeaderRec."No." := NoSeriesMgt.GetNextNo(SalesSetup."Credit Memo Nos.", TODAY, TRUE);
                        END;
                    HeaderRec.INSERT(TRUE);
                    HeaderRec.VALIDATE("Document Date", SalesRec."Document Date");
                    HeaderRec.VALIDATE("Sell-to Customer No.", AgreementMaster."Client No.");
                    HeaderRec.VALIDATE("Salesperson Code", SalesRec."Salesperson Code");
                    HeaderRec.VALIDATE("Currency Code", SalesRec."Currency Code");
                    HeaderRec.VALIDATE("Ref. Document Type", AgreementMaster."Agreement Type");
                    HeaderRec.VALIDATE("Ref. Document No.", AgreementMaster."No.");
                    HeaderRec.MODIFY(TRUE);

                    DocDim.RESET;
                    DocDim.SETRANGE("Table ID", DATABASE::"Sales Header");
                    DocDim.SETRANGE("Document Type", SalesRec."Document Type");
                    DocDim.SETRANGE("Document No.", SalesRec."No.");
                    IF DocDim.FINDSET THEN
                        REPEAT
                            IF GLSetup."Global Dimension 1 Code" = DocDim."Dimension Code" THEN BEGIN
                                HeaderRec.VALIDATE("Shortcut Dimension 1 Code", DocDim."Dimension Value Code");
                                HeaderRec.MODIFY;
                            END ELSE
                                IF GLSetup."Global Dimension 2 Code" = DocDim."Dimension Code" THEN BEGIN
                                    HeaderRec.VALIDATE("Shortcut Dimension 2 Code", DocDim."Dimension Value Code");
                                    HeaderRec.MODIFY;
                                END;
                            DocDimRec.INIT;
                            DocDimRec."Table ID" := DATABASE::"Sales Header";
                            DocDimRec."Document Type" := HeaderRec."Document Type";
                            DocDimRec."Document No." := HeaderRec."No.";
                            DocDimRec."Line No." := 0;
                            DocDimRec."Dimension Code" := DocDim."Dimension Code";
                            DocDimRec."Dimension Value Code" := DocDim."Dimension Value Code";
                            IF NOT DocDimRec.INSERT THEN
                                DocDimRec.MODIFY;
                        UNTIL DocDim.NEXT = 0;

                    SalesLineRec.RESET;
                    SalesLineRec.SETRANGE("Document Type", SalesRec."Document Type");
                    SalesLineRec.SETRANGE("Document No.", SalesRec."No.");
                    IF SalesLineRec.FINDSET THEN
                        REPEAT
                            LineRec.INIT;
                            IF HeaderRec."Document Type" = HeaderRec."Document Type"::Invoice THEN
                                LineRec."Document Type" := LineRec."Document Type"::Invoice
                            ELSE
                                IF HeaderRec."Document Type" = HeaderRec."Document Type"::"Credit Memo" THEN
                                    LineRec."Document Type" := LineRec."Document Type"::"Credit Memo";
                            LineRec."Document No." := HeaderRec."No.";
                            LineRec."Line No." := SalesLineRec."Line No.";

                            LineRec.VALIDATE("Element Type", SalesLineRec."Element Type");
                            LineRec.Type := LineRec.Type::"G/L Account";
                            LineRec.VALIDATE("No.", SalesLineRec."No.");
                            LineRec.VALIDATE(Description, SalesLineRec.Description);
                            LineRec.VALIDATE("Unit of Measure", SalesLineRec."Unit of Measure");
                            LineRec.VALIDATE(Quantity, SalesLineRec.Quantity);
                            LineRec.VALIDATE("Unit Price", SalesLineRec."Unit Price");
                            LineRec.VALIDATE("Line Amount", SalesLineRec."Line Amount");
                            LineRec.VALIDATE(Amount, SalesLineRec.Amount);
                            LineRec."VAT Prod. Posting Group" := SalesLineRec."VAT Prod. Posting Group";
                            LineRec."VAT Bus. Posting Group" := SalesLineRec."VAT Bus. Posting Group";
                            LineRec."Gen. Bus. Posting Group" := SalesLineRec."Gen. Bus. Posting Group";
                            LineRec."Gen. Prod. Posting Group" := SalesLineRec."Gen. Prod. Posting Group";
                            LineRec.VALIDATE("Ref. Document Type", HeaderRec."Ref. Document Type");
                            LineRec.VALIDATE("Ref. Document No.", HeaderRec."Ref. Document No.");
                            LineRec.VALIDATE("Ref. Document Line No.", SalesLineRec."Ref. Document Line No.");
                            LineRec.INSERT;

                            DocDim.RESET;
                            DocDim.SETRANGE("Table ID", DATABASE::"Sales Line");
                            DocDim.SETRANGE("Document Type", LineRec."Document Type");
                            DocDim.SETRANGE("Document No.", LineRec."Document No.");
                            DocDim.SETRANGE("Line No.", LineRec."Line No.");
                            IF DocDim.FINDSET THEN
                                REPEAT
                                    IF GLSetup."Global Dimension 1 Code" = DocDim."Dimension Code" THEN BEGIN
                                        LineRec.VALIDATE("Shortcut Dimension 1 Code", DocDim."Dimension Value Code");
                                        LineRec.MODIFY;
                                    END ELSE
                                        IF GLSetup."Global Dimension 2 Code" = DocDim."Dimension Code" THEN BEGIN
                                            LineRec.VALIDATE("Shortcut Dimension 2 Code", DocDim."Dimension Value Code");
                                            LineRec.MODIFY;
                                        END;
                                    DocDimRec.INIT;
                                    DocDimRec."Table ID" := DATABASE::"Sales Line";
                                    DocDimRec."Document Type" := LineRec."Document Type";
                                    DocDimRec."Document No." := LineRec."No.";
                                    DocDimRec."Line No." := LineRec."Line No.";
                                    DocDimRec."Dimension Code" := DocDim."Dimension Code";
                                    DocDimRec."Dimension Value Code" := DocDim."Dimension Value Code";
                                    IF NOT DocDimRec.INSERT THEN
                                        DocDimRec.MODIFY;
                                UNTIL DocDim.NEXT = 0;
                            SalesLineRec."Ref. Document Type" := 0;
                            SalesLineRec."Ref. Document No." := '';
                            SalesLineRec."Ref. Document Line No." := 0;
                            SalesLineRec.MODIFY;
                        UNTIL SalesLineRec.NEXT = 0;
                    SalesRec."Ref. Document Type" := 0;
                    SalesRec."Ref. Document No." := '';
                    SalesRec.MODIFY;
                UNTIL SalesRec.NEXT = 0;
            END;

            MESSAGE(Text018, AgreementRec."No.", AgreementMaster."No.");
        END ELSE
            ERROR(Text012, AgreementRec."No.")
    end;

    procedure UpdateRevenueSharingAmt(AgreementLineRec: Record "Agreement Line"; FromDate: Date; ToDate: Date): Decimal
    var
        ClientRevRec: Record "Client Revenue";
        RevSharingSlabRec: Record "Revenue Sharing Slab";
        ClientRevenueAmt: Decimal;
        ClientRec: Record Customer;
        CheckFlag: Boolean;
        AgreementHeaderRec: Record "Agreement Header";
        AgreementElementRec: Record "Agreement Element";
    begin
        /*
        IF AgreementElementRec.GET(AgreementLineRec."Element Type") THEN
          IF AgreementElementRec."Rev. Sharing Element" THEN BEGIN
            CLEAR(ClientRevenueAmt);
            ClientRevRec.RESET;
            ClientRevRec.SETFILTER("Client No.",AgreementLineRec."Client No.");
            ClientRevRec.SETRANGE("Agreement Type",AgreementLineRec."Agreement Type");
            ClientRevRec.SETFILTER("Agreement No.",AgreementLineRec."Agreement No.");
            ClientRevRec.SETFILTER("Start Date",'%1..%2',FromDate,ToDate);
            IF ClientRevRec.FINDSET THEN REPEAT
              ClientRevenueAmt += ClientRevRec."Net Sales";
            UNTIL ClientRevRec.NEXT = 0;
        
            CLEAR(CheckFlag);
            AgreementHeaderRec.GET(AgreementLineRec."Agreement Type",AgreementLineRec."Agreement No.");
            IF ClientRevenueAmt <> 0 THEN BEGIN
              //ClientWise
              IF ClientRec.GET(AgreementLineRec."Client No.") THEN
                IF ClientRec."Client Type" = ClientRec."Client Type"::Tenant THEN BEGIN
                  RevSharingSlabRec.RESET;
                  RevSharingSlabRec.SETRANGE("Client No.",RevSharingSlabRec."Client No."::"2");
                  RevSharingSlabRec.SETFILTER("Item Category Code",AgreementLineRec."Client No.");
                  RevSharingSlabRec.SETFILTER("Active From Date",'%1..%2',FromDate,ToDate);
                  RevSharingSlabRec.SETFILTER("Min. Sale",'<=%1',ClientRevenueAmt);
                  RevSharingSlabRec.SETFILTER("Max. Sale",'>=%1',ClientRevenueAmt);
                  IF RevSharingSlabRec.FINDLAST THEN BEGIN
                    IF RevSharingSlabRec."Slab Type" = RevSharingSlabRec."Slab Type"::Amount THEN
                      EXIT(RevSharingSlabRec.Slab)
                    ELSE
                      EXIT((ClientRevenueAmt * RevSharingSlabRec.Slab) / 100);
                  END;
                END;
        
              //SegmentWise
              IF NOT CheckFlag THEN BEGIN
                RevSharingSlabRec.RESET;
                RevSharingSlabRec.SETRANGE("Client No.",RevSharingSlabRec."Client No."::"1");
                RevSharingSlabRec.SETFILTER("Item Category Code",AgreementHeaderRec."Client Segment");
                RevSharingSlabRec.SETFILTER("Active From Date",'%1..%2',FromDate,ToDate);
                RevSharingSlabRec.SETFILTER("Min. Sale",'<=%1',ClientRevenueAmt);
                RevSharingSlabRec.SETFILTER("Max. Sale",'>=%1',ClientRevenueAmt);
                IF RevSharingSlabRec.FINDLAST THEN BEGIN
                  IF RevSharingSlabRec."Slab Type" = RevSharingSlabRec."Slab Type"::Amount THEN
                    EXIT(RevSharingSlabRec.Slab)
                  ELSE
                    EXIT((ClientRevenueAmt * RevSharingSlabRec.Slab) / 100);
                END;
              END;
        
              //All
              IF NOT CheckFlag THEN BEGIN
                RevSharingSlabRec.RESET;
                RevSharingSlabRec.SETRANGE("Client No.",RevSharingSlabRec."Client No."::"0");
                RevSharingSlabRec.SETFILTER("Active From Date",'%1..%2',FromDate,ToDate);
                RevSharingSlabRec.SETFILTER("Min. Sale",'<=%1',ClientRevenueAmt);
                RevSharingSlabRec.SETFILTER("Max. Sale",'>=%1',ClientRevenueAmt);
                IF RevSharingSlabRec.FINDLAST THEN BEGIN
                  IF RevSharingSlabRec."Slab Type" = RevSharingSlabRec."Slab Type"::Amount THEN
                    EXIT(RevSharingSlabRec.Slab)
                  ELSE
                    EXIT((ClientRevenueAmt * RevSharingSlabRec.Slab) / 100);
                END;
              END;
            END;
          END;
        */

    end;

    procedure GenerateClientRevenueInvoice(ClientRevenue: Record "Client Revenue")
    var
        InvoiceRec: Record "Sales Header";
        InvoiceLineRec: Record "Sales Line";
        SalesSetup: Record "Sales & Receivables Setup";
        NoSeriesMgt: Codeunit "396";
        ElementRec: Record "Agreement Element";
        CustomerRec: Record Customer;
        ClientSalesRec: Record "Client Sales Transactions";
        ClientStoreRec: Record "Client Store Mapping";
    begin
        PremiseMgtSetup.GET;
        PremiseMgtSetup.TESTFIELD("Revenue Sharing", TRUE);

        ClientRevenue.TESTFIELD("Invoice Generated", FALSE);
        SalesSetup.GET;
        SalesSetup.TESTFIELD("Invoice Nos.");
        CustomerRec.GET(ClientRevenue."Client No.");
        CustomerRec.TESTFIELD("Revenue Element");
        ElementRec.GET(CustomerRec."Revenue Element");
        ElementRec.TESTFIELD(ElementRec."Invoice G/L Account");

        InvoiceRec.INIT;
        InvoiceRec.VALIDATE("Document Type", InvoiceRec."Document Type"::Invoice);
        CLEAR(NoSeriesMgt);
        InvoiceRec."No." := NoSeriesMgt.GetNextNo(SalesSetup."Invoice Nos.", TODAY, TRUE);
        InvoiceRec.VALIDATE("Document Date", ClientRevenue."Start Date");
        ClientRevenue.TESTFIELD("Client No.");
        InvoiceRec.VALIDATE("Sell-to Customer No.", ClientRevenue."Client No.");
        InvoiceRec.INSERT(TRUE);

        InvoiceLineRec.INIT;
        InvoiceLineRec.VALIDATE("Document Type", InvoiceRec."Document Type");
        InvoiceLineRec.VALIDATE("Document No.", InvoiceRec."No.");
        InvoiceLineRec.VALIDATE("Line No.", 10000);
        InvoiceLineRec.VALIDATE(Type, InvoiceLineRec.Type::"G/L Account");
        InvoiceLineRec.VALIDATE("No.", ElementRec."Invoice G/L Account");
        InvoiceLineRec.VALIDATE("Gen. Prod. Posting Group", ElementRec."Gen. Prod. Posting Group");
        InvoiceLineRec.VALIDATE("VAT Prod. Posting Group", ElementRec."VAT Prod. Posting Group");
        InvoiceLineRec.VALIDATE("Unit Price", ClientRevenue."Net Sales");
        InvoiceLineRec.VALIDATE(Quantity, 1);
        InvoiceLineRec.VALIDATE(Amount, ClientRevenue."Net Sales");
        InvoiceLineRec.VALIDATE("Sell-to Customer No.", InvoiceRec."Sell-to Customer No.");
        InvoiceLineRec.INSERT(TRUE);

        ClientRevenue."Invoice Generated" := TRUE;
        ClientRevenue."Invoice No." := InvoiceRec."No.";
        ClientRevenue.MODIFY;

        ClientStoreRec.RESET;
        ClientStoreRec.SETRANGE("Client No.", ClientRevenue."Client No.");
        IF ClientStoreRec.FINDFIRST THEN BEGIN
            ClientSalesRec.RESET;
            ClientSalesRec.SETRANGE("Store No.", ClientStoreRec."Client Store No.");
            ClientSalesRec.SETRANGE(Date, ClientRevenue."Start Date", ClientRevenue."End Date");
            ClientSalesRec.SETRANGE(Invoiced, FALSE);
            IF ClientSalesRec.FINDSET THEN
                ClientSalesRec.MODIFYALL(Invoiced, TRUE, TRUE);
        END;
        MESSAGE(Text019, InvoiceRec."Document Type", InvoiceRec."No.");
    end;

    procedure ReverseClientRevenueInvoice(InvoiceNo: Code[20])
    var
        ClientRevenueRec: Record "Client Revenue";
        ClientSalesRec: Record "Client Sales Transactions";
        ClientStoreRec: Record "Client Store Mapping";
    begin
        PremiseMgtSetup.GET;
        PremiseMgtSetup.TESTFIELD("Revenue Sharing", TRUE);

        ClientRevenueRec.RESET;
        ClientRevenueRec.SETRANGE("Invoice No.", InvoiceNo);
        IF ClientRevenueRec.FINDFIRST THEN
            REPEAT
                ClientRevenueRec."Invoice No." := '';
                ClientRevenueRec."Invoice Generated" := FALSE;
                ClientRevenueRec.MODIFY;

                ClientSalesRec.RESET;
                ClientSalesRec.SETRANGE("Store No.", ClientRevenueRec."Client Store Code");
                ClientSalesRec.SETRANGE("Client No.", ClientRevenueRec."Client No.");
                ClientSalesRec.SETRANGE(Date, ClientRevenueRec."Start Date", ClientRevenueRec."End Date");
                ClientSalesRec.MODIFYALL(Invoiced, FALSE);
            UNTIL ClientRevenueRec.NEXT = 0;
    end;

    procedure ClientRevenueInvoicePost(InvoiceNo: Code[20])
    var
        ClientRevenueRec: Record "33016829";
    begin
        ClientRevenueRec.RESET;
        ClientRevenueRec.SETRANGE("Invoice No.", InvoiceNo);
        IF ClientRevenueRec.FINDSET THEN BEGIN
            REPEAT
                ClientRevenueRec."Invoice Posted" := TRUE;
                ClientRevenueRec.MODIFY;
            UNTIL ClientRevenueRec.NEXT = 0;
        END;
    end;

    procedure UpdateAgreementPremiseRelation(AgreementRec: Record "Agreement Header"; AgreementMaster: Record "Agreement Header")
    var
        AgreemtRecRelation: Record "Agreement Premise Relation";
        AgrememtMasterRelation: Record "Agreement Premise Relation";
    begin
        AgreemtRecRelation.RESET;
        AgreemtRecRelation.SETRANGE("Agreement No.", AgreementRec."No.");
        IF AgreemtRecRelation.FINDSET THEN BEGIN
            REPEAT
                AgrememtMasterRelation.INIT;
                AgrememtMasterRelation."Agreement Type" := AgreementMaster."Agreement Type";
                AgrememtMasterRelation."Agreement No." := AgreementMaster."No.";
                AgrememtMasterRelation.VALIDATE("Premise No.", AgreemtRecRelation."Premise No.");
                AgrememtMasterRelation."Premise Description" := AgreemtRecRelation."Premise Description";
                AgrememtMasterRelation."Premise/Sub-Premise" := AgreemtRecRelation."Premise/Sub-Premise";
                AgrememtMasterRelation."Sub-Premise of Premise" := AgreemtRecRelation."Sub-Premise of Premise";
                AgrememtMasterRelation.VALIDATE("Agreement Status", AgrememtMasterRelation."Agreement Status"::New);
                AgrememtMasterRelation.INSERT(TRUE);
            UNTIL AgreemtRecRelation.NEXT = 0;
        END;
    end;
}

