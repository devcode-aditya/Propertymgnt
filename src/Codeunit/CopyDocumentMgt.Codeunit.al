codeunit 6620 "Copy Document Mgt."
{
    // LS = changes made by LS Retail
    // DP = changes made by DVS
    // Code          Date        Name        Description
    // APNT-HRU1.0   23.12.13    Sangeeta    Added code for HRU Customization.
    // APNT-HRU1.1   26.06.14    Sangeeta    Added code for HRU Customization.
    // T004175       08.07.14    Sujith      Added code for HRU Customization.
    // APNT-HRU2.0   04.08.14    Ashish      Added code for HRU Customization - disabling Applies to Doc type and No. for Posted Invoice.
    // T005962       06.01.15    Sangeeta    Added code for HRU Customization
    //                                       (To pass SO transaction posted field from Sales Order only in case of Return Order);
    // T005962       20.01.15    Sangeeta    Added code for HRU Customization
    //                                       (To pass SO transaction posted field from Sales Order only in case of Return Order);
    // T006421       26.02.15    Tanweer     Added code to make location code fields blank for HRU Return Orders
    // T007735       05.08.15    Tanweer     Added code to pass Document No. and Document Line No. in Sale Lines
    // APNT-WMS1.0 T015451   11.05.17    Shameema    Added condition to update WMS Exported flag to false bydefault whily copydoc
    // WMS LALS 1.1 12.07.17    Utkarsh  Added code for Updated 'WMS Update SO' and 'WMS Cust Export' flag to false bydefault while copydoc
    // WMS LALS 1.2  24.07.17   Utkarsh  Added code for Update Created date and time while copy Document.
    // WMS LALS 1.3  24.07.17   Utkarsh  Added Code for Update required fields in case of ESO.
    // APNT- T049424  04.05.23  Pavan    Added validation for quantity avaiability while converting POS Quote to POS SFO.


    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'Please enter a Document No.';
        Text001: Label '%1 %2 cannot be copied onto itself.';
        Text002: Label 'The existing lines for %1 %2 will be deleted.\\';
        Text003: Label 'Do you want to continue?';
        Text004: Label 'The document line(s) with a G/L account where direct posting is not allowed have not been copied to the new document by the Copy Document batch job.';
        Text006: Label 'NOTE: A Payment Discount was Granted by %1 %2.';
        Text007: Label 'Quote,Blanket Order,Order,Invoice,Credit Memo,Posted Shipment,Posted Invoice,Posted Credit Memo,Posted Return Receipt';
        Currency: Record Currency;
        Item: Record Item;
        CustCheckCreditLimit: Codeunit "312";
        ItemCheckAvail: Codeunit "311";
        TransferExtendedText: Codeunit "378";
        TransferOldExtLines: Codeunit "379";
        Window: Dialog;
        WindowUpdateTime: Time;
        SalesDocType: Option Quote,"Blanket Order","Order",Invoice,"Return Order","Credit Memo","Posted Shipment","Posted Invoice","Posted Return Receipt","Posted Credit Memo";
        PurchDocType: Option Quote,"Blanket Order","Order",Invoice,"Return Order","Credit Memo","Posted Receipt","Posted Invoice","Posted Return Shipment","Posted Credit Memo";
        ServDocType: Option Quote,Contract;
        IncludeHeader: Boolean;
        RecalculateLines: Boolean;
        MoveNegLines: Boolean;
        Text008: Label 'There are no negative sales lines to move.';
        Text009: Label 'NOTE: A Payment Discount was Received by %1 %2.';
        Text010: Label 'There are no negative purchase lines to move.';
        CreateToHeader: Boolean;
        Text011: Label 'Please enter a Vendor No.';
        HideDialog: Boolean;
        Text012: Label 'There are no sales lines to copy.';
        Text013: Label 'Shipment No.,Invoice No.,Return Receipt No.,Credit Memo No.';
        Text014: Label 'Receipt No.,Invoice No.,Return Shipment No.,Credit Memo No.';
        Text015: Label '%1 %2:';
        Text016: Label 'Inv. No. ,Shpt. No. ,Cr. Memo No. ,Rtrn. Rcpt. No. ';
        Text017: Label 'Inv. No. ,Rcpt. No. ,Cr. Memo No. ,Rtrn. Shpt. No. ';
        Text018: Label '%1 - %2:';
        Text019: Label 'Exact Cost Reversing Link has not been created for all copied document lines.';
        Text020: Label '\';
        Text022: Label 'Copying document lines...\';
        Text023: Label 'Processing source lines      #1######\';
        Text024: Label 'Creating new lines           #2######';
        ExactCostRevMandatory: Boolean;
        ApplyFully: Boolean;
        AskApply: Boolean;
        ReappDone: Boolean;
        Text025: Label 'For one or more return document lines, you chose to return the original quantity, which is already fully applied. Therefore, when you post the return document, the program will reapply relevant entries. Beware that this may change the cost of existing entries. To avoid this, you must delete the affected return document lines before posting.';
        SkippedLine: Boolean;
        Text029: Label 'One or more return document lines were not inserted or they contain only the remaining quantity of the original document line. This is because quantities on the posted document line are already fully or partially applied. If you want to reverse the full quantity, you must select Return Original Quantity before getting the posted document lines.';
        Text030: Label '%1 %2, line no. %3 is not copied because the full quantity on the posted document line is already manually applied.';
        Text031: Label 'Return document line contains only the original document line quantity, that is not already manually applied.';
        SomeAreFixed: Boolean;
        LastVariantSumLineNo: Integer;
        SalesOrder: Record "Sales Header";

    procedure SetProperties(NewIncludeHeader: Boolean; NewRecalculateLines: Boolean; NewMoveNegLines: Boolean; NewCreateToHeader: Boolean; NewHideDialog: Boolean; NewExactCostRevMandatory: Boolean; NewApplyFully: Boolean)
    begin
        IncludeHeader := NewIncludeHeader;
        RecalculateLines := NewRecalculateLines;
        MoveNegLines := NewMoveNegLines;
        CreateToHeader := NewCreateToHeader;
        HideDialog := NewHideDialog;
        ExactCostRevMandatory := NewExactCostRevMandatory;
        ApplyFully := NewApplyFully;
        AskApply := FALSE;
        ReappDone := FALSE;
        SkippedLine := FALSE;
        SomeAreFixed := FALSE;
    end;

    procedure SalesHeaderDocType(DocType: Option): Integer
    var
        SalesHeader: Record "Sales Header";
    begin
        CASE DocType OF
            SalesDocType::Quote:
                EXIT(SalesHeader."Document Type"::Quote);
            SalesDocType::"Blanket Order":
                EXIT(SalesHeader."Document Type"::"Blanket Order");
            SalesDocType::Order:
                EXIT(SalesHeader."Document Type"::Order);
            SalesDocType::Invoice:
                EXIT(SalesHeader."Document Type"::Invoice);
            SalesDocType::"Return Order":
                EXIT(SalesHeader."Document Type"::"Return Order");
            SalesDocType::"Credit Memo":
                EXIT(SalesHeader."Document Type"::"Credit Memo");
        END;
    end;

    procedure PurchHeaderDocType(DocType: Option): Integer
    var
        FromPurchHeader: Record "Purchase Header";
    begin
        CASE DocType OF
            PurchDocType::Quote:
                EXIT(FromPurchHeader."Document Type"::Quote);
            PurchDocType::"Blanket Order":
                EXIT(FromPurchHeader."Document Type"::"Blanket Order");
            PurchDocType::Order:
                EXIT(FromPurchHeader."Document Type"::Order);
            PurchDocType::Invoice:
                EXIT(FromPurchHeader."Document Type"::Invoice);
            PurchDocType::"Return Order":
                EXIT(FromPurchHeader."Document Type"::"Return Order");
            PurchDocType::"Credit Memo":
                EXIT(FromPurchHeader."Document Type"::"Credit Memo");
        END;
    end;

    procedure CopySalesDoc(FromDocType: Option; FromDocNo: Code[20]; var ToSalesHeader: Record "Sales Header")
    var
        PaymentTerms: Record "Payment Terms";
        ToSalesLine: Record "Sales Line";
        OldSalesHeader: Record "Sales Header";
        FromSalesHeader: Record "Sales Header";
        FromSalesLine: Record "Sales Line";
        FromSalesShptHeader: Record "Sales Shipment Header";
        FromSalesShptLine: Record "Sales Shipment Line";
        FromSalesInvHeader: Record "Sales Invoice Header";
        FromSalesInvLine: Record "Sales Invoice Line";
        FromReturnRcptHeader: Record "Return Receipt Header";
        FromReturnRcptLine: Record "Return Receipt Line";
        FromSalesCrMemoHeader: Record "Sales Cr.Memo Header";
        FromSalesCrMemoLine: Record "Sales Cr.Memo Line";
        DocDim: Record "Document Dimension";
        CustLedgEntry: Record "Cust. Ledger Entry";
        GLSetUp: Record "General Ledger Setup";
        Cust: Record Customer;
        NextLineNo: Integer;
        ItemChargeAssgntNextLineNo: Integer;
        LinesNotCopied: Integer;
        MissingExCostRevLink: Boolean;
        ReleaseSalesDocument: Codeunit "414";
        ReleaseDocument: Boolean;
        lConfigID: Code[30];
        SalesSetup: Record "Sales & Receivables Setup";
        HRUCopyDocExtension: Codeunit "50057";
    begin
        WITH ToSalesHeader DO BEGIN
            IF NOT CreateToHeader THEN BEGIN
                TESTFIELD(Status, Status::Open);
                IF FromDocNo = '' THEN
                    ERROR(Text000);
                FIND;
            END;
            TransferOldExtLines.ClearLineNumbers;
            CASE FromDocType OF
                SalesDocType::Quote,
                SalesDocType::"Blanket Order",
                SalesDocType::Order,
                SalesDocType::Invoice,
                SalesDocType::"Return Order",
                SalesDocType::"Credit Memo":
                    BEGIN
                        FromSalesHeader.GET(SalesHeaderDocType(FromDocType), FromDocNo);
                        IF MoveNegLines THEN
                            DeleteSalesLinesWithNegQty(FromSalesHeader, TRUE);
                        IF (FromSalesHeader."Document Type" = "Document Type") AND
                           (FromSalesHeader."No." = "No.")
                        THEN
                            ERROR(
                              Text001,
                              "Document Type", "No.");

                        IF "Document Type" <= "Document Type"::Invoice THEN BEGIN
                            FromSalesHeader.CALCFIELDS("Amount Including VAT");
                            "Amount Including VAT" := FromSalesHeader."Amount Including VAT";
                            IF IncludeHeader THEN
                                CustCheckCreditLimit.SalesHeaderCheck(FromSalesHeader)
                            ELSE
                                CustCheckCreditLimit.SalesHeaderCheck(ToSalesHeader);
                        END;
                        IF "Document Type" IN ["Document Type"::Order, "Document Type"::Invoice] THEN BEGIN
                            FromSalesLine.SETRANGE("Document Type", FromSalesHeader."Document Type");
                            FromSalesLine.SETRANGE("Document No.", FromSalesHeader."No.");
                            FromSalesLine.SETRANGE(Type, FromSalesLine.Type::Item);
                            FromSalesLine.SETFILTER("No.", '<>%1', '');
                            IF FromSalesLine.FIND('-') THEN
                                REPEAT
                                    IF FromSalesLine.Quantity > 0 THEN BEGIN
                                        ToSalesLine."No." := FromSalesLine."No.";
                                        ToSalesLine."Variant Code" := FromSalesLine."Variant Code";
                                        ToSalesLine."Location Code" := FromSalesLine."Location Code";
                                        ToSalesLine."Bin Code" := FromSalesLine."Bin Code";
                                        ToSalesLine."Unit of Measure Code" := FromSalesLine."Unit of Measure Code";
                                        ToSalesLine."Qty. per Unit of Measure" := FromSalesLine."Qty. per Unit of Measure";
                                        ToSalesLine."Outstanding Quantity" := FromSalesLine.Quantity;
                                        ToSalesLine."Drop Shipment" := FromSalesLine."Drop Shipment";
                                        // APNT  T049424
                                        CheckInventory(FromSalesLine."No.", FromSalesLine."Location Code",
                                        FromSalesLine.Quantity, FromSalesLine."Pick Location");
                                        // APNT  T049424
                                        CheckItemAvailable(ToSalesHeader, ToSalesLine);
                                    END;
                                UNTIL FromSalesLine.NEXT = 0;
                        END;
                        IF NOT IncludeHeader AND NOT RecalculateLines THEN BEGIN
                            FromSalesHeader.TESTFIELD("Sell-to Customer No.", "Sell-to Customer No.");
                            FromSalesHeader.TESTFIELD("Bill-to Customer No.", "Bill-to Customer No.");
                            FromSalesHeader.TESTFIELD("Customer Posting Group", "Customer Posting Group");
                            FromSalesHeader.TESTFIELD("Gen. Bus. Posting Group", "Gen. Bus. Posting Group");
                            FromSalesHeader.TESTFIELD("Currency Code", "Currency Code");
                            FromSalesHeader.TESTFIELD("Prices Including VAT", "Prices Including VAT");
                        END;
                    END;
                SalesDocType::"Posted Shipment":
                    BEGIN
                        FromSalesShptHeader.GET(FromDocNo);
                        IF "Document Type" IN ["Document Type"::Order, "Document Type"::Invoice] THEN BEGIN
                            FromSalesShptLine.SETRANGE("Document No.", FromSalesShptHeader."No.");
                            FromSalesShptLine.SETRANGE(Type, FromSalesShptLine.Type::Item);
                            FromSalesShptLine.SETFILTER("No.", '<>%1', '');
                            IF FromSalesShptLine.FIND('-') THEN
                                REPEAT
                                    IF FromSalesShptLine.Quantity > 0 THEN BEGIN
                                        ToSalesLine."No." := FromSalesShptLine."No.";
                                        ToSalesLine."Variant Code" := FromSalesShptLine."Variant Code";
                                        ToSalesLine."Location Code" := FromSalesShptLine."Location Code";
                                        ToSalesLine."Bin Code" := FromSalesShptLine."Bin Code";
                                        ToSalesLine."Unit of Measure Code" := FromSalesShptLine."Unit of Measure Code";
                                        ToSalesLine."Qty. per Unit of Measure" := FromSalesShptLine."Qty. per Unit of Measure";
                                        ToSalesLine."Outstanding Quantity" := FromSalesShptLine.Quantity;
                                        ToSalesLine."Drop Shipment" := FromSalesShptLine."Drop Shipment";
                                        CheckItemAvailable(ToSalesHeader, ToSalesLine);
                                    END;
                                UNTIL FromSalesShptLine.NEXT = 0;
                        END;
                        IF NOT IncludeHeader AND NOT RecalculateLines THEN BEGIN
                            FromSalesShptHeader.TESTFIELD("Sell-to Customer No.", "Sell-to Customer No.");
                            FromSalesShptHeader.TESTFIELD("Bill-to Customer No.", "Bill-to Customer No.");
                            FromSalesShptHeader.TESTFIELD("Customer Posting Group", "Customer Posting Group");
                            FromSalesShptHeader.TESTFIELD("Gen. Bus. Posting Group", "Gen. Bus. Posting Group");
                            FromSalesShptHeader.TESTFIELD("Currency Code", "Currency Code");
                            FromSalesShptHeader.TESTFIELD("Prices Including VAT", "Prices Including VAT");
                        END;
                    END;
                SalesDocType::"Posted Invoice":
                    BEGIN
                        FromSalesInvHeader.GET(FromDocNo);
                        FromSalesInvHeader.TESTFIELD("Prepayment Invoice", FALSE);
                        WarnSalesInvoicePmtDisc(ToSalesHeader, FromSalesHeader, FromDocType, FromDocNo);
                        IF "Document Type" <= "Document Type"::Invoice THEN BEGIN
                            FromSalesInvHeader.CALCFIELDS("Amount Including VAT");
                            "Amount Including VAT" := FromSalesInvHeader."Amount Including VAT";
                            IF IncludeHeader THEN BEGIN
                                FromSalesHeader.TRANSFERFIELDS(FromSalesInvHeader);
                                CustCheckCreditLimit.SalesHeaderCheck(FromSalesHeader)
                            END ELSE
                                CustCheckCreditLimit.SalesHeaderCheck(ToSalesHeader);
                        END;
                        IF "Document Type" IN ["Document Type"::Order, "Document Type"::Invoice] THEN BEGIN
                            FromSalesInvLine.SETRANGE("Document No.", FromSalesInvHeader."No.");
                            FromSalesInvLine.SETRANGE(Type, FromSalesInvLine.Type::Item);
                            FromSalesInvLine.SETFILTER("No.", '<>%1', '');
                            FromSalesInvLine.SETRANGE("Prepayment Line", FALSE);
                            IF FromSalesInvLine.FIND('-') THEN
                                REPEAT
                                    IF FromSalesInvLine.Quantity > 0 THEN BEGIN
                                        ToSalesLine."No." := FromSalesInvLine."No.";
                                        ToSalesLine."Variant Code" := FromSalesInvLine."Variant Code";
                                        ToSalesLine."Location Code" := FromSalesInvLine."Location Code";
                                        ToSalesLine."Bin Code" := FromSalesInvLine."Bin Code";
                                        ToSalesLine."Unit of Measure Code" := FromSalesInvLine."Unit of Measure Code";
                                        ToSalesLine."Qty. per Unit of Measure" := FromSalesInvLine."Qty. per Unit of Measure";
                                        ToSalesLine."Outstanding Quantity" := FromSalesInvLine.Quantity;
                                        ToSalesLine."Drop Shipment" := FromSalesInvLine."Drop Shipment";
                                        CheckItemAvailable(ToSalesHeader, ToSalesLine);
                                    END;
                                UNTIL FromSalesInvLine.NEXT = 0;
                        END;
                        IF NOT IncludeHeader AND NOT RecalculateLines THEN BEGIN
                            FromSalesInvHeader.TESTFIELD("Sell-to Customer No.", "Sell-to Customer No.");
                            FromSalesInvHeader.TESTFIELD("Bill-to Customer No.", "Bill-to Customer No.");
                            FromSalesInvHeader.TESTFIELD("Customer Posting Group", "Customer Posting Group");
                            FromSalesInvHeader.TESTFIELD("Gen. Bus. Posting Group", "Gen. Bus. Posting Group");
                            FromSalesInvHeader.TESTFIELD("Currency Code", "Currency Code");
                            FromSalesInvHeader.TESTFIELD("Prices Including VAT", "Prices Including VAT");
                        END;
                    END;
                SalesDocType::"Posted Return Receipt":
                    BEGIN
                        FromReturnRcptHeader.GET(FromDocNo);
                        IF "Document Type" IN ["Document Type"::Order, "Document Type"::Invoice] THEN BEGIN
                            FromReturnRcptLine.SETRANGE("Document No.", FromReturnRcptHeader."No.");
                            FromReturnRcptLine.SETRANGE(Type, FromReturnRcptLine.Type::Item);
                            FromReturnRcptLine.SETFILTER("No.", '<>%1', '');
                            IF FromReturnRcptLine.FIND('-') THEN
                                REPEAT
                                    IF FromReturnRcptLine.Quantity > 0 THEN BEGIN
                                        ToSalesLine."No." := FromReturnRcptLine."No.";
                                        ToSalesLine."Variant Code" := FromReturnRcptLine."Variant Code";
                                        ToSalesLine."Location Code" := FromReturnRcptLine."Location Code";
                                        ToSalesLine."Bin Code" := FromReturnRcptLine."Bin Code";
                                        ToSalesLine."Unit of Measure Code" := FromReturnRcptLine."Unit of Measure Code";
                                        ToSalesLine."Qty. per Unit of Measure" := FromReturnRcptLine."Qty. per Unit of Measure";
                                        ToSalesLine."Outstanding Quantity" := FromReturnRcptLine.Quantity;
                                        ToSalesLine."Drop Shipment" := FALSE;
                                        CheckItemAvailable(ToSalesHeader, ToSalesLine);
                                    END;
                                UNTIL FromReturnRcptLine.NEXT = 0;
                        END;
                        IF NOT IncludeHeader AND NOT RecalculateLines THEN BEGIN
                            FromReturnRcptHeader.TESTFIELD("Sell-to Customer No.", "Sell-to Customer No.");
                            FromReturnRcptHeader.TESTFIELD("Bill-to Customer No.", "Bill-to Customer No.");
                            FromReturnRcptHeader.TESTFIELD("Customer Posting Group", "Customer Posting Group");
                            FromReturnRcptHeader.TESTFIELD("Gen. Bus. Posting Group", "Gen. Bus. Posting Group");
                            FromReturnRcptHeader.TESTFIELD("Currency Code", "Currency Code");
                            FromReturnRcptHeader.TESTFIELD("Prices Including VAT", "Prices Including VAT");
                        END;
                    END;
                SalesDocType::"Posted Credit Memo":
                    BEGIN
                        FromSalesCrMemoHeader.GET(FromDocNo);
                        WarnSalesInvoicePmtDisc(ToSalesHeader, FromSalesHeader, FromDocType, FromDocNo);
                        IF "Document Type" <= "Document Type"::Invoice THEN BEGIN
                            FromSalesCrMemoHeader.CALCFIELDS("Amount Including VAT");
                            "Amount Including VAT" := FromSalesCrMemoHeader."Amount Including VAT";
                            IF IncludeHeader THEN BEGIN
                                FromSalesHeader.TRANSFERFIELDS(FromSalesInvHeader);
                                CustCheckCreditLimit.SalesHeaderCheck(FromSalesHeader)
                            END ELSE
                                CustCheckCreditLimit.SalesHeaderCheck(ToSalesHeader);
                        END;
                        IF "Document Type" IN ["Document Type"::Order, "Document Type"::Invoice] THEN BEGIN
                            FromSalesCrMemoLine.SETRANGE("Document No.", FromSalesCrMemoHeader."No.");
                            FromSalesCrMemoLine.SETRANGE(Type, FromSalesCrMemoLine.Type::Item);
                            FromSalesCrMemoLine.SETFILTER("No.", '<>%1', '');
                            FromSalesCrMemoLine.SETRANGE("Prepayment Line", FALSE);
                            IF FromSalesCrMemoLine.FIND('-') THEN
                                REPEAT
                                    IF FromSalesCrMemoLine.Quantity > 0 THEN BEGIN
                                        ToSalesLine."No." := FromSalesCrMemoLine."No.";
                                        ToSalesLine."Variant Code" := FromSalesCrMemoLine."Variant Code";
                                        ToSalesLine."Location Code" := FromSalesCrMemoLine."Location Code";
                                        ToSalesLine."Bin Code" := FromSalesCrMemoLine."Bin Code";
                                        ToSalesLine."Unit of Measure Code" := FromSalesCrMemoLine."Unit of Measure Code";
                                        ToSalesLine."Qty. per Unit of Measure" := FromSalesCrMemoLine."Qty. per Unit of Measure";
                                        ToSalesLine."Outstanding Quantity" := FromSalesCrMemoLine.Quantity;
                                        ToSalesLine."Drop Shipment" := FALSE;
                                        CheckItemAvailable(ToSalesHeader, ToSalesLine);
                                    END;
                                UNTIL FromSalesCrMemoLine.NEXT = 0;
                        END;
                        IF NOT IncludeHeader AND NOT RecalculateLines THEN BEGIN
                            FromSalesCrMemoHeader.TESTFIELD("Sell-to Customer No.", "Sell-to Customer No.");
                            FromSalesCrMemoHeader.TESTFIELD("Bill-to Customer No.", "Bill-to Customer No.");
                            FromSalesCrMemoHeader.TESTFIELD("Customer Posting Group", "Customer Posting Group");
                            FromSalesCrMemoHeader.TESTFIELD("Gen. Bus. Posting Group", "Gen. Bus. Posting Group");
                            FromSalesCrMemoHeader.TESTFIELD("Currency Code", "Currency Code");
                            FromSalesCrMemoHeader.TESTFIELD("Prices Including VAT", "Prices Including VAT");
                        END;
                    END;
            END;

            DocDim.LOCKTABLE;
            ToSalesLine.LOCKTABLE;

            IF CreateToHeader THEN BEGIN
                INSERT(TRUE);
                ToSalesLine.SETRANGE("Document Type", "Document Type");
                ToSalesLine.SETRANGE("Document No.", "No.");
            END ELSE BEGIN
                ToSalesLine.SETRANGE("Document Type", "Document Type");
                ToSalesLine.SETRANGE("Document No.", "No.");
                IF IncludeHeader THEN BEGIN
                    IF ToSalesLine.FIND('-') THEN BEGIN
                        COMMIT;
                        IF NOT
                           CONFIRM(
                             Text002 +
                             Text003, TRUE,
                             "Document Type", "No.")
                        THEN
                            EXIT;
                        ToSalesLine.DELETEALL(TRUE);
                    END;
                END;
            END;

            IF ToSalesLine.FIND('+') THEN
                NextLineNo := ToSalesLine."Line No."
            ELSE
                NextLineNo := 0;

            IF NOT RECORDLEVELLOCKING THEN
                LOCKTABLE(TRUE, TRUE);

            IF IncludeHeader THEN BEGIN
                IF Cust.GET(FromSalesHeader."Sell-to Customer No.") THEN
                    Cust.CheckBlockedCustOnDocs(Cust, "Document Type", FALSE, FALSE);
                IF Cust.GET(FromSalesHeader."Bill-to Customer No.") THEN
                    Cust.CheckBlockedCustOnDocs(Cust, "Document Type", FALSE, FALSE);
                OldSalesHeader := ToSalesHeader;
                CASE FromDocType OF
                    SalesDocType::Quote,
                    SalesDocType::"Blanket Order",
                    SalesDocType::Order,
                    SalesDocType::Invoice,
                    SalesDocType::"Return Order",
                    SalesDocType::"Credit Memo":
                        BEGIN
                            TRANSFERFIELDS(FromSalesHeader, FALSE);
                            Status := Status::Open;
                            IF "Document Type" <> "Document Type"::Order THEN
                                ToSalesHeader."Prepayment %" := 0;
                            IF FromDocType = SalesDocType::"Return Order" THEN
                                VALIDATE("Ship-to Code");
                            IF FromDocType IN [SalesDocType::Quote, SalesDocType::"Blanket Order"] THEN
                                IF OldSalesHeader."Posting Date" = 0D THEN
                                    "Posting Date" := WORKDATE
                                ELSE
                                    "Posting Date" := OldSalesHeader."Posting Date";
                            CopyFromSalesDocDimToHeader(ToSalesHeader, FromSalesHeader);
                        END;
                    SalesDocType::"Posted Shipment":
                        BEGIN
                            ToSalesHeader.VALIDATE("Sell-to Customer No.", FromSalesShptHeader."Sell-to Customer No.");
                            TRANSFERFIELDS(FromSalesShptHeader, FALSE);
                            CopyFromPstdSalesDocDimToHdr(
                              ToSalesHeader, FromDocType, FromSalesShptHeader, FromSalesInvHeader,
                              FromReturnRcptHeader, FromSalesCrMemoHeader);
                        END;
                    SalesDocType::"Posted Invoice":
                        BEGIN
                            ToSalesHeader.VALIDATE("Sell-to Customer No.", FromSalesInvHeader."Sell-to Customer No.");
                            TRANSFERFIELDS(FromSalesInvHeader, FALSE);
                            CopyFromPstdSalesDocDimToHdr(
                              ToSalesHeader, FromDocType, FromSalesShptHeader, FromSalesInvHeader,
                              FromReturnRcptHeader, FromSalesCrMemoHeader);
                        END;
                    SalesDocType::"Posted Return Receipt":
                        BEGIN
                            ToSalesHeader.VALIDATE("Sell-to Customer No.", FromReturnRcptHeader."Sell-to Customer No.");
                            TRANSFERFIELDS(FromReturnRcptHeader, FALSE);
                            CopyFromPstdSalesDocDimToHdr(
                              ToSalesHeader, FromDocType, FromSalesShptHeader, FromSalesInvHeader,
                              FromReturnRcptHeader, FromSalesCrMemoHeader);
                        END;
                    SalesDocType::"Posted Credit Memo":
                        BEGIN
                            ToSalesHeader.VALIDATE("Sell-to Customer No.", FromSalesCrMemoHeader."Sell-to Customer No.");
                            TRANSFERFIELDS(FromSalesCrMemoHeader, FALSE);
                            CopyFromPstdSalesDocDimToHdr(
                              ToSalesHeader, FromDocType, FromSalesShptHeader, FromSalesInvHeader,
                              FromReturnRcptHeader, FromSalesCrMemoHeader);
                        END;
                END;
                IF Status = Status::Released THEN BEGIN
                    Status := Status::Open;
                    ReleaseDocument := TRUE;
                END;
                IF MoveNegLines OR IncludeHeader THEN
                    ToSalesHeader.VALIDATE("Location Code");

                "No. Series" := OldSalesHeader."No. Series";
                "Posting Description" := OldSalesHeader."Posting Description";
                "Posting No." := OldSalesHeader."Posting No.";
                "Posting No. Series" := OldSalesHeader."Posting No. Series";
                "Shipping No." := OldSalesHeader."Shipping No.";
                "Shipping No. Series" := OldSalesHeader."Shipping No. Series";
                "Return Receipt No." := OldSalesHeader."Return Receipt No.";
                "Return Receipt No. Series" := OldSalesHeader."Return Receipt No. Series";
                "Prepayment No. Series" := OldSalesHeader."Prepayment No. Series";
                "Prepayment No." := OldSalesHeader."Prepayment No.";
                "Prepmt. Posting Description" := OldSalesHeader."Prepmt. Posting Description";
                "Prepmt. Cr. Memo No. Series" := OldSalesHeader."Prepmt. Cr. Memo No. Series";
                "Prepmt. Cr. Memo No." := OldSalesHeader."Prepmt. Cr. Memo No.";
                "Prepmt. Posting Description" := OldSalesHeader."Prepmt. Posting Description";
                "No. Printed" := 0;
                "Applies-to Doc. Type" := "Applies-to Doc. Type"::" ";
                "Applies-to Doc. No." := '';
                "Applies-to ID" := '';
                "Opportunity No." := '';
                //T004175
                IF OldSalesHeader."HRU Document" THEN BEGIN
                    "HRU Document" := TRUE;
                END;
                //T004175
                //APNT-HRU1.0 -
                IF FromSalesHeader."HRU Document" THEN BEGIN
                    "External Document No." := FromSalesHeader."No.";
                    //APNT-T005962 -
                    IF "Document Type" = "Document Type"::"Return Order" THEN
                        "SO Transaction Posted" := FromSalesHeader."Transaction Posted"
                    ELSE
                        "SO Transaction Posted" := FALSE;
                    //APNT-T005962 +
                    "Transaction Posted" := FALSE;
                    "Retrieved At POS" := FALSE;
                    "Statement Posted" := FALSE;  //APNT-HRU1.1
                    "Open Statement No." := '';  //APNT-HRU1.1
                    "Quote No." := FromSalesHeader."No.";    //T004175
                                                             //T015451 -
                    "WMS Exported" := FALSE;
                    "WMS Customer Export" := FALSE;      //WMS LALS 1.1
                    "WMS Update SO" := FALSE;      //WMS LALS 1.1
                                                   //T015451 +
                    "Created Date" := WORKDATE;    //WMS LALS 1.2
                    "Created Time" := TIME;        //WMS LALS 1.2

                    /*
                    "Deposit Amount" := 0;
                    "Deposit Received" := FALSE;
                    */
                    "Created Time" := TIME;
                    "Created Date" := TODAY;
                    SalesSetup.GET;
                    IF SalesSetup."Unattended SO Time Frame (Min)" <> 0 THEN BEGIN
                        "Cancellation Time" := "Created Time" + (60000 * SalesSetup."Unattended SO Time Frame (Min)")
                    END ELSE
                        "Cancellation Time" := "Created Time" + (60000 * 30);
                    "SO Lines Reversed" := FALSE;
                    //T004175
                    "Cancellation Time" := OldSalesHeader."Cancellation Time";
                    "Cancellation Date" := OldSalesHeader."Cancellation Date";
                    //T004175
                END;
                //WMS LALS 1.3
                "WMS Exported" := FALSE;
                "WMS Customer Export" := FALSE;      //WMS LALS 1.1
                "WMS Update SO" := FALSE;      //WMS LALS 1.1
                                               //T015451 +
                "Created Date" := WORKDATE;    //WMS LALS 1.2
                "Created Time" := TIME;        //WMS LALS 1.2
                                               //WMS LALS 1.3

                IF FromSalesShptHeader."HRU Document" THEN BEGIN
                    "External Document No." := FromSalesShptHeader."No.";
                    //APNT-T005962 -
                    IF "Document Type" = "Document Type"::"Return Order" THEN
                        //APNT-T005962 +
                        "SO Transaction Posted" := FromSalesShptHeader."Transaction Posted"
                    ELSE
                        "SO Transaction Posted" := FALSE;
                    "Transaction Posted" := FALSE;
                    "Retrieved At POS" := FALSE;
                    "Statement Posted" := FALSE;
                    "Open Statement No." := '';
                    /*
                    "Deposit Amount" := 0;
                    "Deposit Received" := FALSE;
                    */
                    "Created Time" := TIME;
                    "Created Date" := TODAY;
                    //T015451 -
                    "WMS Exported" := FALSE;
                    "WMS Customer Export" := FALSE;      //WMS LALS 1.1
                    "WMS Update SO" := FALSE;      //WMS LALS 1.1
                                                   //T015451 +
                    "Created Date" := WORKDATE;    //WMS LALS 1.2
                    "Created Time" := TIME;        //WMS LALS 1.2

                    SalesSetup.GET;
                    IF SalesSetup."Unattended SO Time Frame (Min)" <> 0 THEN BEGIN
                        "Cancellation Time" := "Created Time" + (60000 * SalesSetup."Unattended SO Time Frame (Min)")
                    END ELSE
                        "Cancellation Time" := "Created Time" + (60000 * 30);
                    "SO Lines Reversed" := FALSE;
                END;
                //WMS LALS 1.3
                "WMS Exported" := FALSE;
                "WMS Customer Export" := FALSE;      //WMS LALS 1.1
                "WMS Update SO" := FALSE;      //WMS LALS 1.1
                                               //T015451 +
                "Created Date" := WORKDATE;    //WMS LALS 1.2
                "Created Time" := TIME;        //WMS LALS 1.2
                                               //WMS LALS 1.3

                IF FromSalesInvHeader."HRU Document" THEN BEGIN
                    "External Document No." := FromSalesInvHeader."No.";
                    //APNT-T005962 -
                    IF "Document Type" = "Document Type"::"Return Order" THEN
                        //APNT-T005962 +
                        "SO Transaction Posted" := FromSalesInvHeader."Transaction Posted"
                    ELSE
                        "SO Transaction Posted" := FALSE;
                    "Transaction Posted" := FALSE;
                    "Retrieved At POS" := FALSE;
                    "Statement Posted" := FALSE;
                    "Open Statement No." := '';
                    /*
                    "Deposit Amount" := 0;
                    "Deposit Received" := FALSE;
                    */
                    "Created Time" := TIME;
                    "Created Date" := TODAY;
                    //T015451 -
                    "WMS Exported" := FALSE;
                    "WMS Customer Export" := FALSE;      //WMS LALS 1.1
                    "WMS Update SO" := FALSE;      //WMS LALS 1.1
                                                   //T015451 +
                    "Created Date" := WORKDATE;    //WMS LALS 1.2
                    "Created Time" := TIME;        //WMS LALS 1.2

                    SalesSetup.GET;
                    IF SalesSetup."Unattended SO Time Frame (Min)" <> 0 THEN BEGIN
                        "Cancellation Time" := "Created Time" + (60000 * SalesSetup."Unattended SO Time Frame (Min)")
                    END ELSE
                        "Cancellation Time" := "Created Time" + (60000 * 30);
                    "SO Lines Reversed" := FALSE;
                    //T004175
                    "Cancellation Time" := OldSalesHeader."Cancellation Time";
                    "Cancellation Date" := OldSalesHeader."Cancellation Date";
                    //T004175
                END;
                //WMS LALS 1.3
                "WMS Exported" := FALSE;
                "WMS Customer Export" := FALSE;      //WMS LALS 1.1
                "WMS Update SO" := FALSE;      //WMS LALS 1.1
                                               //T015451 +
                "Created Date" := WORKDATE;    //WMS LALS 1.2
                "Created Time" := TIME;        //WMS LALS 1.2
                                               //WMS LALS 1.3


                //APNT-HRU1.0 +
                ClearSalesBizTalkFields(ToSalesHeader);
                IF ((FromDocType = SalesDocType::"Posted Invoice") AND
                    ("Document Type" IN ["Document Type"::"Return Order", "Document Type"::"Credit Memo"])) OR
                   ((FromDocType = SalesDocType::"Posted Credit Memo") AND
                    NOT ("Document Type" IN ["Document Type"::"Return Order", "Document Type"::"Credit Memo"]))
                THEN BEGIN
                    CustLedgEntry.SETCURRENTKEY("Document No.");
                    IF FromDocType = SalesDocType::"Posted Invoice" THEN
                        CustLedgEntry.SETRANGE("Document Type", CustLedgEntry."Document Type"::Invoice)
                    ELSE
                        CustLedgEntry.SETRANGE("Document Type", CustLedgEntry."Document Type"::"Credit Memo");
                    CustLedgEntry.SETRANGE("Document No.", FromDocNo);
                    CustLedgEntry.SETRANGE("Customer No.", "Bill-to Customer No.");
                    CustLedgEntry.SETRANGE(Open, TRUE);
                    IF CustLedgEntry.FIND('-') THEN BEGIN
                        IF FromDocType = SalesDocType::"Posted Invoice" THEN BEGIN
                            "Applies-to Doc. Type" := "Applies-to Doc. Type"::Invoice;
                            "Applies-to Doc. No." := FromDocNo;
                            //APNT-HRU2.0
                            IF ("Document Type" = "Document Type"::"Return Order") AND "HRU Document" THEN BEGIN
                                "Applies-to Doc. Type" := "Applies-to Doc. Type"::" ";
                                "Applies-to Doc. No." := '';
                            END;
                            //APNT-HRU2.0
                        END ELSE BEGIN
                            "Applies-to Doc. Type" := "Applies-to Doc. Type"::"Credit Memo";
                            "Applies-to Doc. No." := FromDocNo;
                        END;
                        CustLedgEntry.CALCFIELDS("Remaining Amount");
                        CustLedgEntry."Amount to Apply" := CustLedgEntry."Remaining Amount";
                        CustLedgEntry."Accepted Payment Tolerance" := 0;
                        CustLedgEntry."Accepted Pmt. Disc. Tolerance" := FALSE;
                        CODEUNIT.RUN(CODEUNIT::"Cust. Entry-Edit", CustLedgEntry);
                    END;
                END;

                IF "Document Type" IN ["Document Type"::"Blanket Order", "Document Type"::Quote] THEN
                    "Posting Date" := 0D;

                Correction := FALSE;
                IF "Document Type" IN ["Document Type"::"Return Order", "Document Type"::"Credit Memo"] THEN BEGIN
                    "Shipment Date" := 0D;
                    GLSetUp.GET;
                    Correction := GLSetUp."Mark Cr. Memos as Corrections";
                    IF ("Payment Terms Code" <> '') AND ("Document Date" <> 0D) THEN
                        PaymentTerms.GET("Payment Terms Code")
                    ELSE
                        CLEAR(PaymentTerms);
                    IF NOT PaymentTerms."Calc. Pmt. Disc. on Cr. Memos" THEN BEGIN
                        "Payment Terms Code" := '';
                        "Due Date" := 0D;
                        "Payment Discount %" := 0;
                        "Pmt. Discount Date" := 0D;
                    END;
                END;

                IF CreateToHeader THEN BEGIN
                    VALIDATE("Payment Terms Code");
                    MODIFY(TRUE);
                END ELSE
                    MODIFY;
            END;

            LinesNotCopied := 0;
            CASE FromDocType OF
                SalesDocType::Quote,
                SalesDocType::"Blanket Order",
                SalesDocType::Order,
                SalesDocType::Invoice,
                SalesDocType::"Return Order",
                SalesDocType::"Credit Memo":
                    BEGIN
                        ItemChargeAssgntNextLineNo := 0;
                        FromSalesLine.RESET;
                        FromSalesLine.SETRANGE("Document Type", FromSalesHeader."Document Type");
                        FromSalesLine.SETRANGE("Document No.", FromSalesHeader."No.");
                        IF MoveNegLines THEN
                            FromSalesLine.SETFILTER(Quantity, '<=0');
                        IF FromSalesLine.FIND('-') THEN
                            REPEAT
                                IF CopySalesLine(ToSalesHeader, ToSalesLine, FromSalesHeader, FromSalesLine, NextLineNo, LinesNotCopied, FALSE) THEN BEGIN
                                    CopyFromSalesDocDimToLine(ToSalesLine, FromSalesLine);
                                    IF FromSalesLine.Type = FromSalesLine.Type::"Charge (Item)" THEN
                                        CopyFromSalesDocAssgntToLine(ToSalesLine, FromSalesLine, ItemChargeAssgntNextLineNo);
                                    //LS -
                                    IF (FromSalesLine."Retail Special Order") AND (FromSalesLine."Configuration ID" <> '') THEN BEGIN
                                        lConfigID := ToSalesLine."Document No." + '.' + FORMAT(ToSalesLine."Line No.");
                                        CopyOptionType(lConfigID, FromSalesLine."Configuration ID");
                                    END;
                                    //LS +
                                END;
                            UNTIL FromSalesLine.NEXT = 0;
                    END;
                SalesDocType::"Posted Shipment":
                    BEGIN
                        FromSalesHeader.TRANSFERFIELDS(FromSalesShptHeader);
                        FromSalesShptLine.RESET;
                        FromSalesShptLine.SETRANGE("Document No.", FromSalesShptHeader."No.");
                        IF MoveNegLines THEN
                            FromSalesShptLine.SETFILTER(Quantity, '<=0');
                        CopySalesShptLinesToDoc(ToSalesHeader, FromSalesShptLine, LinesNotCopied, MissingExCostRevLink);
                    END;
                SalesDocType::"Posted Invoice":
                    BEGIN
                        FromSalesHeader.TRANSFERFIELDS(FromSalesInvHeader);
                        FromSalesInvLine.RESET;
                        FromSalesInvLine.SETRANGE("Document No.", FromSalesInvHeader."No.");
                        IF MoveNegLines THEN
                            FromSalesInvLine.SETFILTER(Quantity, '<=0');
                        CopySalesInvLinesToDoc(ToSalesHeader, FromSalesInvLine, LinesNotCopied, MissingExCostRevLink);
                    END;
                SalesDocType::"Posted Return Receipt":
                    BEGIN
                        FromSalesHeader.TRANSFERFIELDS(FromReturnRcptHeader);
                        FromReturnRcptLine.RESET;
                        FromReturnRcptLine.SETRANGE("Document No.", FromReturnRcptHeader."No.");
                        IF MoveNegLines THEN
                            FromReturnRcptLine.SETFILTER(Quantity, '<=0');
                        CopySalesReturnRcptLinesToDoc(ToSalesHeader, FromReturnRcptLine, LinesNotCopied, MissingExCostRevLink);
                    END;
                SalesDocType::"Posted Credit Memo":
                    BEGIN
                        FromSalesHeader.TRANSFERFIELDS(FromSalesCrMemoHeader);
                        FromSalesCrMemoLine.RESET;
                        FromSalesCrMemoLine.SETRANGE("Document No.", FromSalesCrMemoHeader."No.");
                        IF MoveNegLines THEN
                            FromSalesCrMemoLine.SETFILTER(Quantity, '<=0');
                        CopySalesCrMemoLinesToDoc(ToSalesHeader, FromSalesCrMemoLine, LinesNotCopied, MissingExCostRevLink);
                    END;
            END;
        END;

        IF MoveNegLines THEN
            DeleteSalesLinesWithNegQty(FromSalesHeader, FALSE);

        //APNT-HRU2.0
        CLEAR(HRUCopyDocExtension);
        //HRUCopyDocExtension.CheckPostedQuantity(ToSalesHeader);
        //APNT-HRU2.0

        IF ReleaseDocument THEN BEGIN
            ToSalesHeader.Status := ToSalesHeader.Status::Released;
            ReleaseSalesDocument.Reopen(ToSalesHeader);
        END ELSE
            IF (FromDocType IN
     [SalesDocType::Quote,
      SalesDocType::"Blanket Order",
      SalesDocType::Order,
      SalesDocType::Invoice,
      SalesDocType::"Return Order",
      SalesDocType::"Credit Memo"])
      AND NOT IncludeHeader AND NOT RecalculateLines THEN
                IF FromSalesHeader.Status = FromSalesHeader.Status::Released THEN BEGIN
                    ReleaseSalesDocument.RUN(ToSalesHeader);
                    ReleaseSalesDocument.Reopen(ToSalesHeader);
                END;
        CASE TRUE OF
            MissingExCostRevLink AND (LinesNotCopied <> 0):
                MESSAGE(Text019 + Text020 + Text004);
            MissingExCostRevLink:
                MESSAGE(Text019);
            LinesNotCopied <> 0:
                MESSAGE(Text004);
        END;

    end;

    procedure CopyPurchDoc(FromDocType: Option; FromDocNo: Code[20]; var ToPurchHeader: Record "Purchase Header")
    var
        PaymentTerms: Record "Payment Terms";
        ToPurchLine: Record "Purchase Line";
        OldPurchHeader: Record "Purchase Header";
        FromPurchHeader: Record "Purchase Header";
        FromPurchLine: Record "Purchase Line";
        FromPurchRcptHeader: Record "Purch. Rcpt. Header";
        FromPurchRcptLine: Record "Purch. Rcpt. Line";
        FromPurchInvHeader: Record "Purch. Inv. Header";
        FromPurchInvLine: Record "Purch. Inv. Line";
        FromReturnShptHeader: Record "Return Shipment Header";
        FromReturnShptLine: Record "Return Shipment Line";
        FromPurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        FromPurchCrMemoLine: Record "Purch. Cr. Memo Line";
        DocDim: Record "Document Dimension";
        VendLedgEntry: Record "Vendor Ledger Entry";
        GLSetup: Record "General Ledger Setup";
        Vend: Record Vendor;
        NextLineNo: Integer;
        ItemChargeAssgntNextLineNo: Integer;
        LinesNotCopied: Integer;
        MissingExCostRevLink: Boolean;
        ReleasePurchaseDocument: Codeunit "415";
        ReleaseDocument: Boolean;
    begin
        WITH ToPurchHeader DO BEGIN
            IF NOT CreateToHeader THEN BEGIN
                TESTFIELD(Status, Status::Open);
                IF FromDocNo = '' THEN
                    ERROR(Text000);
                FIND;
            END;
            TransferOldExtLines.ClearLineNumbers;
            CASE FromDocType OF
                PurchDocType::Quote,
                PurchDocType::"Blanket Order",
                PurchDocType::Order,
                PurchDocType::Invoice,
                PurchDocType::"Return Order",
                PurchDocType::"Credit Memo":
                    BEGIN
                        FromPurchHeader.GET(PurchHeaderDocType(FromDocType), FromDocNo);
                        IF MoveNegLines THEN
                            DeletePurchLinesWithNegQty(FromPurchHeader, TRUE);
                        IF (FromPurchHeader."Document Type" = "Document Type") AND
                           (FromPurchHeader."No." = "No.")
                        THEN
                            ERROR(
                              Text001,
                              "Document Type", "No.");
                        IF NOT IncludeHeader AND NOT RecalculateLines THEN BEGIN
                            FromPurchHeader.TESTFIELD("Buy-from Vendor No.", "Buy-from Vendor No.");
                            FromPurchHeader.TESTFIELD("Pay-to Vendor No.", "Pay-to Vendor No.");
                            FromPurchHeader.TESTFIELD("Vendor Posting Group", "Vendor Posting Group");
                            FromPurchHeader.TESTFIELD("Gen. Bus. Posting Group", "Gen. Bus. Posting Group");
                            FromPurchHeader.TESTFIELD("Currency Code", "Currency Code");
                        END;
                    END;
                PurchDocType::"Posted Receipt":
                    BEGIN
                        FromPurchRcptHeader.GET(FromDocNo);
                        IF NOT IncludeHeader AND NOT RecalculateLines THEN BEGIN
                            FromPurchRcptHeader.TESTFIELD("Buy-from Vendor No.", "Buy-from Vendor No.");
                            FromPurchRcptHeader.TESTFIELD("Pay-to Vendor No.", "Pay-to Vendor No.");
                            FromPurchRcptHeader.TESTFIELD("Vendor Posting Group", "Vendor Posting Group");
                            FromPurchRcptHeader.TESTFIELD("Gen. Bus. Posting Group", "Gen. Bus. Posting Group");
                            FromPurchRcptHeader.TESTFIELD("Currency Code", "Currency Code");
                        END;
                    END;
                PurchDocType::"Posted Invoice":
                    BEGIN
                        FromPurchInvHeader.GET(FromDocNo);
                        FromPurchInvHeader.TESTFIELD("Prepayment Invoice", FALSE);
                        WarnPurchInvoicePmtDisc(ToPurchHeader, FromPurchHeader, FromDocType, FromDocNo);
                        IF NOT IncludeHeader AND NOT RecalculateLines THEN BEGIN
                            FromPurchInvHeader.TESTFIELD("Buy-from Vendor No.", "Buy-from Vendor No.");
                            FromPurchInvHeader.TESTFIELD("Pay-to Vendor No.", "Pay-to Vendor No.");
                            FromPurchInvHeader.TESTFIELD("Vendor Posting Group", "Vendor Posting Group");
                            FromPurchInvHeader.TESTFIELD("Gen. Bus. Posting Group", "Gen. Bus. Posting Group");
                            FromPurchInvHeader.TESTFIELD("Currency Code", "Currency Code");
                        END;
                    END;
                PurchDocType::"Posted Return Shipment":
                    BEGIN
                        FromReturnShptHeader.GET(FromDocNo);
                        IF NOT IncludeHeader AND NOT RecalculateLines THEN BEGIN
                            FromReturnShptHeader.TESTFIELD("Buy-from Vendor No.", "Buy-from Vendor No.");
                            FromReturnShptHeader.TESTFIELD("Pay-to Vendor No.", "Pay-to Vendor No.");
                            FromReturnShptHeader.TESTFIELD("Vendor Posting Group", "Vendor Posting Group");
                            FromReturnShptHeader.TESTFIELD("Gen. Bus. Posting Group", "Gen. Bus. Posting Group");
                            FromReturnShptHeader.TESTFIELD("Currency Code", "Currency Code");
                        END;
                    END;
                PurchDocType::"Posted Credit Memo":
                    BEGIN
                        FromPurchCrMemoHeader.GET(FromDocNo);
                        WarnPurchInvoicePmtDisc(ToPurchHeader, FromPurchHeader, FromDocType, FromDocNo);
                        IF NOT IncludeHeader AND NOT RecalculateLines THEN BEGIN
                            FromPurchCrMemoHeader.TESTFIELD("Buy-from Vendor No.", "Buy-from Vendor No.");
                            FromPurchCrMemoHeader.TESTFIELD("Pay-to Vendor No.", "Pay-to Vendor No.");
                            FromPurchCrMemoHeader.TESTFIELD("Vendor Posting Group", "Vendor Posting Group");
                            FromPurchCrMemoHeader.TESTFIELD("Gen. Bus. Posting Group", "Gen. Bus. Posting Group");
                            FromPurchCrMemoHeader.TESTFIELD("Currency Code", "Currency Code");
                        END;
                    END;
            END;

            DocDim.LOCKTABLE;
            ToPurchLine.LOCKTABLE;

            IF CreateToHeader THEN BEGIN
                INSERT(TRUE);
                ToPurchLine.SETRANGE("Document Type", "Document Type");
                ToPurchLine.SETRANGE("Document No.", "No.");
            END ELSE BEGIN
                ToPurchLine.SETRANGE("Document Type", "Document Type");
                ToPurchLine.SETRANGE("Document No.", "No.");
                IF IncludeHeader THEN BEGIN
                    IF ToPurchLine.FIND('-') THEN BEGIN
                        COMMIT;
                        IF NOT
                           CONFIRM(
                             Text002 +
                             Text003, TRUE,
                             "Document Type", "No.")
                        THEN
                            EXIT;
                        ToPurchLine.DELETEALL(TRUE);
                    END;
                END;
            END;

            IF ToPurchLine.FIND('+') THEN
                NextLineNo := ToPurchLine."Line No."
            ELSE
                NextLineNo := 0;

            IF NOT RECORDLEVELLOCKING THEN
                LOCKTABLE(TRUE, TRUE);

            IF IncludeHeader THEN BEGIN
                IF Vend.GET(FromPurchHeader."Buy-from Vendor No.") THEN
                    Vend.CheckBlockedVendOnDocs(Vend, FALSE);
                IF Vend.GET(FromPurchHeader."Pay-to Vendor No.") THEN
                    Vend.CheckBlockedVendOnDocs(Vend, FALSE);
                OldPurchHeader := ToPurchHeader;
                CASE FromDocType OF
                    PurchDocType::Quote,
                    PurchDocType::"Blanket Order",
                    PurchDocType::Order,
                    PurchDocType::Invoice,
                    PurchDocType::"Return Order",
                    PurchDocType::"Credit Memo":
                        BEGIN
                            TRANSFERFIELDS(FromPurchHeader, FALSE);
                            IF "Document Type" <> "Document Type"::Order THEN
                                "Prepayment %" := 0;
                            IF FromDocType IN [PurchDocType::Quote, PurchDocType::"Blanket Order"] THEN
                                IF OldPurchHeader."Posting Date" = 0D THEN
                                    "Posting Date" := WORKDATE
                                ELSE
                                    "Posting Date" := OldPurchHeader."Posting Date";
                            CopyFromPurchDocDimToHeader(ToPurchHeader, FromPurchHeader);
                        END;
                    PurchDocType::"Posted Receipt":
                        BEGIN
                            ToPurchHeader.VALIDATE("Buy-from Vendor No.", FromPurchRcptHeader."Buy-from Vendor No.");
                            TRANSFERFIELDS(FromPurchRcptHeader, FALSE);
                            CopyFromPstdPurchDocDimToHdr(
                              ToPurchHeader, FromDocType, FromPurchRcptHeader, FromPurchInvHeader,
                              FromReturnShptHeader, FromPurchCrMemoHeader);
                        END;
                    PurchDocType::"Posted Invoice":
                        BEGIN
                            ToPurchHeader.VALIDATE("Buy-from Vendor No.", FromPurchInvHeader."Buy-from Vendor No.");
                            TRANSFERFIELDS(FromPurchInvHeader, FALSE);
                            CopyFromPstdPurchDocDimToHdr(
                              ToPurchHeader, FromDocType, FromPurchRcptHeader, FromPurchInvHeader,
                              FromReturnShptHeader, FromPurchCrMemoHeader);
                        END;
                    PurchDocType::"Posted Return Shipment":
                        BEGIN
                            ToPurchHeader.VALIDATE("Buy-from Vendor No.", FromReturnShptHeader."Buy-from Vendor No.");
                            TRANSFERFIELDS(FromReturnShptHeader, FALSE);
                            CopyFromPstdPurchDocDimToHdr(
                              ToPurchHeader, FromDocType, FromPurchRcptHeader, FromPurchInvHeader,
                              FromReturnShptHeader, FromPurchCrMemoHeader);
                        END;
                    PurchDocType::"Posted Credit Memo":
                        BEGIN
                            ToPurchHeader.VALIDATE("Buy-from Vendor No.", FromPurchCrMemoHeader."Buy-from Vendor No.");
                            TRANSFERFIELDS(FromPurchCrMemoHeader, FALSE);
                            CopyFromPstdPurchDocDimToHdr(
                              ToPurchHeader, FromDocType, FromPurchRcptHeader, FromPurchInvHeader,
                              FromReturnShptHeader, FromPurchCrMemoHeader);
                        END;
                END;
                IF Status = Status::Released THEN BEGIN
                    Status := Status::Open;
                    ReleaseDocument := TRUE;
                END;
                IF MoveNegLines OR IncludeHeader THEN
                    ToPurchHeader.VALIDATE("Location Code");
                IF MoveNegLines THEN
                    VALIDATE("Order Address Code");

                "No. Series" := OldPurchHeader."No. Series";
                "Posting Description" := OldPurchHeader."Posting Description";
                "Posting No." := OldPurchHeader."Posting No.";
                "Posting No. Series" := OldPurchHeader."Posting No. Series";
                "Receiving No." := OldPurchHeader."Receiving No.";
                "Receiving No. Series" := OldPurchHeader."Receiving No. Series";
                "Return Shipment No." := OldPurchHeader."Return Shipment No.";
                "Return Shipment No. Series" := OldPurchHeader."Return Shipment No. Series";
                "Prepayment No. Series" := OldPurchHeader."Prepayment No. Series";
                "Prepayment No." := OldPurchHeader."Prepayment No.";
                "Prepmt. Posting Description" := OldPurchHeader."Prepmt. Posting Description";
                "Prepmt. Cr. Memo No. Series" := OldPurchHeader."Prepmt. Cr. Memo No. Series";
                "Prepmt. Cr. Memo No." := OldPurchHeader."Prepmt. Cr. Memo No.";
                "Prepmt. Posting Description" := OldPurchHeader."Prepmt. Posting Description";
                "No. Printed" := 0;
                //T015451 -
                "WMS Exported" := FALSE;
                //"WMS Customer Export" := FALSE;      //WMS LALS 1.1
                //"WMS Update SO"      :=  FALSE;      //WMS LALS 1.1
                //T015451 +

                "Applies-to Doc. Type" := "Applies-to Doc. Type"::" ";
                "Applies-to Doc. No." := '';
                "Applies-to ID" := '';
                ClearPurchBizTalkFields(ToPurchHeader);
                IF ((FromDocType = PurchDocType::"Posted Invoice") AND
                    ("Document Type" IN ["Document Type"::"Return Order", "Document Type"::"Credit Memo"])) OR
                   ((FromDocType = PurchDocType::"Posted Credit Memo") AND
                    NOT ("Document Type" IN ["Document Type"::"Return Order", "Document Type"::"Credit Memo"]))
                THEN BEGIN
                    VendLedgEntry.SETCURRENTKEY("Document No.");
                    IF FromDocType = PurchDocType::"Posted Invoice" THEN
                        VendLedgEntry.SETRANGE("Document Type", VendLedgEntry."Document Type"::Invoice)
                    ELSE
                        VendLedgEntry.SETRANGE("Document Type", VendLedgEntry."Document Type"::"Credit Memo");
                    VendLedgEntry.SETRANGE("Document No.", FromDocNo);
                    VendLedgEntry.SETRANGE("Vendor No.", "Pay-to Vendor No.");
                    VendLedgEntry.SETRANGE(Open, TRUE);
                    IF VendLedgEntry.FIND('-') THEN BEGIN
                        IF FromDocType = PurchDocType::"Posted Invoice" THEN BEGIN
                            "Applies-to Doc. Type" := "Applies-to Doc. Type"::Invoice;
                            "Applies-to Doc. No." := FromDocNo;
                        END ELSE BEGIN
                            "Applies-to Doc. Type" := "Applies-to Doc. Type"::"Credit Memo";
                            "Applies-to Doc. No." := FromDocNo;
                        END;
                        VendLedgEntry.CALCFIELDS("Remaining Amount");
                        VendLedgEntry."Amount to Apply" := VendLedgEntry."Remaining Amount";
                        VendLedgEntry."Accepted Payment Tolerance" := 0;
                        VendLedgEntry."Accepted Pmt. Disc. Tolerance" := FALSE;
                        CODEUNIT.RUN(CODEUNIT::"Vend. Entry-Edit", VendLedgEntry);
                    END;
                END;

                IF "Document Type" IN ["Document Type"::"Blanket Order", "Document Type"::Quote] THEN
                    "Posting Date" := 0D;

                Correction := FALSE;
                IF "Document Type" IN ["Document Type"::"Return Order", "Document Type"::"Credit Memo"] THEN BEGIN
                    "Expected Receipt Date" := 0D;
                    GLSetup.GET;
                    Correction := GLSetup."Mark Cr. Memos as Corrections";
                    IF ("Payment Terms Code" <> '') AND ("Document Date" <> 0D) THEN
                        PaymentTerms.GET("Payment Terms Code")
                    ELSE
                        CLEAR(PaymentTerms);
                    IF NOT PaymentTerms."Calc. Pmt. Disc. on Cr. Memos" THEN BEGIN
                        "Payment Terms Code" := '';
                        "Due Date" := 0D;
                        "Payment Discount %" := 0;
                        "Pmt. Discount Date" := 0D;
                    END;
                END;

                IF CreateToHeader THEN BEGIN
                    VALIDATE("Payment Terms Code");
                    MODIFY(TRUE);
                END ELSE
                    MODIFY;
            END;

            LinesNotCopied := 0;
            CASE FromDocType OF
                PurchDocType::Quote,
                PurchDocType::"Blanket Order",
                PurchDocType::Order,
                PurchDocType::Invoice,
                PurchDocType::"Return Order",
                PurchDocType::"Credit Memo":
                    BEGIN
                        ItemChargeAssgntNextLineNo := 0;
                        FromPurchLine.RESET;
                        FromPurchLine.SETRANGE("Document Type", FromPurchHeader."Document Type");
                        FromPurchLine.SETRANGE("Document No.", FromPurchHeader."No.");
                        IF MoveNegLines THEN
                            FromPurchLine.SETFILTER(Quantity, '<=0');
                        IF FromPurchLine.FIND('-') THEN
                            REPEAT
                                IF CopyPurchLine(
                                  ToPurchHeader, ToPurchLine, FromPurchHeader, FromPurchLine,
                                  NextLineNo, LinesNotCopied, FALSE)
                                THEN BEGIN
                                    CopyFromPurchDocDimToLine(ToPurchLine, FromPurchLine);
                                    IF FromPurchLine.Type = FromPurchLine.Type::"Charge (Item)" THEN
                                        CopyFromPurchDocAssgntToLine(ToPurchLine, FromPurchLine, ItemChargeAssgntNextLineNo);
                                END;
                            UNTIL FromPurchLine.NEXT = 0;
                    END;
                PurchDocType::"Posted Receipt":
                    BEGIN
                        FromPurchHeader.TRANSFERFIELDS(FromPurchRcptHeader);
                        FromPurchRcptLine.RESET;
                        FromPurchRcptLine.SETRANGE("Document No.", FromPurchRcptHeader."No.");
                        IF MoveNegLines THEN
                            FromPurchRcptLine.SETFILTER(Quantity, '<=0');
                        CopyPurchRcptLinesToDoc(ToPurchHeader, FromPurchRcptLine, LinesNotCopied, MissingExCostRevLink);
                    END;
                PurchDocType::"Posted Invoice":
                    BEGIN
                        FromPurchHeader.TRANSFERFIELDS(FromPurchInvHeader);
                        FromPurchInvLine.RESET;
                        FromPurchInvLine.SETRANGE("Document No.", FromPurchInvHeader."No.");
                        IF MoveNegLines THEN
                            FromPurchInvLine.SETFILTER(Quantity, '<=0');
                        CopyPurchInvLinesToDoc(ToPurchHeader, FromPurchInvLine, LinesNotCopied, MissingExCostRevLink);
                    END;
                PurchDocType::"Posted Return Shipment":
                    BEGIN
                        FromPurchHeader.TRANSFERFIELDS(FromReturnShptHeader);
                        FromReturnShptLine.RESET;
                        FromReturnShptLine.SETRANGE("Document No.", FromReturnShptHeader."No.");
                        IF MoveNegLines THEN
                            FromReturnShptLine.SETFILTER(Quantity, '<=0');
                        CopyPurchReturnShptLinesToDoc(ToPurchHeader, FromReturnShptLine, LinesNotCopied, MissingExCostRevLink);
                    END;
                PurchDocType::"Posted Credit Memo":
                    BEGIN
                        FromPurchHeader.TRANSFERFIELDS(FromPurchCrMemoHeader);
                        FromPurchCrMemoLine.RESET;
                        FromPurchCrMemoLine.SETRANGE("Document No.", FromPurchCrMemoHeader."No.");
                        IF MoveNegLines THEN
                            FromPurchCrMemoLine.SETFILTER(Quantity, '<=0');
                        CopyPurchCrMemoLinesToDoc(ToPurchHeader, FromPurchCrMemoLine, LinesNotCopied, MissingExCostRevLink);
                    END;
            END;
        END;

        IF MoveNegLines THEN
            DeletePurchLinesWithNegQty(FromPurchHeader, FALSE);

        IF ReleaseDocument THEN BEGIN
            ToPurchHeader.Status := ToPurchHeader.Status::Released;
            ReleasePurchaseDocument.Reopen(ToPurchHeader);
        END ELSE
            IF (FromDocType IN
     [PurchDocType::Quote,
      PurchDocType::"Blanket Order",
      PurchDocType::Order,
      PurchDocType::Invoice,
      PurchDocType::"Return Order",
      PurchDocType::"Credit Memo"])
      AND NOT IncludeHeader AND NOT RecalculateLines THEN
                IF FromPurchHeader.Status = FromPurchHeader.Status::Released THEN BEGIN
                    ReleasePurchaseDocument.RUN(ToPurchHeader);
                    ReleasePurchaseDocument.Reopen(ToPurchHeader);
                END;


        CASE TRUE OF
            MissingExCostRevLink AND (LinesNotCopied <> 0):
                MESSAGE(Text019 + Text020 + Text004);
            MissingExCostRevLink:
                MESSAGE(Text019);
            LinesNotCopied <> 0:
                MESSAGE(Text004);
        END;
    end;

    procedure ShowSalesDoc(ToSalesHeader: Record "Sales Header")
    begin
        WITH ToSalesHeader DO BEGIN
            CASE "Document Type" OF
                "Document Type"::Order:
                    FORM.RUN(FORM::"Sales Order", ToSalesHeader);
                "Document Type"::Invoice:
                    FORM.RUN(FORM::"Sales Invoice", ToSalesHeader);
                "Document Type"::"Return Order":
                    FORM.RUN(FORM::"Sales Return Order", ToSalesHeader);
                "Document Type"::"Credit Memo":
                    FORM.RUN(FORM::"Sales Credit Memo", ToSalesHeader);
            END;
        END;
    end;

    procedure ShowPurchDoc(ToPurchHeader: Record "Purchase Header")
    begin
        WITH ToPurchHeader DO BEGIN
            CASE "Document Type" OF
                "Document Type"::Order:
                    FORM.RUN(FORM::"Purchase Order", ToPurchHeader);
                "Document Type"::Invoice:
                    FORM.RUN(FORM::"Purchase Invoice", ToPurchHeader);
                "Document Type"::"Return Order":
                    FORM.RUN(FORM::"Purchase Return Order", ToPurchHeader);
                "Document Type"::"Credit Memo":
                    FORM.RUN(FORM::"Purchase Credit Memo", ToPurchHeader);
            END;
        END;
    end;

    procedure CopyFromSalesToPurchDoc(VendorNo: Code[20]; FromSalesHeader: Record "Sales Header"; var ToPurchHeader: Record "Purchase Header")
    var
        FromSalesLine: Record "Sales Line";
        ToPurchLine: Record "Purchase Line";
        NextLineNo: Integer;
    begin
        IF VendorNo = '' THEN
            ERROR(Text011);

        WITH ToPurchLine DO BEGIN
            LOCKTABLE;
            ToPurchHeader.INSERT(TRUE);
            ToPurchHeader.VALIDATE("Buy-from Vendor No.", VendorNo);
            ToPurchHeader.MODIFY(TRUE);
            FromSalesLine.SETRANGE("Document Type", FromSalesHeader."Document Type");
            FromSalesLine.SETRANGE("Document No.", FromSalesHeader."No.");
            IF NOT FromSalesLine.FIND('-') THEN
                ERROR(Text012);
            REPEAT
                NextLineNo := NextLineNo + 10000;
                CLEAR(ToPurchLine);
                INIT;
                "Document Type" := ToPurchHeader."Document Type";
                "Document No." := ToPurchHeader."No.";
                IF FromSalesLine.Type = FromSalesLine.Type::" " THEN
                    Description := FromSalesLine.Description
                ELSE
                    TransfldsFromSalesToPurchLine(FromSalesLine, ToPurchLine);
                "Line No." := NextLineNo;
                INSERT(TRUE);
            UNTIL FromSalesLine.NEXT = 0;
        END;
    end;

    procedure TransfldsFromSalesToPurchLine(var FromSalesLine: Record "Sales Line"; var ToPurchLine: Record "Purchase Line")
    begin
        WITH ToPurchLine DO BEGIN
            VALIDATE(Type, FromSalesLine.Type);
            VALIDATE("No.", FromSalesLine."No.");
            VALIDATE("Variant Code", FromSalesLine."Variant Code");
            VALIDATE("Location Code", FromSalesLine."Location Code");
            VALIDATE("Unit of Measure Code", FromSalesLine."Unit of Measure Code");
            IF (Type = Type::Item) AND ("No." <> '') THEN
                UpdateUOMQtyPerStockQty;
            "Expected Receipt Date" := FromSalesLine."Shipment Date";
            "Bin Code" := FromSalesLine."Bin Code";
            VALIDATE(Quantity, FromSalesLine."Outstanding Quantity");
            VALIDATE("Return Reason Code", FromSalesLine."Return Reason Code");
            VALIDATE("Direct Unit Cost");
        END;
    end;

    local procedure DeleteSalesLinesWithNegQty(FromSalesHeader: Record "Sales Header"; OnlyTest: Boolean)
    var
        FromSalesLine: Record "Sales Line";
    begin
        WITH FromSalesLine DO BEGIN
            SETRANGE("Document Type", FromSalesHeader."Document Type");
            SETRANGE("Document No.", FromSalesHeader."No.");
            SETFILTER(Quantity, '<0');
            IF OnlyTest THEN BEGIN
                IF NOT FIND('-') THEN
                    ERROR(Text008);
                REPEAT
                    TESTFIELD("Shipment No.", '');
                    TESTFIELD("Return Receipt No.", '');
                    TESTFIELD("Quantity Shipped", 0);
                    TESTFIELD("Quantity Invoiced", 0);
                UNTIL NEXT = 0;
            END ELSE
                DELETEALL(TRUE);
        END;
    end;

    local procedure DeletePurchLinesWithNegQty(FromPurchHeader: Record "Purchase Header"; OnlyTest: Boolean)
    var
        FromPurchLine: Record "Purchase Line";
    begin
        WITH FromPurchLine DO BEGIN
            SETRANGE("Document Type", FromPurchHeader."Document Type");
            SETRANGE("Document No.", FromPurchHeader."No.");
            SETFILTER(Quantity, '<0');
            IF OnlyTest THEN BEGIN
                IF NOT FIND('-') THEN
                    ERROR(Text010);
                REPEAT
                    TESTFIELD("Receipt No.", '');
                    TESTFIELD("Return Shipment No.", '');
                    TESTFIELD("Quantity Received", 0);
                    TESTFIELD("Quantity Invoiced", 0);
                UNTIL NEXT = 0;
            END ELSE
                DELETEALL(TRUE);
        END;
    end;

    local procedure CopySalesLine(var ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; var FromSalesHeader: Record "Sales Header"; var FromSalesLine: Record "Sales Line"; var NextLineNo: Integer; var LinesNotCopied: Integer; RecalculateAmount: Boolean): Boolean
    var
        GLAcc: Record "G/L Account";
        ToSalesLine2: Record "Sales Line";
        CopyThisLine: Boolean;
        StandardText: Record "Standard Text";
    begin
        CopyThisLine := TRUE;
        //LS-
        /*
        IF ((ToSalesHeader."Language Code" <> FromSalesHeader."Language Code") OR RecalculateLines) AND
           (FromSalesLine."Attached to Line No." <> 0) OR
           FromSalesLine."Prepayment Line"
        */
        IF ((ToSalesHeader."Language Code" <> FromSalesHeader."Language Code") OR RecalculateLines) AND
           ((FromSalesLine."Attached to Line No." <> 0) OR
           FromSalesLine."Prepayment Line") AND
           (FromSalesLine."Posting Group" = '')
        //LS +
        THEN
            EXIT(FALSE);
        ToSalesLine.SetSalesHeader(ToSalesHeader);
        IF RecalculateLines AND NOT FromSalesLine."System-Created Entry" THEN
            ToSalesLine.INIT
        ELSE
            ToSalesLine := FromSalesLine;
        NextLineNo := NextLineNo + 10000;
        ToSalesLine."Document Type" := ToSalesHeader."Document Type";
        ToSalesLine."Document No." := ToSalesHeader."No.";
        ToSalesLine."Line No." := NextLineNo;
        ToSalesLine.VALIDATE("Currency Code", FromSalesHeader."Currency Code");
        //HRU1.0 -
        IF ToSalesHeader."HRU Document" THEN BEGIN
            ToSalesLine."SO Line Reversed" := FALSE;
            ToSalesLine."Transfer Order No." := '';
            ToSalesLine."Transfer Order Line No." := 0;
        END;
        //HRU1.0 +
        IF RecalculateLines AND NOT FromSalesLine."System-Created Entry" THEN BEGIN
            ToSalesLine.VALIDATE(Type, FromSalesLine.Type);
            ToSalesLine.VALIDATE(Description, FromSalesLine.Description);
            ToSalesLine.VALIDATE("Description 2", FromSalesLine."Description 2");
            IF (FromSalesLine.Type <> 0) AND (FromSalesLine."No." <> '') THEN BEGIN
                IF ToSalesLine.Type = ToSalesLine.Type::"G/L Account" THEN BEGIN
                    ToSalesLine."No." := FromSalesLine."No.";
                    IF GLAcc."No." <> FromSalesLine."No." THEN
                        GLAcc.GET(FromSalesLine."No.");
                    CopyThisLine := GLAcc."Direct Posting";
                    IF CopyThisLine THEN
                        ToSalesLine.VALIDATE("No.", FromSalesLine."No.");
                END ELSE
                    ToSalesLine.VALIDATE("No.", FromSalesLine."No.");
                ToSalesLine.VALIDATE("Variant Code", FromSalesLine."Variant Code");
                ToSalesLine.VALIDATE("Location Code", FromSalesLine."Location Code");
                ToSalesLine.VALIDATE("Unit of Measure", FromSalesLine."Unit of Measure");
                ToSalesLine.VALIDATE("Unit of Measure Code", FromSalesLine."Unit of Measure Code");
                ToSalesLine.VALIDATE(Quantity, FromSalesLine.Quantity);
                IF NOT (FromSalesLine.Type IN [FromSalesLine.Type::Item, FromSalesLine.Type::Resource]) THEN BEGIN
                    IF (FromSalesHeader."Currency Code" <> ToSalesHeader."Currency Code") OR
                       (FromSalesHeader."Prices Including VAT" <> ToSalesHeader."Prices Including VAT")
                    THEN BEGIN
                        ToSalesLine."Unit Price" := 0;
                        ToSalesLine."Line Discount %" := 0;
                    END ELSE BEGIN
                        ToSalesLine.VALIDATE("Unit Price", FromSalesLine."Unit Price");
                        ToSalesLine.VALIDATE("Line Discount %", FromSalesLine."Line Discount %");
                    END;
                    IF ToSalesLine.Quantity <> 0 THEN
                        ToSalesLine.VALIDATE("Line Discount Amount", FromSalesLine."Line Discount Amount");
                END;
                ToSalesLine.VALIDATE("Work Type Code", FromSalesLine."Work Type Code");
                IF (ToSalesLine."Document Type" = ToSalesLine."Document Type"::Order) AND
                   (FromSalesLine."Purchasing Code" <> '')
                THEN
                    ToSalesLine.VALIDATE("Purchasing Code", FromSalesLine."Purchasing Code");
            END;
            IF (FromSalesLine.Type = FromSalesLine.Type::" ") AND (FromSalesLine."No." <> '') THEN
                //LS Start
                //ToSalesLine.VALIDATE("No.",FromSalesLine."No.");
                IF StandardText.GET(FromSalesLine."No.") THEN
                    ToSalesLine.VALIDATE("No.", FromSalesLine."No.")
                ELSE BEGIN
                    ToSalesLine."No." := FromSalesLine."No.";
                    ToSalesLine."Location Code" := FromSalesLine."Location Code";
                    ToSalesLine."Unit of Measure Code" := FromSalesLine."Unit of Measure Code";
                    LastVariantSumLineNo := ToSalesLine."Line No.";
                END;
            IF FromSalesLine."Retail Special Order" THEN
                CopySalesLineSPOAddInfo(ToSalesLine, FromSalesLine);
            //LS +
            //DP6.01.01 START
            IF FromSalesHeader."Agreement Invoice/Cr Memo" THEN BEGIN
                ToSalesLine."Ref. Document Type" := FromSalesLine."Ref. Document Type";
                ToSalesLine."Ref. Document No." := FromSalesLine."Ref. Document No.";
                ToSalesLine."Ref. Document Line No." := FromSalesLine."Ref. Document Line No.";
                ToSalesLine."Element Type" := FromSalesLine."Element Type";
                ToSalesLine."Rental Element" := FromSalesLine."Rental Element";
                ToSalesLine."Agreement Due Date" := FromSalesLine."Agreement Due Date";
            END;
            //DP6.01.01 STOP
        END ELSE BEGIN
            IF ToSalesLine."Document Type" <> ToSalesLine."Document Type"::Order THEN BEGIN
                ToSalesLine."Prepayment %" := 0;
                ToSalesLine."Prepayment VAT %" := 0;
                ToSalesLine."Prepmt. VAT Calc. Type" := 0;
                ToSalesLine."Prepayment VAT Identifier" := '';
                ToSalesLine."Prepayment VAT %" := 0;
                ToSalesLine."Prepayment Tax Group Code" := '';
                ToSalesLine."Prepmt. Line Amount" := 0;
                ToSalesLine."Prepmt. Amt. Incl. VAT" := 0;
            END;
            ToSalesLine."Prepmt. Amt. Inv." := 0;
            ToSalesLine."Prepayment Amount" := 0;
            ToSalesLine."Prepmt. VAT Base Amt." := 0;
            ToSalesLine."Prepmt Amt to Deduct" := 0;
            ToSalesLine."Prepmt Amt Deducted" := 0;
            ToSalesLine."Prepmt. Amount Inv. Incl. VAT" := 0;
            ToSalesLine."Prepayment VAT Difference" := 0;
            ToSalesLine."Prepmt VAT Diff. to Deduct" := 0;
            ToSalesLine."Prepmt VAT Diff. Deducted" := 0;
            ToSalesLine."Quantity Shipped" := 0;
            ToSalesLine."Qty. Shipped (Base)" := 0;
            ToSalesLine."Return Qty. Received" := 0;
            ToSalesLine."Return Qty. Received (Base)" := 0;
            ToSalesLine."Quantity Invoiced" := 0;
            ToSalesLine."Qty. Invoiced (Base)" := 0;
            ToSalesLine."Reserved Quantity" := 0;
            ToSalesLine."Reserved Qty. (Base)" := 0;
            ToSalesLine."Qty. to Ship" := 0;
            ToSalesLine."Qty. to Ship (Base)" := 0;
            ToSalesLine."Return Qty. to Receive" := 0;
            ToSalesLine."Return Qty. to Receive (Base)" := 0;
            ToSalesLine."Qty. to Invoice" := 0;
            ToSalesLine."Qty. to Invoice (Base)" := 0;
            ToSalesLine."Qty. Shipped Not Invoiced" := 0;
            ToSalesLine."Return Qty. Rcd. Not Invd." := 0;
            ToSalesLine."Shipped Not Invoiced" := 0;
            ToSalesLine."Return Rcd. Not Invd." := 0;
            ToSalesLine."Qty. Shipped Not Invd. (Base)" := 0;
            ToSalesLine."Ret. Qty. Rcd. Not Invd.(Base)" := 0;
            ToSalesLine."Shipped Not Invoiced (LCY)" := 0;
            ToSalesLine."Return Rcd. Not Invd. (LCY)" := 0;
            ToSalesLine."Job No." := '';
            ToSalesLine."Job Task No." := '';
            ToSalesLine."Job Contract Entry No." := 0;
            ToSalesLine."Configuration ID" := ToSalesLine."Document No." + '.' + FORMAT(ToSalesLine."Line No.");  //LS

            ToSalesLine.InitOutstanding;
            IF ToSalesLine."Document Type" IN
               [ToSalesLine."Document Type"::"Return Order", ToSalesLine."Document Type"::"Credit Memo"]
            THEN
                ToSalesLine.InitQtyToReceive
            ELSE
                ToSalesLine.InitQtyToShip;
            ToSalesLine."VAT Difference" := FromSalesLine."VAT Difference";
            IF NOT CreateToHeader THEN
                ToSalesLine."Shipment Date" := ToSalesHeader."Shipment Date";
            ToSalesLine."Appl.-from Item Entry" := 0;
            ToSalesLine."Appl.-to Item Entry" := 0;

            ToSalesLine."Purchase Order No." := '';
            ToSalesLine."Purch. Order Line No." := 0;
            ToSalesLine."Special Order Purchase No." := '';
            ToSalesLine."Special Order Purch. Line No." := 0;
            IF ToSalesLine."Document Type" <> ToSalesLine."Document Type"::Order THEN BEGIN
                ToSalesLine."Drop Shipment" := FALSE;
                ToSalesLine."Special Order" := FALSE;
            END;
            IF RecalculateAmount AND (FromSalesLine."Appl.-from Item Entry" = 0) THEN BEGIN
                ToSalesLine.VALIDATE("Line Discount %", FromSalesLine."Line Discount %");
                ToSalesLine.VALIDATE(
                  "Inv. Discount Amount",
                  ROUND(FromSalesLine."Inv. Discount Amount", Currency."Amount Rounding Precision"));
                ToSalesLine.VALIDATE("Unit Cost (LCY)", FromSalesLine."Unit Cost (LCY)");
            END;

            ToSalesLine.UpdateWithWarehouseShip;
            IF (ToSalesLine.Type = ToSalesLine.Type::Item) AND (ToSalesLine."No." <> '') THEN BEGIN
                GetItem(ToSalesLine."No.");
                IF (Item."Costing Method" = Item."Costing Method"::Standard) AND NOT ToSalesLine.IsShipment THEN
                    ToSalesLine.GetUnitCost;

                IF Item.Reserve = Item.Reserve::Optional THEN
                    ToSalesLine.Reserve := ToSalesHeader.Reserve
                ELSE
                    ToSalesLine.Reserve := Item.Reserve;
                IF ToSalesLine.Reserve = ToSalesLine.Reserve::Always THEN
                    IF ToSalesHeader."Shipment Date" <> 0D THEN
                        ToSalesLine."Shipment Date" := ToSalesHeader."Shipment Date"
                    ELSE
                        ToSalesLine."Shipment Date" := WORKDATE;
            END;

        END;

        IF ExactCostRevMandatory AND
           (FromSalesLine.Type = FromSalesLine.Type::Item) AND
           (FromSalesLine."Appl.-from Item Entry" <> 0) AND
           NOT MoveNegLines
        THEN BEGIN
            IF RecalculateAmount THEN BEGIN
                ToSalesLine.VALIDATE("Unit Price", FromSalesLine."Unit Price");
                ToSalesLine.VALIDATE(
                  "Line Discount Amount",
                  ROUND(FromSalesLine."Line Discount Amount", Currency."Amount Rounding Precision"));
                ToSalesLine.VALIDATE(
                  "Inv. Discount Amount",
                  ROUND(FromSalesLine."Inv. Discount Amount", Currency."Amount Rounding Precision"));
            END;
            ToSalesLine.VALIDATE("Appl.-from Item Entry", FromSalesLine."Appl.-from Item Entry");
            IF NOT CreateToHeader THEN
                IF ToSalesLine."Shipment Date" = 0D THEN BEGIN
                    IF ToSalesHeader."Shipment Date" <> 0D THEN
                        ToSalesLine."Shipment Date" := ToSalesHeader."Shipment Date"
                    ELSE
                        ToSalesLine."Shipment Date" := WORKDATE;
                END;
        END;

        IF MoveNegLines AND (ToSalesLine.Type <> ToSalesLine.Type::" ") THEN BEGIN
            ToSalesLine.VALIDATE(Quantity, -FromSalesLine.Quantity);
            ToSalesLine.VALIDATE("Line Discount %", FromSalesLine."Line Discount %");
            ToSalesLine."Appl.-to Item Entry" := FromSalesLine."Appl.-to Item Entry";
            ToSalesLine."Appl.-from Item Entry" := FromSalesLine."Appl.-from Item Entry";
        END;

        IF (ToSalesHeader."Language Code" <> FromSalesHeader."Language Code") OR RecalculateLines THEN BEGIN
            IF TransferExtendedText.SalesCheckIfAnyExtText(ToSalesLine, FALSE) THEN BEGIN
                TransferExtendedText.InsertSalesExtText(ToSalesLine);
                ToSalesLine2.SETRANGE("Document Type", ToSalesLine."Document Type");
                ToSalesLine2.SETRANGE("Document No.", ToSalesLine."Document No.");
                ToSalesLine2.FIND('+');
                NextLineNo := ToSalesLine2."Line No.";
            END;
        END ELSE
            ToSalesLine."Attached to Line No." :=
              TransferOldExtLines.TransferExtendedText(
                FromSalesLine."Line No.",
                NextLineNo,
                FromSalesLine."Attached to Line No.");

        //LS Start
        IF (FromSalesLine."Attached to Line No." <> 0) AND
           (ToSalesLine."Attached to Line No." = 0) AND
           (ToSalesLine."Variant Code" <> '') AND
           (LastVariantSumLineNo <> 0)
        THEN
            ToSalesLine."Attached to Line No." := LastVariantSumLineNo;
        //LS Stop

        //T007735
        IF ToSalesHeader."HRU Document" THEN BEGIN
            ToSalesLine."Ref. Document Type" := ToSalesLine."Ref. Document Type"::Sale;
            ToSalesLine."Ref. Document No." := FromSalesLine."Document No.";
            ToSalesLine."Ref. Document Line No." := FromSalesLine."Line No.";
        END;
        //T007735

        IF CopyThisLine THEN BEGIN
            ToSalesLine.INSERT;
            //T006421
            IF (ToSalesHeader."HRU Document") AND (ToSalesHeader."Document Type" =
                      ToSalesHeader."Document Type"::"Return Order") THEN BEGIN
                ToSalesLine."Delivery Method" := ToSalesLine."Delivery Method"::Warehouse; //As per Sandeep Patil's Request 02.03.15
                ToSalesLine.VALIDATE("Pick Location", '');
                ToSalesLine.VALIDATE("Delivery By location", '');
                ToSalesLine.VALIDATE("Location Code", '');
                ToSalesLine.MODIFY;
            END;
            //T006421
            IF ToSalesLine.Reserve = ToSalesLine.Reserve::Always THEN
                ToSalesLine.AutoReserve;
        END ELSE
            LinesNotCopied := LinesNotCopied + 1;

        EXIT(TRUE);

    end;

    local procedure CopyPurchLine(var ToPurchHeader: Record "Purchase Header"; var ToPurchLine: Record "Purchase Line"; var FromPurchHeader: Record "Purchase Header"; var FromPurchLine: Record "Purchase Line"; var NextLineNo: Integer; var LinesNotCopied: Integer; RecalculateAmount: Boolean): Boolean
    var
        GLAcc: Record "G/L Account";
        ToPurchLine2: Record "Purchase Line";
        CopyThisLine: Boolean;
        StandardText: Record "Standard Text";
    begin
        CopyThisLine := TRUE;
        IF ((ToPurchHeader."Language Code" <> FromPurchHeader."Language Code") OR RecalculateLines) AND
           //LS -
           /*
           (FromPurchLine."Attached to Line No." <> 0) OR
           FromPurchLine."Prepayment Line"
           */
           ((FromPurchLine."Attached to Line No." <> 0) OR
           FromPurchLine."Prepayment Line") AND
           (FromPurchLine."Posting Group" = '')
        //LS +
        THEN
            EXIT(FALSE);

        IF RecalculateLines AND NOT FromPurchLine."System-Created Entry" THEN
            ToPurchLine.INIT
        ELSE
            ToPurchLine := FromPurchLine;
        NextLineNo := NextLineNo + 10000;
        ToPurchLine."Document Type" := ToPurchHeader."Document Type";
        ToPurchLine."Document No." := ToPurchHeader."No.";
        ToPurchLine."Line No." := NextLineNo;
        ToPurchLine.VALIDATE("Currency Code", FromPurchHeader."Currency Code");

        IF RecalculateLines AND NOT FromPurchLine."System-Created Entry" THEN BEGIN
            ToPurchLine.VALIDATE(Type, FromPurchLine.Type);
            ToPurchLine.VALIDATE(Description, FromPurchLine.Description);
            ToPurchLine.VALIDATE("Description 2", FromPurchLine."Description 2");
            IF (FromPurchLine.Type <> 0) AND (FromPurchLine."No." <> '') THEN BEGIN
                IF ToPurchLine.Type = ToPurchLine.Type::"G/L Account" THEN BEGIN
                    ToPurchLine."No." := FromPurchLine."No.";
                    IF GLAcc."No." <> FromPurchLine."No." THEN
                        GLAcc.GET(FromPurchLine."No.");
                    CopyThisLine := GLAcc."Direct Posting";
                    IF CopyThisLine THEN
                        ToPurchLine.VALIDATE("No.", FromPurchLine."No.");
                END ELSE
                    ToPurchLine.VALIDATE("No.", FromPurchLine."No.");
                ToPurchLine.VALIDATE("Variant Code", FromPurchLine."Variant Code");
                ToPurchLine.VALIDATE("Location Code", FromPurchLine."Location Code");
                ToPurchLine.VALIDATE("Unit of Measure", FromPurchLine."Unit of Measure");
                ToPurchLine.VALIDATE("Unit of Measure Code", FromPurchLine."Unit of Measure Code");
                ToPurchLine.VALIDATE(Quantity, FromPurchLine.Quantity);
                IF FromPurchLine.Type <> FromPurchLine.Type::Item THEN BEGIN
                    FromPurchHeader.TESTFIELD("Currency Code", ToPurchHeader."Currency Code");
                    ToPurchLine.VALIDATE("Direct Unit Cost", FromPurchLine."Direct Unit Cost");
                    ToPurchLine.VALIDATE("Line Discount %", FromPurchLine."Line Discount %");
                    IF ToPurchLine.Quantity <> 0 THEN
                        ToPurchLine.VALIDATE("Line Discount Amount", FromPurchLine."Line Discount Amount");
                END;
                IF (ToPurchLine."Document Type" = ToPurchLine."Document Type"::Order) AND
                   (FromPurchLine."Purchasing Code" <> '') AND NOT FromPurchLine."Drop Shipment" AND
                   NOT FromPurchLine."Special Order"
                THEN
                    ToPurchLine.VALIDATE("Purchasing Code", FromPurchLine."Purchasing Code");
            END;
            IF (FromPurchLine.Type = FromPurchLine.Type::" ") AND (FromPurchLine."No." <> '') THEN
                //LS -
                IF StandardText.GET(FromPurchLine."No.") THEN
                    //LS+
                    ToPurchLine.VALIDATE("No.", FromPurchLine."No.")
                //LS -
                ELSE BEGIN
                    ToPurchLine."No." := FromPurchLine."No.";
                    ToPurchLine."Location Code" := FromPurchLine."Location Code";
                    ToPurchLine."Unit of Measure Code" := FromPurchLine."Unit of Measure Code";
                    LastVariantSumLineNo := ToPurchLine."Line No.";
                END;
            //LS +
        END ELSE BEGIN
            IF ToPurchLine."Document Type" <> ToPurchLine."Document Type"::Order THEN BEGIN
                ToPurchLine."Prepayment %" := 0;
                ToPurchLine."Prepayment VAT %" := 0;
                ToPurchLine."Prepmt. VAT Calc. Type" := 0;
                ToPurchLine."Prepayment VAT Identifier" := '';
                ToPurchLine."Prepayment VAT %" := 0;
                ToPurchLine."Prepayment Tax Group Code" := '';
                ToPurchLine."Prepmt. Line Amount" := 0;
                ToPurchLine."Prepmt. Amt. Incl. VAT" := 0;
            END;
            ToPurchLine."Prepmt. Amt. Inv." := 0;
            ToPurchLine."Prepayment Amount" := 0;
            ToPurchLine."Prepmt. VAT Base Amt." := 0;
            ToPurchLine."Prepmt Amt to Deduct" := 0;
            ToPurchLine."Prepmt Amt Deducted" := 0;
            ToPurchLine."Prepmt. Amount Inv. Incl. VAT" := 0;
            ToPurchLine."Prepayment VAT Difference" := 0;
            ToPurchLine."Prepmt VAT Diff. to Deduct" := 0;
            ToPurchLine."Prepmt VAT Diff. Deducted" := 0;
            ToPurchLine."Quantity Received" := 0;
            ToPurchLine."Qty. Received (Base)" := 0;
            ToPurchLine."Return Qty. Shipped" := 0;
            ToPurchLine."Return Qty. Shipped (Base)" := 0;
            ToPurchLine."Quantity Invoiced" := 0;
            ToPurchLine."Qty. Invoiced (Base)" := 0;
            ToPurchLine."Reserved Quantity" := 0;
            ToPurchLine."Reserved Qty. (Base)" := 0;
            ToPurchLine."Qty. Rcd. Not Invoiced" := 0;
            ToPurchLine."Qty. Rcd. Not Invoiced (Base)" := 0;
            ToPurchLine."Return Qty. Shipped Not Invd." := 0;
            ToPurchLine."Ret. Qty. Shpd Not Invd.(Base)" := 0;
            ToPurchLine."Qty. to Receive" := 0;
            ToPurchLine."Qty. to Receive (Base)" := 0;
            ToPurchLine."Return Qty. to Ship" := 0;
            ToPurchLine."Return Qty. to Ship (Base)" := 0;
            ToPurchLine."Qty. to Invoice" := 0;
            ToPurchLine."Qty. to Invoice (Base)" := 0;
            ToPurchLine."Amt. Rcd. Not Invoiced" := 0;
            ToPurchLine."Amt. Rcd. Not Invoiced (LCY)" := 0;
            ToPurchLine."Return Shpd. Not Invd." := 0;
            ToPurchLine."Return Shpd. Not Invd. (LCY)" := 0;

            ToPurchLine.InitOutstanding;
            IF ToPurchLine."Document Type" IN
               [ToPurchLine."Document Type"::"Return Order", ToPurchLine."Document Type"::"Credit Memo"]
            THEN
                ToPurchLine.InitQtyToShip
            ELSE
                ToPurchLine.InitQtyToReceive;
            ToPurchLine."VAT Difference" := FromPurchLine."VAT Difference";
            ToPurchLine."Receipt No." := '';
            ToPurchLine."Receipt Line No." := 0;
            IF NOT CreateToHeader THEN
                ToPurchLine."Expected Receipt Date" := ToPurchHeader."Expected Receipt Date";
            ToPurchLine."Appl.-to Item Entry" := 0;

            ToPurchLine."Sales Order No." := '';
            ToPurchLine."Sales Order Line No." := 0;
            ToPurchLine."Special Order Sales No." := '';
            ToPurchLine."Special Order Sales Line No." := 0;
            IF FromPurchLine."Drop Shipment" OR FromPurchLine."Special Order" THEN
                ToPurchLine."Purchasing Code" := '';
            ToPurchLine."Drop Shipment" := FALSE;
            ToPurchLine."Special Order" := FALSE;

            IF RecalculateAmount THEN BEGIN
                ToPurchLine.VALIDATE("Line Discount %", FromPurchLine."Line Discount %");
                ToPurchLine.VALIDATE(
                  "Inv. Discount Amount",
                  ROUND(FromPurchLine."Inv. Discount Amount", Currency."Amount Rounding Precision"));
            END;

            ToPurchLine.UpdateWithWarehouseReceive;
            ToPurchLine."Pay-to Vendor No." := ToPurchHeader."Pay-to Vendor No.";
        END;

        IF ExactCostRevMandatory AND
           (FromPurchLine.Type = FromPurchLine.Type::Item) AND
           (FromPurchLine."Appl.-to Item Entry" <> 0) AND
           NOT MoveNegLines
        THEN BEGIN
            IF RecalculateAmount THEN BEGIN
                ToPurchLine.VALIDATE("Direct Unit Cost", FromPurchLine."Direct Unit Cost");
                ToPurchLine.VALIDATE(
                  "Line Discount Amount",
                  ROUND(FromPurchLine."Line Discount Amount", Currency."Amount Rounding Precision"));
                ToPurchLine.VALIDATE(
                  "Inv. Discount Amount",
                  ROUND(FromPurchLine."Inv. Discount Amount", Currency."Amount Rounding Precision"));
            END;
            ToPurchLine.VALIDATE("Appl.-to Item Entry", FromPurchLine."Appl.-to Item Entry");
            IF NOT CreateToHeader THEN
                IF ToPurchLine."Expected Receipt Date" = 0D THEN BEGIN
                    IF ToPurchHeader."Expected Receipt Date" <> 0D THEN
                        ToPurchLine."Expected Receipt Date" := ToPurchHeader."Expected Receipt Date"
                    ELSE
                        ToPurchLine."Expected Receipt Date" := WORKDATE;
                END;
        END;

        IF MoveNegLines AND (ToPurchLine.Type <> ToPurchLine.Type::" ") THEN BEGIN
            ToPurchLine.VALIDATE(Quantity, -FromPurchLine.Quantity);
            ToPurchLine."Appl.-to Item Entry" := FromPurchLine."Appl.-to Item Entry"
        END;

        IF (ToPurchHeader."Language Code" <> FromPurchHeader."Language Code") OR RecalculateLines THEN BEGIN
            IF TransferExtendedText.PurchCheckIfAnyExtText(ToPurchLine, FALSE) THEN BEGIN
                TransferExtendedText.InsertPurchExtText(ToPurchLine);
                ToPurchLine2.SETRANGE("Document Type", ToPurchLine."Document Type");
                ToPurchLine2.SETRANGE("Document No.", ToPurchLine."Document No.");
                ToPurchLine2.FIND('+');
                NextLineNo := ToPurchLine2."Line No.";
            END;
        END ELSE
            ToPurchLine."Attached to Line No." :=
              TransferOldExtLines.TransferExtendedText(
                FromPurchLine."Line No.",
                NextLineNo,
                FromPurchLine."Attached to Line No.");

        //LS Start
        IF (FromPurchLine."Attached to Line No." <> 0) AND
           (ToPurchLine."Attached to Line No." = 0) AND
           (ToPurchLine."Variant Code" <> '') AND
           (LastVariantSumLineNo <> 0) THEN
            ToPurchLine."Attached to Line No." := LastVariantSumLineNo;
        //LS Stop

        IF CopyThisLine THEN
            ToPurchLine.INSERT
        ELSE
            LinesNotCopied := LinesNotCopied + 1;
        EXIT(TRUE);

    end;

    local procedure CopyFromSalesDocDimToHeader(var ToSalesHeader: Record "Sales Header"; var FromSalesHeader: Record "Sales Header")
    var
        DocDim: Record "Document Dimension";
        FromDocDim: Record "Document Dimension";
    begin
        DocDim.SETRANGE("Table ID", DATABASE::"Sales Header");
        DocDim.SETRANGE("Document Type", ToSalesHeader."Document Type");
        DocDim.SETRANGE("Document No.", ToSalesHeader."No.");
        DocDim.SETRANGE("Line No.", 0);
        DocDim.DELETEALL;
        ToSalesHeader."Shortcut Dimension 1 Code" := FromSalesHeader."Shortcut Dimension 1 Code";
        ToSalesHeader."Shortcut Dimension 2 Code" := FromSalesHeader."Shortcut Dimension 2 Code";
        FromDocDim.SETRANGE("Table ID", DATABASE::"Sales Header");
        FromDocDim.SETRANGE("Document Type", FromSalesHeader."Document Type");
        FromDocDim.SETRANGE("Document No.", FromSalesHeader."No.");
        IF FromDocDim.FIND('-') THEN BEGIN
            REPEAT
                DocDim.INIT;
                DocDim."Table ID" := DATABASE::"Sales Header";
                DocDim."Document Type" := ToSalesHeader."Document Type";
                DocDim."Document No." := ToSalesHeader."No.";
                DocDim."Line No." := 0;
                DocDim."Dimension Code" := FromDocDim."Dimension Code";
                DocDim."Dimension Value Code" := FromDocDim."Dimension Value Code";
                DocDim.INSERT;
            UNTIL FromDocDim.NEXT = 0;
        END;
    end;

    local procedure CopyFromPurchDocDimToHeader(var ToPurchHeader: Record "Purchase Header"; var FromPurchHeader: Record "Purchase Header")
    var
        DocDim: Record "Document Dimension";
        FromDocDim: Record "Document Dimension";
    begin
        DocDim.SETRANGE("Table ID", DATABASE::"Purchase Header");
        DocDim.SETRANGE("Document Type", ToPurchHeader."Document Type");
        DocDim.SETRANGE("Document No.", ToPurchHeader."No.");
        DocDim.SETRANGE("Line No.", 0);
        DocDim.DELETEALL;
        ToPurchHeader."Shortcut Dimension 1 Code" := FromPurchHeader."Shortcut Dimension 1 Code";
        ToPurchHeader."Shortcut Dimension 2 Code" := FromPurchHeader."Shortcut Dimension 2 Code";
        FromDocDim.SETRANGE("Table ID", DATABASE::"Purchase Header");
        FromDocDim.SETRANGE("Document Type", FromPurchHeader."Document Type");
        FromDocDim.SETRANGE("Document No.", FromPurchHeader."No.");
        IF FromDocDim.FIND('-') THEN BEGIN
            REPEAT
                DocDim.INIT;
                DocDim."Table ID" := DATABASE::"Purchase Header";
                DocDim."Document Type" := ToPurchHeader."Document Type";
                DocDim."Document No." := ToPurchHeader."No.";
                DocDim."Line No." := 0;
                DocDim."Dimension Code" := FromDocDim."Dimension Code";
                DocDim."Dimension Value Code" := FromDocDim."Dimension Value Code";
                DocDim.INSERT;
            UNTIL FromDocDim.NEXT = 0;
        END;
    end;

    local procedure CopyFromPstdSalesDocDimToHdr(var ToSalesHeader: Record "Sales Header"; FromDocType: Option; var FromSalesShptHeader: Record "Sales Shipment Header"; var FromSalesInvHeader: Record "Sales Invoice Header"; var FromReturnRcptHeader: Record "Return Receipt Header"; var FromSalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        DocDim: Record "Document Dimension";
        FromPostedDocDim: Record "Posted Document Dimension";
    begin
        DocDim.SETRANGE("Table ID", DATABASE::"Sales Header");
        DocDim.SETRANGE("Document Type", ToSalesHeader."Document Type");
        DocDim.SETRANGE("Document No.", ToSalesHeader."No.");
        DocDim.SETRANGE("Line No.", 0);
        DocDim.DELETEALL;
        CASE FromDocType OF
            SalesDocType::"Posted Shipment":
                BEGIN
                    ToSalesHeader."Shortcut Dimension 1 Code" := FromSalesShptHeader."Shortcut Dimension 1 Code";
                    ToSalesHeader."Shortcut Dimension 2 Code" := FromSalesShptHeader."Shortcut Dimension 2 Code";
                    FromPostedDocDim.SETRANGE("Table ID", DATABASE::"Sales Shipment Header");
                    FromPostedDocDim.SETRANGE("Document No.", FromSalesShptHeader."No.");
                END;
            SalesDocType::"Posted Invoice":
                BEGIN
                    ToSalesHeader."Shortcut Dimension 1 Code" := FromSalesInvHeader."Shortcut Dimension 1 Code";
                    ToSalesHeader."Shortcut Dimension 2 Code" := FromSalesInvHeader."Shortcut Dimension 2 Code";
                    FromPostedDocDim.SETRANGE("Table ID", DATABASE::"Sales Invoice Header");
                    FromPostedDocDim.SETRANGE("Document No.", FromSalesInvHeader."No.");
                END;
            SalesDocType::"Posted Return Receipt":
                BEGIN
                    ToSalesHeader."Shortcut Dimension 1 Code" := FromReturnRcptHeader."Shortcut Dimension 1 Code";
                    ToSalesHeader."Shortcut Dimension 2 Code" := FromReturnRcptHeader."Shortcut Dimension 2 Code";
                    FromPostedDocDim.SETRANGE("Table ID", DATABASE::"Return Receipt Header");
                    FromPostedDocDim.SETRANGE("Document No.", FromReturnRcptHeader."No.");
                END;
            SalesDocType::"Posted Credit Memo":
                BEGIN
                    ToSalesHeader."Shortcut Dimension 1 Code" := FromSalesCrMemoHeader."Shortcut Dimension 1 Code";
                    ToSalesHeader."Shortcut Dimension 2 Code" := FromSalesCrMemoHeader."Shortcut Dimension 2 Code";
                    FromPostedDocDim.SETRANGE("Table ID", DATABASE::"Sales Cr.Memo Header");
                    FromPostedDocDim.SETRANGE("Document No.", FromSalesCrMemoHeader."No.");
                END;
        END;
        IF FromPostedDocDim.FIND('-') THEN BEGIN
            REPEAT
                DocDim.INIT;
                DocDim."Table ID" := DATABASE::"Sales Header";
                DocDim."Document Type" := ToSalesHeader."Document Type";
                DocDim."Document No." := ToSalesHeader."No.";
                DocDim."Line No." := 0;
                DocDim."Dimension Code" := FromPostedDocDim."Dimension Code";
                DocDim."Dimension Value Code" := FromPostedDocDim."Dimension Value Code";
                DocDim.INSERT;
            UNTIL FromPostedDocDim.NEXT = 0;
        END;
    end;

    local procedure CopyFromPstdPurchDocDimToHdr(var ToPurchHeader: Record "Purchase Header"; FromDocType: Option; var FromPurchRcptHeader: Record "Purch. Rcpt. Header"; var FromPurchInvHeader: Record "Purch. Inv. Header"; var FromReturnShptHeader: Record "Return Shipment Header"; var FromPurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.")
    var
        DocDim: Record "Document Dimension";
        FromPostedDocDim: Record "Posted Document Dimension";
    begin
        DocDim.SETRANGE("Table ID", DATABASE::"Purchase Header");
        DocDim.SETRANGE("Document Type", ToPurchHeader."Document Type");
        DocDim.SETRANGE("Document No.", ToPurchHeader."No.");
        DocDim.SETRANGE("Line No.", 0);
        DocDim.DELETEALL;
        CASE FromDocType OF
            PurchDocType::"Posted Receipt":
                BEGIN
                    ToPurchHeader."Shortcut Dimension 1 Code" := FromPurchRcptHeader."Shortcut Dimension 1 Code";
                    ToPurchHeader."Shortcut Dimension 2 Code" := FromPurchRcptHeader."Shortcut Dimension 2 Code";
                    FromPostedDocDim.SETRANGE("Table ID", DATABASE::"Purch. Rcpt. Header");
                    FromPostedDocDim.SETRANGE("Document No.", FromPurchRcptHeader."No.");
                END;
            PurchDocType::"Posted Invoice":
                BEGIN
                    ToPurchHeader."Shortcut Dimension 1 Code" := FromPurchInvHeader."Shortcut Dimension 1 Code";
                    ToPurchHeader."Shortcut Dimension 2 Code" := FromPurchInvHeader."Shortcut Dimension 2 Code";
                    FromPostedDocDim.SETRANGE("Table ID", DATABASE::"Purch. Inv. Header");
                    FromPostedDocDim.SETRANGE("Document No.", FromPurchInvHeader."No.");
                END;
            PurchDocType::"Posted Return Shipment":
                BEGIN
                    ToPurchHeader."Shortcut Dimension 1 Code" := FromReturnShptHeader."Shortcut Dimension 1 Code";
                    ToPurchHeader."Shortcut Dimension 2 Code" := FromReturnShptHeader."Shortcut Dimension 2 Code";
                    FromPostedDocDim.SETRANGE("Table ID", DATABASE::"Return Shipment Header");
                    FromPostedDocDim.SETRANGE("Document No.", FromReturnShptHeader."No.");
                END;
            PurchDocType::"Posted Credit Memo":
                BEGIN
                    ToPurchHeader."Shortcut Dimension 1 Code" := FromPurchCrMemoHeader."Shortcut Dimension 1 Code";
                    ToPurchHeader."Shortcut Dimension 2 Code" := FromPurchCrMemoHeader."Shortcut Dimension 2 Code";
                    FromPostedDocDim.SETRANGE("Table ID", DATABASE::"Purch. Cr. Memo Hdr.");
                    FromPostedDocDim.SETRANGE("Document No.", FromPurchCrMemoHeader."No.");
                END;
        END;
        IF FromPostedDocDim.FIND('-') THEN BEGIN
            REPEAT
                DocDim.INIT;
                DocDim."Table ID" := DATABASE::"Purchase Header";
                DocDim."Document Type" := ToPurchHeader."Document Type";
                DocDim."Document No." := ToPurchHeader."No.";
                DocDim."Line No." := 0;
                DocDim."Dimension Code" := FromPostedDocDim."Dimension Code";
                DocDim."Dimension Value Code" := FromPostedDocDim."Dimension Value Code";
                DocDim.INSERT;
            UNTIL FromPostedDocDim.NEXT = 0;
        END;
    end;

    local procedure CopyFromSalesDocDimToLine(var ToSalesLine: Record "Sales Line"; var FromSalesLine: Record "Sales Line")
    var
        DocDim: Record "Document Dimension";
        FromDocDim: Record "Document Dimension";
    begin
        IF NOT RecalculateLines THEN BEGIN
            DocDim.SETRANGE("Table ID", DATABASE::"Sales Line");
            DocDim.SETRANGE("Document Type", ToSalesLine."Document Type");
            DocDim.SETRANGE("Document No.", ToSalesLine."Document No.");
            DocDim.SETRANGE("Line No.", ToSalesLine."Line No.");
            DocDim.DELETEALL;
            ToSalesLine."Shortcut Dimension 1 Code" := FromSalesLine."Shortcut Dimension 1 Code";
            ToSalesLine."Shortcut Dimension 2 Code" := FromSalesLine."Shortcut Dimension 2 Code";
            FromDocDim.SETRANGE("Table ID", DATABASE::"Sales Line");
            FromDocDim.SETRANGE("Document Type", FromSalesLine."Document Type");
            FromDocDim.SETRANGE("Document No.", FromSalesLine."Document No.");
            FromDocDim.SETRANGE("Line No.", FromSalesLine."Line No.");
            IF FromDocDim.FIND('-') THEN BEGIN
                REPEAT
                    DocDim.INIT;
                    DocDim."Table ID" := DATABASE::"Sales Line";
                    DocDim."Document Type" := ToSalesLine."Document Type";
                    DocDim."Document No." := ToSalesLine."Document No.";
                    DocDim."Line No." := ToSalesLine."Line No.";
                    DocDim."Dimension Code" := FromDocDim."Dimension Code";
                    DocDim."Dimension Value Code" := FromDocDim."Dimension Value Code";
                    DocDim.INSERT;
                UNTIL FromDocDim.NEXT = 0;
            END;
        END;
    end;

    local procedure CopyFromPurchDocDimToLine(var ToPurchLine: Record "Purchase Line"; var FromPurchLine: Record "Purchase Line")
    var
        DocDim: Record "Document Dimension";
        FromDocDim: Record "Document Dimension";
    begin
        IF NOT RecalculateLines THEN BEGIN
            DocDim.SETRANGE("Table ID", DATABASE::"Purchase Line");
            DocDim.SETRANGE("Document Type", ToPurchLine."Document Type");
            DocDim.SETRANGE("Document No.", ToPurchLine."Document No.");
            DocDim.SETRANGE("Line No.", ToPurchLine."Line No.");
            DocDim.DELETEALL;
            ToPurchLine."Shortcut Dimension 1 Code" := FromPurchLine."Shortcut Dimension 1 Code";
            ToPurchLine."Shortcut Dimension 2 Code" := FromPurchLine."Shortcut Dimension 2 Code";
            FromDocDim.SETRANGE("Table ID", DATABASE::"Purchase Line");
            FromDocDim.SETRANGE("Document Type", FromPurchLine."Document Type");
            FromDocDim.SETRANGE("Document No.", FromPurchLine."Document No.");
            FromDocDim.SETRANGE("Line No.", FromPurchLine."Line No.");
            IF FromDocDim.FIND('-') THEN BEGIN
                REPEAT
                    DocDim.INIT;
                    DocDim."Table ID" := DATABASE::"Purchase Line";
                    DocDim."Document Type" := ToPurchLine."Document Type";
                    DocDim."Document No." := ToPurchLine."Document No.";
                    DocDim."Line No." := ToPurchLine."Line No.";
                    DocDim."Dimension Code" := FromDocDim."Dimension Code";
                    DocDim."Dimension Value Code" := FromDocDim."Dimension Value Code";
                    DocDim.INSERT;
                UNTIL FromDocDim.NEXT = 0;
            END;
        END;
    end;

    local procedure CopyFromPstdSalesDocDimToLine(var ToSalesLine: Record "Sales Line"; FromDocType: Option; var FromSalesShptLine: Record "Sales Shipment Line"; var FromSalesInvLine: Record "Sales Invoice Line"; var FromReturnRcptLine: Record "Return Receipt Line"; var FromSalesCrMemoLine: Record "Sales Cr.Memo Line")
    var
        DocDim: Record "Document Dimension";
        FromPostedDocDim: Record "Posted Document Dimension";
    begin
        IF NOT RecalculateLines THEN BEGIN
            DocDim.SETRANGE("Table ID", DATABASE::"Sales Line");
            DocDim.SETRANGE("Document Type", ToSalesLine."Document Type");
            DocDim.SETRANGE("Document No.", ToSalesLine."Document No.");
            DocDim.SETRANGE("Line No.", ToSalesLine."Line No.");
            DocDim.DELETEALL;
            CASE FromDocType OF
                SalesDocType::"Posted Shipment":
                    BEGIN
                        ToSalesLine."Shortcut Dimension 1 Code" := FromSalesShptLine."Shortcut Dimension 1 Code";
                        ToSalesLine."Shortcut Dimension 2 Code" := FromSalesShptLine."Shortcut Dimension 2 Code";
                        FromPostedDocDim.SETRANGE("Table ID", DATABASE::"Sales Shipment Line");
                        FromPostedDocDim.SETRANGE("Document No.", FromSalesShptLine."Document No.");
                        FromPostedDocDim.SETRANGE("Line No.", FromSalesShptLine."Line No.");
                    END;
                SalesDocType::"Posted Invoice":
                    BEGIN
                        ToSalesLine."Shortcut Dimension 1 Code" := FromSalesInvLine."Shortcut Dimension 1 Code";
                        ToSalesLine."Shortcut Dimension 2 Code" := FromSalesInvLine."Shortcut Dimension 2 Code";
                        FromPostedDocDim.SETRANGE("Table ID", DATABASE::"Sales Invoice Line");
                        FromPostedDocDim.SETRANGE("Document No.", FromSalesInvLine."Document No.");
                        FromPostedDocDim.SETRANGE("Line No.", FromSalesInvLine."Line No.");
                    END;
                SalesDocType::"Posted Return Receipt":
                    BEGIN
                        ToSalesLine."Shortcut Dimension 1 Code" := FromReturnRcptLine."Shortcut Dimension 1 Code";
                        ToSalesLine."Shortcut Dimension 2 Code" := FromReturnRcptLine."Shortcut Dimension 2 Code";
                        FromPostedDocDim.SETRANGE("Table ID", DATABASE::"Return Receipt Line");
                        FromPostedDocDim.SETRANGE("Document No.", FromReturnRcptLine."Document No.");
                        FromPostedDocDim.SETRANGE("Line No.", FromReturnRcptLine."Line No.");
                    END;
                SalesDocType::"Posted Credit Memo":
                    BEGIN
                        ToSalesLine."Shortcut Dimension 1 Code" := FromSalesCrMemoLine."Shortcut Dimension 1 Code";
                        ToSalesLine."Shortcut Dimension 2 Code" := FromSalesCrMemoLine."Shortcut Dimension 2 Code";
                        FromPostedDocDim.SETRANGE("Table ID", DATABASE::"Sales Cr.Memo Line");
                        FromPostedDocDim.SETRANGE("Document No.", FromSalesCrMemoLine."Document No.");
                        FromPostedDocDim.SETRANGE("Line No.", FromSalesCrMemoLine."Line No.");
                    END;
            END;
            IF FromPostedDocDim.FIND('-') THEN BEGIN
                REPEAT
                    DocDim.INIT;
                    DocDim."Table ID" := DATABASE::"Sales Line";
                    DocDim."Document Type" := ToSalesLine."Document Type";
                    DocDim."Document No." := ToSalesLine."Document No.";
                    DocDim."Line No." := ToSalesLine."Line No.";
                    DocDim."Dimension Code" := FromPostedDocDim."Dimension Code";
                    DocDim."Dimension Value Code" := FromPostedDocDim."Dimension Value Code";
                    DocDim.INSERT;
                UNTIL FromPostedDocDim.NEXT = 0;
            END;
        END;
    end;

    local procedure CopyFromPstdPurchDocDimToLine(var ToPurchLine: Record "Purchase Line"; FromDocType: Option; var FromPurchRcptLine: Record "Purch. Rcpt. Line"; var FromPurchInvLine: Record "Purch. Inv. Line"; var FromReturnShptLine: Record "Return Shipment Line"; var FromPurchCrMemoLine: Record "Purch. Cr. Memo Line")
    var
        DocDim: Record "Document Dimension";
        FromPostedDocDim: Record "Posted Document Dimension";
    begin
        IF NOT RecalculateLines THEN BEGIN
            DocDim.SETRANGE("Table ID", DATABASE::"Purchase Line");
            DocDim.SETRANGE("Document Type", ToPurchLine."Document Type");
            DocDim.SETRANGE("Document No.", ToPurchLine."Document No.");
            DocDim.SETRANGE("Line No.", ToPurchLine."Line No.");
            DocDim.DELETEALL;
            CASE FromDocType OF
                PurchDocType::"Posted Receipt":
                    BEGIN
                        ToPurchLine."Shortcut Dimension 1 Code" := FromPurchRcptLine."Shortcut Dimension 1 Code";
                        ToPurchLine."Shortcut Dimension 2 Code" := FromPurchRcptLine."Shortcut Dimension 2 Code";
                        FromPostedDocDim.SETRANGE("Table ID", DATABASE::"Purch. Rcpt. Line");
                        FromPostedDocDim.SETRANGE("Document No.", FromPurchRcptLine."Document No.");
                        FromPostedDocDim.SETRANGE("Line No.", FromPurchRcptLine."Line No.");
                    END;
                PurchDocType::"Posted Invoice":
                    BEGIN
                        ToPurchLine."Shortcut Dimension 1 Code" := FromPurchInvLine."Shortcut Dimension 1 Code";
                        ToPurchLine."Shortcut Dimension 2 Code" := FromPurchInvLine."Shortcut Dimension 2 Code";
                        FromPostedDocDim.SETRANGE("Table ID", DATABASE::"Purch. Inv. Line");
                        FromPostedDocDim.SETRANGE("Document No.", FromPurchInvLine."Document No.");
                        FromPostedDocDim.SETRANGE("Line No.", FromPurchInvLine."Line No.");
                    END;
                PurchDocType::"Posted Return Shipment":
                    BEGIN
                        ToPurchLine."Shortcut Dimension 1 Code" := FromReturnShptLine."Shortcut Dimension 1 Code";
                        ToPurchLine."Shortcut Dimension 2 Code" := FromReturnShptLine."Shortcut Dimension 2 Code";
                        FromPostedDocDim.SETRANGE("Table ID", DATABASE::"Return Shipment Line");
                        FromPostedDocDim.SETRANGE("Document No.", FromReturnShptLine."Document No.");
                        FromPostedDocDim.SETRANGE("Line No.", FromReturnShptLine."Line No.");
                    END;
                PurchDocType::"Posted Credit Memo":
                    BEGIN
                        ToPurchLine."Shortcut Dimension 1 Code" := FromPurchCrMemoLine."Shortcut Dimension 1 Code";
                        ToPurchLine."Shortcut Dimension 2 Code" := FromPurchCrMemoLine."Shortcut Dimension 2 Code";
                        FromPostedDocDim.SETRANGE("Table ID", DATABASE::"Purch. Cr. Memo Line");
                        FromPostedDocDim.SETRANGE("Document No.", FromPurchCrMemoLine."Document No.");
                        FromPostedDocDim.SETRANGE("Line No.", FromPurchCrMemoLine."Line No.");
                    END;
            END;
            IF FromPostedDocDim.FIND('-') THEN BEGIN
                REPEAT
                    DocDim.INIT;
                    DocDim."Table ID" := DATABASE::"Purchase Line";
                    DocDim."Document Type" := ToPurchLine."Document Type";
                    DocDim."Document No." := ToPurchLine."Document No.";
                    DocDim."Line No." := ToPurchLine."Line No.";
                    DocDim."Dimension Code" := FromPostedDocDim."Dimension Code";
                    DocDim."Dimension Value Code" := FromPostedDocDim."Dimension Value Code";
                    DocDim.INSERT;
                UNTIL FromPostedDocDim.NEXT = 0;
            END;
        END;
    end;

    local procedure CopyFromSalesDocAssgntToLine(var ToSalesLine: Record "Sales Line"; FromSalesLine: Record "Sales Line"; var ItemChargeAssgntNextLineNo: Integer)
    var
        FromItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
        ToItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
        AssignItemChargeSales: Codeunit "5807";
    begin
        WITH FromSalesLine DO BEGIN
            IF NOT FromItemChargeAssgntSales.RECORDLEVELLOCKING THEN
                FromItemChargeAssgntSales.LOCKTABLE(TRUE, TRUE);
            FromItemChargeAssgntSales.RESET;
            FromItemChargeAssgntSales.SETRANGE("Document Type", "Document Type");
            FromItemChargeAssgntSales.SETRANGE("Document No.", "Document No.");
            FromItemChargeAssgntSales.SETRANGE("Document Line No.", "Line No.");
            FromItemChargeAssgntSales.SETFILTER(
              "Applies-to Doc. Type", '<>%1', "Document Type");
            IF FromItemChargeAssgntSales.FIND('-') THEN
                REPEAT
                    ToItemChargeAssgntSales.COPY(FromItemChargeAssgntSales);
                    ToItemChargeAssgntSales."Document Type" := ToSalesLine."Document Type";
                    ToItemChargeAssgntSales."Document No." := ToSalesLine."Document No.";
                    ToItemChargeAssgntSales."Document Line No." := ToSalesLine."Line No.";
                    AssignItemChargeSales.InsertItemChargeAssgnt(
                      ToItemChargeAssgntSales, ToItemChargeAssgntSales."Applies-to Doc. Type",
                      ToItemChargeAssgntSales."Applies-to Doc. No.", ToItemChargeAssgntSales."Applies-to Doc. Line No.",
                      ToItemChargeAssgntSales."Item No.", ToItemChargeAssgntSales.Description, ItemChargeAssgntNextLineNo);
                UNTIL FromItemChargeAssgntSales.NEXT = 0;
        END;
    end;

    local procedure CopyFromPurchDocAssgntToLine(var ToPurchLine: Record "Purchase Line"; FromPurchLine: Record "Purchase Line"; var ItemChargeAssgntNextLineNo: Integer)
    var
        FromItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        ToItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        AssignItemChargePurch: Codeunit "5805";
    begin
        WITH FromPurchLine DO BEGIN
            IF NOT FromItemChargeAssgntPurch.RECORDLEVELLOCKING THEN
                FromItemChargeAssgntPurch.LOCKTABLE(TRUE, TRUE);
            FromItemChargeAssgntPurch.RESET;
            FromItemChargeAssgntPurch.SETRANGE("Document Type", "Document Type");
            FromItemChargeAssgntPurch.SETRANGE("Document No.", "Document No.");
            FromItemChargeAssgntPurch.SETRANGE("Document Line No.", "Line No.");
            FromItemChargeAssgntPurch.SETFILTER(
              "Applies-to Doc. Type", '<>%1', "Document Type");
            IF FromItemChargeAssgntPurch.FIND('-') THEN
                REPEAT
                    ToItemChargeAssgntPurch.COPY(FromItemChargeAssgntPurch);
                    ToItemChargeAssgntPurch."Document Type" := ToPurchLine."Document Type";
                    ToItemChargeAssgntPurch."Document No." := ToPurchLine."Document No.";
                    ToItemChargeAssgntPurch."Document Line No." := ToPurchLine."Line No.";
                    AssignItemChargePurch.InsertItemChargeAssgnt(
                      ToItemChargeAssgntPurch, ToItemChargeAssgntPurch."Applies-to Doc. Type",
                      ToItemChargeAssgntPurch."Applies-to Doc. No.", ToItemChargeAssgntPurch."Applies-to Doc. Line No.",
                      ToItemChargeAssgntPurch."Item No.", ToItemChargeAssgntPurch.Description, ItemChargeAssgntNextLineNo);
                UNTIL FromItemChargeAssgntPurch.NEXT = 0;
        END;
    end;

    local procedure WarnSalesInvoicePmtDisc(var ToSalesHeader: Record "Sales Header"; var FromSalesHeader: Record "Sales Header"; FromDocType: Option; FromDocNo: Code[20])
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        IF HideDialog THEN
            EXIT;

        IF IncludeHeader AND
           (ToSalesHeader."Document Type" IN
            [ToSalesHeader."Document Type"::"Return Order", ToSalesHeader."Document Type"::"Credit Memo"])
        THEN BEGIN
            CustLedgEntry.SETCURRENTKEY("Document No.");
            CustLedgEntry.SETRANGE("Document Type", FromSalesHeader."Document Type"::Invoice);
            CustLedgEntry.SETRANGE("Document No.", FromDocNo);
            IF CustLedgEntry.FIND('-') THEN BEGIN
                IF (CustLedgEntry."Pmt. Disc. Given (LCY)" <> 0) AND
                   (CustLedgEntry."Journal Batch Name" = '')
                THEN
                    MESSAGE(Text006, SELECTSTR(FromDocType, Text007), FromDocNo);
            END;
        END;

        IF IncludeHeader AND
           (ToSalesHeader."Document Type" IN
            [ToSalesHeader."Document Type"::Invoice, ToSalesHeader."Document Type"::Order,
             ToSalesHeader."Document Type"::Quote, ToSalesHeader."Document Type"::"Blanket Order"]) AND
           (FromDocType = FromDocType::"9")
        THEN BEGIN
            CustLedgEntry.SETCURRENTKEY("Document No.");
            CustLedgEntry.SETRANGE("Document Type", FromSalesHeader."Document Type"::"Credit Memo");
            CustLedgEntry.SETRANGE("Document No.", FromDocNo);
            IF CustLedgEntry.FIND('-') THEN BEGIN
                IF (CustLedgEntry."Pmt. Disc. Given (LCY)" <> 0) AND
                   (CustLedgEntry."Journal Batch Name" = '')
                THEN
                    MESSAGE(Text006, SELECTSTR(FromDocType - 1, Text007), FromDocNo);
            END;
        END;
    end;

    local procedure WarnPurchInvoicePmtDisc(var ToPurchHeader: Record "Purchase Header"; var FromPurchHeader: Record "Purchase Header"; FromDocType: Option; FromDocNo: Code[20])
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        IF HideDialog THEN
            EXIT;

        IF IncludeHeader AND
           (ToPurchHeader."Document Type" IN
            [ToPurchHeader."Document Type"::"Return Order", ToPurchHeader."Document Type"::"Credit Memo"])
        THEN BEGIN
            VendLedgEntry.SETCURRENTKEY("Document No.");
            VendLedgEntry.SETRANGE("Document Type", FromPurchHeader."Document Type"::Invoice);
            VendLedgEntry.SETRANGE("Document No.", FromDocNo);
            IF VendLedgEntry.FIND('-') THEN BEGIN
                IF (VendLedgEntry."Pmt. Disc. Rcd.(LCY)" <> 0) AND
                   (VendLedgEntry."Journal Batch Name" = '')
                THEN
                    MESSAGE(Text009, SELECTSTR(FromDocType, Text007), FromDocNo);
            END;
        END;

        IF IncludeHeader AND
           (ToPurchHeader."Document Type" IN
            [ToPurchHeader."Document Type"::Invoice, ToPurchHeader."Document Type"::Order,
             ToPurchHeader."Document Type"::Quote, ToPurchHeader."Document Type"::"Blanket Order"]) AND
           (FromDocType = FromDocType::"9")
        THEN BEGIN
            VendLedgEntry.SETCURRENTKEY("Document No.");
            VendLedgEntry.SETRANGE("Document Type", FromPurchHeader."Document Type"::"Credit Memo");
            VendLedgEntry.SETRANGE("Document No.", FromDocNo);
            IF VendLedgEntry.FIND('-') THEN BEGIN
                IF (VendLedgEntry."Pmt. Disc. Rcd.(LCY)" <> 0) AND
                   (VendLedgEntry."Journal Batch Name" = '')
                THEN
                    MESSAGE(Text006, SELECTSTR(FromDocType - 1, Text007), FromDocNo);
            END;
        END;
    end;

    local procedure CheckItemAvailable(var ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line")
    begin
        IF HideDialog THEN
            EXIT;

        ToSalesLine."Document Type" := ToSalesHeader."Document Type";
        ToSalesLine."Document No." := ToSalesHeader."No.";
        ToSalesLine."Line No." := 0;
        ToSalesLine.Type := ToSalesLine.Type::Item;
        ToSalesLine."Purchase Order No." := '';
        ToSalesLine."Purch. Order Line No." := 0;
        ToSalesLine."Drop Shipment" :=
          NOT RecalculateLines AND ToSalesLine."Drop Shipment" AND
          (ToSalesHeader."Document Type" = ToSalesHeader."Document Type"::Order);

        IF ToSalesLine."Shipment Date" = 0D THEN BEGIN
            IF ToSalesHeader."Shipment Date" <> 0D THEN
                ToSalesLine.VALIDATE("Shipment Date", ToSalesHeader."Shipment Date")
            ELSE
                ToSalesLine.VALIDATE("Shipment Date", WORKDATE);
        END;

        ItemCheckAvail.SalesLineCheck(ToSalesLine);
    end;

    local procedure ClearSalesBizTalkFields(var NewSalesHeader: Record "Sales Header")
    begin
        WITH NewSalesHeader DO BEGIN
            "Date Received" := 0D;
            "Time Received" := 0T;
            //APNT-Suj
            /*
            "BizTalk Request for Sales Qte." := FALSE;
            "BizTalk Sales Order" := FALSE;
            "Date Sent" := 0D;
            "Time Sent" := 0T;
            "BizTalk Sales Quote" := FALSE;
            "BizTalk Sales Order Cnfmn." := FALSE;
            */
            //APNT-Suj
            //"Customer Quote No." := ''; APNT-HRU1.0
            "Customer Order No." := '';
            //"BizTalk Document Sent" := FALSE;  //APNT-Suj
        END

    end;

    local procedure ClearPurchBizTalkFields(var NewPurchHeader: Record "Purchase Header")
    begin
        WITH NewPurchHeader DO BEGIN
            "Date Received" := 0D;
            "Time Received" := 0T;
            "BizTalk Purchase Quote" := FALSE;
            "BizTalk Purch. Order Cnfmn." := FALSE;
            "BizTalk Purchase Invoice" := FALSE;
            "BizTalk Purchase Receipt" := FALSE;
            "BizTalk Purchase Credit Memo" := FALSE;
            "Date Sent" := 0D;
            "Time Sent" := 0T;
            "BizTalk Request for Purch. Qte" := FALSE;
            "BizTalk Purchase Order" := FALSE;
            "Vendor Quote No." := '';
            "BizTalk Document Sent" := FALSE;
        END
    end;

    procedure CopyServContractLines(ToServContractHeader: Record "Service Contract"; FromDocType: Option; FromDocNo: Code[20]; var FromServContractLine: Record "Service Contract Line") AllLinesCopied: Boolean
    var
        ExistingServContractLine: Record "Service Contract Line";
        LineNo: Integer;
    begin
        IF FromDocNo = '' THEN
            ERROR(Text000);

        ExistingServContractLine.LOCKTABLE;
        ExistingServContractLine.RESET;
        ExistingServContractLine.SETRANGE("Contract Type", ToServContractHeader."Contract Type");
        ExistingServContractLine.SETRANGE("Contract No.", ToServContractHeader."Contract No.");
        IF ExistingServContractLine.FIND('+') THEN
            LineNo := ExistingServContractLine."Line No." + 10000
        ELSE
            LineNo := 10000;

        AllLinesCopied := TRUE;
        FromServContractLine.RESET;
        FromServContractLine.SETRANGE("Contract Type", FromDocType);
        FromServContractLine.SETRANGE("Contract No.", FromDocNo);
        IF FromServContractLine.FIND('-') THEN
            REPEAT
                IF NOT ProcessServContractLine(
                  ToServContractHeader,
                  FromServContractLine,
                  LineNo)
                THEN BEGIN
                    AllLinesCopied := FALSE;
                    FromServContractLine.MARK(TRUE)
                END ELSE
                    LineNo := LineNo + 10000
            UNTIL FromServContractLine.NEXT = 0;
    end;

    procedure ServContractHeaderDocType(DocType: Option): Integer
    var
        ServContractHeader: Record "Service Contract";
    begin
        CASE DocType OF
            ServDocType::Quote:
                EXIT(ServContractHeader."Contract Type"::Quote);
            ServDocType::Contract:
                EXIT(ServContractHeader."Contract Type"::Contract);
        END;
    end;

    procedure ProcessServContractLine(ToServContractHeader: Record "Service Contract"; var FromServContractLine: Record "Service Contract Line"; LineNo: Integer): Boolean
    var
        ToServContractLine: Record "Service Contract Line";
        ExistingServContractLine: Record "Service Contract Line";
        ServItem: Record "Service Item";
    begin
        IF FromServContractLine."Service Item No." <> '' THEN BEGIN
            ServItem.GET(FromServContractLine."Service Item No.");
            IF ServItem."Customer No." <> ToServContractHeader."Customer No." THEN
                EXIT(FALSE);

            ExistingServContractLine.RESET;
            ExistingServContractLine.SETCURRENTKEY("Service Item No.", "Contract Status");
            ExistingServContractLine.SETRANGE("Service Item No.", FromServContractLine."Service Item No.");
            ExistingServContractLine.SETRANGE("Contract Type", ToServContractHeader."Contract Type");
            ExistingServContractLine.SETRANGE("Contract No.", ToServContractHeader."Contract No.");
            IF ExistingServContractLine.FIND('-') THEN
                EXIT(FALSE);
        END;

        ToServContractLine := FromServContractLine;
        ToServContractLine."Last Planned Service Date" := 0D;
        ToServContractLine."Last Service Date" := 0D;
        ToServContractLine."Last Preventive Maint. Date" := 0D;
        ToServContractLine."Invoiced to Date" := 0D;
        ToServContractLine."Contract Type" := ToServContractHeader."Contract Type";
        ToServContractLine."Contract No." := ToServContractHeader."Contract No.";
        ToServContractLine."Line No." := LineNo;
        ToServContractLine."New Line" := TRUE;
        ToServContractLine.Credited := FALSE;
        ToServContractLine.SetupNewLine;
        ToServContractLine.INSERT(TRUE);
        EXIT(TRUE);
    end;

    procedure CopySalesShptLinesToDoc(ToSalesHeader: Record "Sales Header"; var FromSalesShptLine: Record "Sales Shipment Line"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        TempTrkgItemLedgEntry: Record "Item Ledger Entry" temporary;
        FromSalesHeader: Record "Sales Header";
        FromSalesLine: Record "Sales Line";
        ToSalesLine: Record "Sales Line";
        FromSalesLineBuf: Record "Sales Line" temporary;
        FromSalesShptHeader: Record "Sales Shipment Header";
        FromSalesInvLine: Record "Sales Invoice Line";
        FromReturnRcptLine: Record "Return Receipt Line";
        FromSalesCrMemoLine: Record "Sales Cr.Memo Line";
        TempItemTrkgEntry: Record "Reservation Entry" temporary;
        ItemTrackingMgt: Codeunit "6500";
        OldDocNo: Code[20];
        NextLineNo: Integer;
        NextItemTrkgEntryNo: Integer;
        FromLineCounter: Integer;
        ToLineCounter: Integer;
        CopyItemTrkg: Boolean;
        SplitLine: Boolean;
        FillExactCostRevLink: Boolean;
        CopyLine: Boolean;
        InsertDocNoLine: Boolean;
        lConfigID: Code[30];
    begin
        MissingExCostRevLink := FALSE;
        InitCurrency(ToSalesHeader."Currency Code");
        OpenWindow;

        WITH FromSalesShptLine DO
            IF FINDSET THEN
                REPEAT
                    FromLineCounter := FromLineCounter + 1;
                    IF IsTimeForUpdate THEN
                        Window.UPDATE(1, FromLineCounter);
                    IF FromSalesShptHeader."No." <> "Document No." THEN BEGIN
                        FromSalesShptHeader.GET("Document No.");
                        TransferOldExtLines.ClearLineNumbers;
                    END;
                    FromSalesHeader.TRANSFERFIELDS(FromSalesShptHeader);
                    FillExactCostRevLink :=
                      IsSalesFillExactCostRevLink(ToSalesHeader, 0, FromSalesHeader."Currency Code");
                    FromSalesLine.TRANSFERFIELDS(FromSalesShptLine);
                    FromSalesLine."Appl.-from Item Entry" := 0;

                    IF "Document No." <> OldDocNo THEN BEGIN
                        OldDocNo := "Document No.";
                        InsertDocNoLine := TRUE;
                    END;

                    SplitLine := TRUE;
                    FilterPstdDocLnItemLedgEntries(ItemLedgEntry);
                    IF NOT SplitPstdSalesLinesPerILE(
                         ToSalesHeader, FromSalesHeader, ItemLedgEntry, FromSalesLineBuf,
                         FromSalesLine, NextLineNo, CopyItemTrkg, MissingExCostRevLink, FillExactCostRevLink, TRUE)
                    THEN
                        IF CopyItemTrkg THEN
                            SplitLine :=
                              SplitSalesDocLinesPerItemTrkg(
                                ItemLedgEntry, TempItemTrkgEntry, FromSalesLineBuf,
                                FromSalesLine, NextLineNo, NextItemTrkgEntryNo, MissingExCostRevLink, TRUE)
                        ELSE
                            SplitLine := FALSE;

                    IF NOT SplitLine THEN BEGIN
                        FromSalesLineBuf := FromSalesLine;
                        CopyLine := TRUE;
                    END ELSE
                        CopyLine := FromSalesLineBuf.FINDSET AND FillExactCostRevLink;


                    Window.UPDATE(1, FromLineCounter);
                    IF CopyLine THEN BEGIN
                        NextLineNo := GetLastToSalesLineNo(ToSalesHeader);
                        IF InsertDocNoLine THEN BEGIN
                            InsertOldSalesDocNoLine(ToSalesHeader, "Document No.", 1, NextLineNo);
                            InsertDocNoLine := FALSE;
                        END;
                        IF (FromSalesLineBuf.Type <> FromSalesLineBuf.Type::" ") OR
                           (FromSalesLineBuf."Attached to Line No." = 0)
                        THEN
                            REPEAT
                                ToLineCounter := ToLineCounter + 1;
                                IF IsTimeForUpdate THEN
                                    Window.UPDATE(2, ToLineCounter);
                                IF CopySalesLine(
                                  ToSalesHeader, ToSalesLine, FromSalesHeader, FromSalesLineBuf, NextLineNo, LinesNotCopied, FALSE)
                                THEN BEGIN
                                    CopyFromPstdSalesDocDimToLine(
                                      ToSalesLine, SalesDocType::"Posted Shipment",
                                      FromSalesShptLine, FromSalesInvLine, FromReturnRcptLine, FromSalesCrMemoLine);

                                    IF CopyItemTrkg THEN BEGIN
                                        IF SplitLine THEN BEGIN
                                            TempItemTrkgEntry.RESET;
                                            TempItemTrkgEntry.SETCURRENTKEY("Source ID", "Source Ref. No.");
                                            TempItemTrkgEntry.SETRANGE("Source ID", FromSalesLineBuf."Document No.");
                                            TempItemTrkgEntry.SETRANGE("Source Ref. No.", FromSalesLineBuf."Line No.");
                                            CollectItemTrkgPerPstDocLine(TempItemTrkgEntry, TempTrkgItemLedgEntry, FALSE);
                                        END ELSE
                                            ItemTrackingMgt.CollectItemTrkgPerPstdDocLine(TempTrkgItemLedgEntry, ItemLedgEntry);

                                        ItemTrackingMgt.CopyItemLedgEntryTrkgToSalesLn(
                                          TempTrkgItemLedgEntry, ToSalesLine,
                                          FillExactCostRevLink AND ExactCostRevMandatory, MissingExCostRevLink,
                                          FromSalesHeader."Prices Including VAT", ToSalesHeader."Prices Including VAT", TRUE);
                                    END;

                                    CopySalesShptExtTextToDoc(
                                      ToSalesHeader, ToSalesLine, FromSalesShptLine, FromSalesHeader."Language Code",
                                      NextLineNo, FromSalesLineBuf."Appl.-from Item Entry" <> 0);

                                    //LS -
                                    IF (FromSalesShptLine."Retail Special Order") AND (FromSalesShptLine."Configuration ID" <> '') THEN BEGIN
                                        lConfigID := ToSalesLine."Document No." + '.' + FORMAT(ToSalesLine."Line No.");
                                        CopyPstOptionType(lConfigID, FromSalesLineBuf."Configuration ID");
                                    END;
                                    //LS +

                                END;
                            UNTIL FromSalesLineBuf.NEXT = 0;
                    END;
                UNTIL NEXT = 0;

        Window.CLOSE;
    end;

    local procedure CopySalesShptExtTextToDoc(ToSalesHeader: Record "Sales Header"; ToSalesLine: Record "Sales Line"; FromSalesShptLine: Record "Sales Shipment Line"; FromLanguageCode: Code[10]; var NextLineNo: Integer; ExactCostReverse: Boolean)
    var
        ToSalesLine2: Record "Sales Line";
        FromSalesInvLine: Record "Sales Invoice Line";
        FromReturnRcptLine: Record "Return Receipt Line";
        FromSalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        ToSalesLine2.SETRANGE("Document No.", ToSalesLine."Document No.");
        ToSalesLine2.SETRANGE("Attached to Line No.", ToSalesLine."Line No.");
        IF ToSalesLine2.ISEMPTY THEN
            WITH FromSalesShptLine DO BEGIN
                SETRANGE("Document No.", "Document No.");
                SETRANGE("Attached to Line No.", "Line No.");
                IF FINDSET THEN
                    REPEAT
                        IF (ToSalesHeader."Language Code" <> FromLanguageCode) OR
                           (RecalculateLines AND NOT ExactCostReverse)
                        THEN BEGIN
                            IF TransferExtendedText.SalesCheckIfAnyExtText(ToSalesLine, FALSE) THEN BEGIN
                                TransferExtendedText.InsertSalesExtText(ToSalesLine);
                                NextLineNo := GetLastToSalesLineNo(ToSalesHeader);
                            END;
                        END ELSE BEGIN
                            CopySalesExtTextLines(
                              ToSalesLine2, ToSalesLine, Description, "Description 2", NextLineNo);
                            CopyFromPstdSalesDocDimToLine(
                              ToSalesLine2, SalesDocType::"Posted Shipment", FromSalesShptLine,
                              FromSalesInvLine, FromReturnRcptLine, FromSalesCrMemoLine);
                        END;
                    UNTIL NEXT = 0;
            END;
    end;

    procedure CopySalesInvLinesToDoc(ToSalesHeader: Record "Sales Header"; var FromSalesInvLine: Record "Sales Invoice Line"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    var
        ItemLedgEntryBuf: Record "Item Ledger Entry" temporary;
        TempTrkgItemLedgEntry: Record "Item Ledger Entry" temporary;
        FromSalesHeader: Record "Sales Header";
        FromSalesLine: Record "Sales Line";
        FromSalesLine2: Record "Sales Line";
        ToSalesLine: Record "Sales Line";
        FromSalesLineBuf: Record "Sales Line" temporary;
        FromSalesInvHeader: Record "Sales Invoice Header";
        FromSalesShptLine: Record "Sales Shipment Line";
        FromReturnRcptLine: Record "Return Receipt Line";
        FromSalesCrMemoLine: Record "Sales Cr.Memo Line";
        TempItemTrkgEntry: Record "Reservation Entry" temporary;
        ItemTrackingMgt: Codeunit "6500";
        OldInvDocNo: Code[20];
        OldShptDocNo: Code[20];
        NextLineNo: Integer;
        NextItemTrkgEntryNo: Integer;
        FromLineCounter: Integer;
        ToLineCounter: Integer;
        CopyItemTrkg: Boolean;
        SplitLine: Boolean;
        FillExactCostRevLink: Boolean;
        lConfigID: Code[30];
    begin
        MissingExCostRevLink := FALSE;
        InitCurrency(ToSalesHeader."Currency Code");
        FromSalesLineBuf.RESET;
        FromSalesLineBuf.DELETEALL;
        TempItemTrkgEntry.RESET;
        TempItemTrkgEntry.DELETEALL;
        OpenWindow;

        // Fill sales line buffer
        WITH FromSalesInvLine DO
            IF FINDSET THEN
                REPEAT
                    FromLineCounter := FromLineCounter + 1;
                    IF IsTimeForUpdate THEN
                        Window.UPDATE(1, FromLineCounter);
                    IF FromSalesInvHeader."No." <> "Document No." THEN BEGIN
                        FromSalesInvHeader.GET("Document No.");
                        TransferOldExtLines.ClearLineNumbers;
                    END;
                    FromSalesHeader.TRANSFERFIELDS(FromSalesInvHeader);
                    FillExactCostRevLink :=
                      IsSalesFillExactCostRevLink(ToSalesHeader, 1, FromSalesHeader."Currency Code");
                    FromSalesLine.TRANSFERFIELDS(FromSalesInvLine);
                    FromSalesLine."Appl.-from Item Entry" := 0;
                    // Reuse fields to buffer invoice line information
                    FromSalesLine."Shipment No." := "Document No.";
                    FromSalesLine."Shipment Line No." := 0;
                    FromSalesLine."Return Receipt No." := '';
                    FromSalesLine."Return Receipt Line No." := "Line No.";
                    //DP6.01.01 START
                    IF FromSalesInvHeader."Agreement Invoice/Cr Memo" THEN BEGIN
                        FromSalesLine."Ref. Document Type" := FromSalesInvLine."Ref. Document Type";
                        FromSalesLine."Ref. Document No." := FromSalesInvLine."Ref. Document No.";
                        FromSalesLine."Ref. Document Line No." := FromSalesInvLine."Ref. Document Line No.";
                        FromSalesLine."Element Type" := FromSalesInvLine."Element Type";
                        FromSalesLine."Rental Element" := FromSalesInvLine."Rental Element";
                        FromSalesLine."Agreement Due Date" := FromSalesInvLine."Agreement Due Date";
                    END;
                    //DP6.01.01 STOP

                    SplitLine := TRUE;
                    GetItemLedgEntries(ItemLedgEntryBuf, TRUE);
                    IF NOT SplitPstdSalesLinesPerILE(
                         ToSalesHeader, FromSalesHeader, ItemLedgEntryBuf, FromSalesLineBuf,
                         FromSalesLine, NextLineNo, CopyItemTrkg, MissingExCostRevLink, FillExactCostRevLink, FALSE)
                    THEN
                        IF CopyItemTrkg THEN
                            SplitLine :=
                              SplitSalesDocLinesPerItemTrkg(
                                ItemLedgEntryBuf, TempItemTrkgEntry, FromSalesLineBuf,
                                FromSalesLine, NextLineNo, NextItemTrkgEntryNo, MissingExCostRevLink, FALSE)
                        ELSE
                            SplitLine := FALSE;

                    //T007735
                    IF ToSalesHeader."HRU Document" THEN BEGIN
                        FromSalesLine."Ref. Document Type" := FromSalesLine."Ref. Document Type"::Sale;
                        FromSalesLine."Ref. Document No." := FromSalesInvLine."Document No.";
                        FromSalesLine."Ref. Document Line No." := FromSalesInvLine."Line No.";
                        FromSalesLineBuf."Ref. Document Type" := FromSalesLineBuf."Ref. Document Type"::Sale;
                        FromSalesLineBuf."Ref. Document No." := FromSalesInvLine."Document No.";
                        FromSalesLineBuf."Ref. Document Line No." := FromSalesInvLine."Line No.";
                    END;
                    //T007735

                    IF NOT SplitLine THEN BEGIN
                        FromSalesLine2 := FromSalesLineBuf;
                        FromSalesLineBuf := FromSalesLine;
                        FromSalesLineBuf."Document No." := FromSalesLine2."Document No.";
                        FromSalesLineBuf."Shipment Line No." := FromSalesLine2."Shipment Line No.";
                        FromSalesLineBuf."Line No." := NextLineNo;

                        NextLineNo := NextLineNo + 1;
                        IF NOT IsRecalculateAmount(
                             FromSalesHeader."Currency Code", ToSalesHeader."Currency Code",
                             FromSalesHeader."Prices Including VAT", ToSalesHeader."Prices Including VAT")
                        THEN
                            FromSalesLineBuf."Return Receipt No." := "Document No.";
                        ReCalcSalesLine(FromSalesHeader, ToSalesHeader, FromSalesLineBuf);
                        FromSalesLineBuf.INSERT;
                    END;
                UNTIL NEXT = 0;

        // Create sales line from buffer
        Window.UPDATE(1, FromLineCounter);
        WITH FromSalesLineBuf DO BEGIN
            // Sorting according to Sales Line Document No.,Line No.
            SETCURRENTKEY("Document Type", "Document No.", "Line No.");
            IF FINDSET THEN BEGIN
                NextLineNo := GetLastToSalesLineNo(ToSalesHeader);
                REPEAT
                    ToLineCounter := ToLineCounter + 1;
                    IF IsTimeForUpdate THEN
                        Window.UPDATE(2, ToLineCounter);
                    IF "Shipment No." <> OldInvDocNo THEN BEGIN
                        OldInvDocNo := "Shipment No.";
                        OldShptDocNo := '';
                        InsertOldSalesDocNoLine(ToSalesHeader, OldInvDocNo, 2, NextLineNo);
                    END;
                    IF ("Document No." <> OldShptDocNo) AND ("Shipment Line No." > 0) THEN BEGIN
                        OldShptDocNo := "Document No.";
                        InsertOldSalesCombDocNoLine(ToSalesHeader, OldInvDocNo, OldShptDocNo, NextLineNo, TRUE);
                    END;

                    IF (Type <> Type::" ") OR ("Attached to Line No." = 0) THEN BEGIN
                        // Empty buffer fields
                        FromSalesLine2 := FromSalesLineBuf;
                        FromSalesLine2."Shipment No." := '';
                        FromSalesLine2."Shipment Line No." := 0;
                        FromSalesLine2."Return Receipt No." := '';
                        FromSalesLine2."Return Receipt Line No." := 0;

                        IF CopySalesLine(
                          ToSalesHeader, ToSalesLine, FromSalesHeader,
                          FromSalesLine2, NextLineNo, LinesNotCopied, "Return Receipt No." = '')
                        THEN BEGIN
                            FromSalesInvLine.GET("Shipment No.", "Return Receipt Line No.");

                            //T007735
                            IF ToSalesHeader."HRU Document" THEN BEGIN
                                ToSalesLine."Ref. Document Type" := ToSalesLine."Ref. Document Type"::Sale;
                                ToSalesLine."Ref. Document No." := FromSalesLine2."Ref. Document No.";
                                ToSalesLine."Ref. Document Line No." := FromSalesLine2."Ref. Document Line No.";
                                IF ToSalesLine.MODIFY THEN;
                            END;
                            //T007735

                            CopyFromPstdSalesDocDimToLine(
                              ToSalesLine, SalesDocType::"Posted Invoice",
                              FromSalesShptLine, FromSalesInvLine, FromReturnRcptLine, FromSalesCrMemoLine);

                            // copy item tracking
                            IF (Type = Type::Item) AND (Quantity <> 0) THEN BEGIN
                                FromSalesInvLine."Document No." := OldInvDocNo;
                                FromSalesInvLine."Line No." := "Return Receipt Line No.";
                                FromSalesInvLine.GetItemLedgEntries(ItemLedgEntryBuf, TRUE);
                                IF IsCopyItemTrkg(ItemLedgEntryBuf, CopyItemTrkg, FillExactCostRevLink) THEN BEGIN
                                    IF MoveNegLines OR NOT ExactCostRevMandatory THEN
                                        ItemTrackingMgt.CollectItemTrkgPerPstdDocLine(TempTrkgItemLedgEntry, ItemLedgEntryBuf)
                                    ELSE BEGIN
                                        TempItemTrkgEntry.RESET;
                                        TempItemTrkgEntry.SETCURRENTKEY("Source ID", "Source Ref. No.");
                                        TempItemTrkgEntry.SETRANGE("Source ID", "Document No.");
                                        TempItemTrkgEntry.SETRANGE("Source Ref. No.", "Line No.");
                                        CollectItemTrkgPerPstDocLine(TempItemTrkgEntry, TempTrkgItemLedgEntry, FALSE);
                                    END;

                                    ItemTrackingMgt.CopyItemLedgEntryTrkgToSalesLn(
                                      TempTrkgItemLedgEntry, ToSalesLine,
                                      FillExactCostRevLink AND ExactCostRevMandatory, MissingExCostRevLink,
                                      FromSalesHeader."Prices Including VAT", ToSalesHeader."Prices Including VAT", FALSE);
                                END;
                            END;

                            CopySalesInvExtTextToDoc(
                              ToSalesHeader, ToSalesLine, FromSalesHeader."Language Code", "Shipment No.",
                              "Return Receipt Line No.", NextLineNo, "Appl.-from Item Entry" <> 0);

                            //LS -
                            IF (FromSalesInvLine."Retail Special Order") AND (FromSalesInvLine."Configuration ID" <> '') THEN BEGIN
                                lConfigID := ToSalesLine."Document No." + '.' + FORMAT(ToSalesLine."Line No.");
                                CopyPstOptionType(lConfigID, FromSalesLineBuf."Configuration ID");
                            END;
                            //LS +
                        END;
                    END;
                UNTIL NEXT = 0;
            END;
        END;

        Window.CLOSE;
    end;

    local procedure CopySalesInvExtTextToDoc(ToSalesHeader: Record "Sales Header"; ToSalesLine: Record "Sales Line"; FromLanguageCode: Code[10]; FromInvDocNo: Code[20]; FromInvDocLineNo: Integer; var NextLineNo: Integer; ExactCostReverse: Boolean)
    var
        ToSalesLine2: Record "Sales Line";
        FromSalesInvLine: Record "Sales Invoice Line";
        FromSalesShptLine: Record "Sales Shipment Line";
        FromReturnRcptLine: Record "Return Receipt Line";
        FromSalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        ToSalesLine2.SETRANGE("Document No.", ToSalesLine."Document No.");
        ToSalesLine2.SETRANGE("Attached to Line No.", ToSalesLine."Line No.");
        IF ToSalesLine2.ISEMPTY THEN
            WITH FromSalesInvLine DO BEGIN
                SETRANGE("Document No.", FromInvDocNo);
                SETRANGE("Attached to Line No.", FromInvDocLineNo);
                IF FINDSET THEN
                    REPEAT
                        IF (ToSalesHeader."Language Code" <> FromLanguageCode) OR
                           (RecalculateLines AND NOT ExactCostReverse)
                        THEN BEGIN
                            IF TransferExtendedText.SalesCheckIfAnyExtText(ToSalesLine, FALSE) THEN BEGIN
                                TransferExtendedText.InsertSalesExtText(ToSalesLine);
                                NextLineNo := GetLastToSalesLineNo(ToSalesHeader);
                            END;
                        END ELSE BEGIN
                            CopySalesExtTextLines(
                              ToSalesLine2, ToSalesLine, Description, "Description 2", NextLineNo);
                            CopyFromPstdSalesDocDimToLine(
                              ToSalesLine2, SalesDocType::"Posted Invoice", FromSalesShptLine,
                              FromSalesInvLine, FromReturnRcptLine, FromSalesCrMemoLine);
                        END;
                    UNTIL NEXT = 0;
            END;
    end;

    procedure CopySalesCrMemoLinesToDoc(ToSalesHeader: Record "Sales Header"; var FromSalesCrMemoLine: Record "Sales Cr.Memo Line"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    var
        ItemLedgEntryBuf: Record "Item Ledger Entry" temporary;
        TempTrkgItemLedgEntry: Record "Item Ledger Entry" temporary;
        FromSalesHeader: Record "Sales Header";
        FromSalesLine: Record "Sales Line";
        FromSalesLine2: Record "Sales Line";
        ToSalesLine: Record "Sales Line";
        FromSalesLineBuf: Record "Sales Line" temporary;
        FromSalesCrMemoHeader: Record "Sales Cr.Memo Header";
        FromSalesShptLine: Record "Sales Shipment Line";
        FromReturnRcptLine: Record "Return Receipt Line";
        FromSalesInvLine: Record "Sales Invoice Line";
        TempItemTrkgEntry: Record "Reservation Entry" temporary;
        ItemTrackingMgt: Codeunit "6500";
        OldCrMemoDocNo: Code[20];
        OldReturnRcptDocNo: Code[20];
        NextLineNo: Integer;
        NextItemTrkgEntryNo: Integer;
        FromLineCounter: Integer;
        ToLineCounter: Integer;
        CopyItemTrkg: Boolean;
        SplitLine: Boolean;
        FillExactCostRevLink: Boolean;
    begin
        MissingExCostRevLink := FALSE;
        InitCurrency(ToSalesHeader."Currency Code");
        FromSalesLineBuf.RESET;
        FromSalesLineBuf.DELETEALL;
        TempItemTrkgEntry.RESET;
        TempItemTrkgEntry.DELETEALL;
        OpenWindow;

        // Fill sales line buffer
        WITH FromSalesCrMemoLine DO
            IF FINDSET THEN
                REPEAT
                    FromLineCounter := FromLineCounter + 1;
                    IF IsTimeForUpdate THEN
                        Window.UPDATE(1, FromLineCounter);
                    IF FromSalesCrMemoHeader."No." <> "Document No." THEN BEGIN
                        FromSalesCrMemoHeader.GET("Document No.");
                        TransferOldExtLines.ClearLineNumbers;
                    END;
                    FromSalesHeader.TRANSFERFIELDS(FromSalesCrMemoHeader);
                    FillExactCostRevLink :=
                      IsSalesFillExactCostRevLink(ToSalesHeader, 3, FromSalesHeader."Currency Code");
                    FromSalesLine.TRANSFERFIELDS(FromSalesCrMemoLine);
                    FromSalesLine."Appl.-from Item Entry" := 0;
                    // Reuse fields to buffer credit memo line information
                    FromSalesLine."Shipment No." := "Document No.";
                    FromSalesLine."Shipment Line No." := 0;
                    FromSalesLine."Return Receipt No." := '';
                    FromSalesLine."Return Receipt Line No." := "Line No.";

                    SplitLine := TRUE;
                    GetItemLedgEntries(ItemLedgEntryBuf, TRUE);
                    IF NOT SplitPstdSalesLinesPerILE(
                         ToSalesHeader, FromSalesHeader, ItemLedgEntryBuf, FromSalesLineBuf,
                         FromSalesLine, NextLineNo, CopyItemTrkg, MissingExCostRevLink, FillExactCostRevLink, FALSE)
                    THEN
                        IF CopyItemTrkg THEN
                            SplitLine :=
                              SplitSalesDocLinesPerItemTrkg(
                                ItemLedgEntryBuf, TempItemTrkgEntry, FromSalesLineBuf,
                                FromSalesLine, NextLineNo, NextItemTrkgEntryNo, MissingExCostRevLink, FALSE)
                        ELSE
                            SplitLine := FALSE;

                    IF NOT SplitLine THEN BEGIN
                        FromSalesLine2 := FromSalesLineBuf;
                        FromSalesLineBuf := FromSalesLine;
                        FromSalesLineBuf."Document No." := FromSalesLine2."Document No.";
                        FromSalesLineBuf."Shipment Line No." := FromSalesLine2."Shipment Line No.";
                        FromSalesLineBuf."Line No." := NextLineNo;
                        NextLineNo := NextLineNo + 1;
                        IF NOT IsRecalculateAmount(
                             FromSalesHeader."Currency Code", ToSalesHeader."Currency Code",
                             FromSalesHeader."Prices Including VAT", ToSalesHeader."Prices Including VAT")
                        THEN
                            FromSalesLineBuf."Return Receipt No." := "Document No.";
                        ReCalcSalesLine(FromSalesHeader, ToSalesHeader, FromSalesLineBuf);
                        FromSalesLineBuf.INSERT;
                    END;

                UNTIL NEXT = 0;

        // Create sales line from buffer
        Window.UPDATE(1, FromLineCounter);
        WITH FromSalesLineBuf DO BEGIN
            // Sorting according to Sales Line Document No.,Line No.
            SETCURRENTKEY("Document Type", "Document No.", "Line No.");
            IF FINDSET THEN BEGIN
                NextLineNo := GetLastToSalesLineNo(ToSalesHeader);
                REPEAT
                    ToLineCounter := ToLineCounter + 1;
                    IF IsTimeForUpdate THEN
                        Window.UPDATE(2, ToLineCounter);
                    IF "Shipment No." <> OldCrMemoDocNo THEN BEGIN
                        OldCrMemoDocNo := "Shipment No.";
                        OldReturnRcptDocNo := '';
                        InsertOldSalesDocNoLine(ToSalesHeader, OldCrMemoDocNo, 4, NextLineNo);
                    END;
                    IF ("Document No." <> OldReturnRcptDocNo) AND ("Shipment Line No." > 0) THEN BEGIN
                        OldReturnRcptDocNo := "Document No.";
                        InsertOldSalesCombDocNoLine(ToSalesHeader, OldCrMemoDocNo, OldReturnRcptDocNo, NextLineNo, FALSE);
                    END;

                    IF (Type <> Type::" ") OR ("Attached to Line No." = 0) THEN BEGIN
                        // Empty buffer fields
                        FromSalesLine2 := FromSalesLineBuf;
                        FromSalesLine2."Shipment No." := '';
                        FromSalesLine2."Shipment Line No." := 0;
                        FromSalesLine2."Return Receipt No." := '';
                        FromSalesLine2."Return Receipt Line No." := 0;

                        IF CopySalesLine(
                          ToSalesHeader, ToSalesLine, FromSalesHeader,
                          FromSalesLine2, NextLineNo, LinesNotCopied, "Return Receipt No." = '')
                        THEN BEGIN
                            FromSalesCrMemoLine.GET("Shipment No.", "Return Receipt Line No.");
                            CopyFromPstdSalesDocDimToLine(
                              ToSalesLine, SalesDocType::"Posted Credit Memo",
                              FromSalesShptLine, FromSalesInvLine, FromReturnRcptLine, FromSalesCrMemoLine);

                            // copy item tracking
                            IF (Type = Type::Item) AND (Quantity <> 0) THEN BEGIN
                                FromSalesCrMemoLine."Document No." := OldCrMemoDocNo;
                                FromSalesCrMemoLine."Line No." := "Return Receipt Line No.";
                                FromSalesCrMemoLine.GetItemLedgEntries(ItemLedgEntryBuf, TRUE);
                                IF IsCopyItemTrkg(ItemLedgEntryBuf, CopyItemTrkg, FillExactCostRevLink) THEN BEGIN
                                    IF MoveNegLines OR NOT ExactCostRevMandatory THEN
                                        ItemTrackingMgt.CollectItemTrkgPerPstdDocLine(TempTrkgItemLedgEntry, ItemLedgEntryBuf)
                                    ELSE BEGIN
                                        TempItemTrkgEntry.RESET;
                                        TempItemTrkgEntry.SETCURRENTKEY("Source ID", "Source Ref. No.");
                                        TempItemTrkgEntry.SETRANGE("Source ID", "Document No.");
                                        TempItemTrkgEntry.SETRANGE("Source Ref. No.", "Line No.");
                                        CollectItemTrkgPerPstDocLine(TempItemTrkgEntry, TempTrkgItemLedgEntry, FALSE);
                                    END;

                                    ItemTrackingMgt.CopyItemLedgEntryTrkgToSalesLn(
                                      TempTrkgItemLedgEntry, ToSalesLine,
                                      FillExactCostRevLink AND ExactCostRevMandatory, MissingExCostRevLink,
                                      FromSalesHeader."Prices Including VAT", ToSalesHeader."Prices Including VAT", FALSE);
                                END;
                            END;
                            CopySalesCrMemoExtTextToDoc(
                              ToSalesHeader, ToSalesLine, FromSalesHeader."Language Code", "Shipment No.",
                              "Return Receipt Line No.", NextLineNo, "Appl.-from Item Entry" <> 0);
                        END;
                    END;
                UNTIL NEXT = 0;
            END;
        END;

        Window.CLOSE;
    end;

    local procedure CopySalesCrMemoExtTextToDoc(ToSalesHeader: Record "Sales Header"; ToSalesLine: Record "Sales Line"; FromLanguageCode: Code[10]; FromCrMemoDocNo: Code[20]; FromCrMemoDocLineNo: Integer; var NextLineNo: Integer; ExactCostReverse: Boolean)
    var
        ToSalesLine2: Record "Sales Line";
        FromSalesShptLine: Record "Sales Shipment Line";
        FromSalesInvLine: Record "Sales Invoice Line";
        FromSalesCrMemoLine: Record "Sales Cr.Memo Line";
        FromReturnRcptLine: Record "Return Receipt Line";
    begin
        ToSalesLine2.SETRANGE("Document No.", ToSalesLine."Document No.");
        ToSalesLine2.SETRANGE("Attached to Line No.", ToSalesLine."Line No.");
        IF ToSalesLine2.ISEMPTY THEN
            WITH FromSalesCrMemoLine DO BEGIN
                SETRANGE("Document No.", FromCrMemoDocNo);
                SETRANGE("Attached to Line No.", FromCrMemoDocLineNo);
                IF FINDSET THEN
                    REPEAT
                        IF (ToSalesHeader."Language Code" <> FromLanguageCode) OR
                           (RecalculateLines AND NOT ExactCostReverse)
                        THEN BEGIN
                            IF TransferExtendedText.SalesCheckIfAnyExtText(ToSalesLine, FALSE) THEN BEGIN
                                TransferExtendedText.InsertSalesExtText(ToSalesLine);
                                NextLineNo := GetLastToSalesLineNo(ToSalesHeader);
                            END;
                        END ELSE BEGIN
                            CopySalesExtTextLines(
                              ToSalesLine2, ToSalesLine, Description, "Description 2", NextLineNo);
                            CopyFromPstdSalesDocDimToLine(
                              ToSalesLine2, SalesDocType::"Posted Credit Memo", FromSalesShptLine,
                              FromSalesInvLine, FromReturnRcptLine, FromSalesCrMemoLine);
                        END;
                    UNTIL NEXT = 0;
            END;
    end;

    procedure CopySalesReturnRcptLinesToDoc(ToSalesHeader: Record "Sales Header"; var FromReturnRcptLine: Record "Return Receipt Line"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        TempTrkgItemLedgEntry: Record "Item Ledger Entry" temporary;
        FromSalesHeader: Record "Sales Header";
        FromSalesLine: Record "Sales Line";
        ToSalesLine: Record "Sales Line";
        FromSalesLineBuf: Record "Sales Line" temporary;
        FromReturnRcptHeader: Record "Return Receipt Header";
        FromSalesShptLine: Record "Sales Shipment Line";
        FromSalesInvLine: Record "Sales Invoice Line";
        FromSalesCrMemoLine: Record "Sales Cr.Memo Line";
        TempItemTrkgEntry: Record "Reservation Entry" temporary;
        ItemTrackingMgt: Codeunit "6500";
        OldDocNo: Code[20];
        NextLineNo: Integer;
        NextItemTrkgEntryNo: Integer;
        FromLineCounter: Integer;
        ToLineCounter: Integer;
        CopyItemTrkg: Boolean;
        SplitLine: Boolean;
        FillExactCostRevLink: Boolean;
        CopyLine: Boolean;
        InsertDocNoLine: Boolean;
    begin
        MissingExCostRevLink := FALSE;
        InitCurrency(ToSalesHeader."Currency Code");
        OpenWindow;

        WITH FromReturnRcptLine DO
            IF FINDSET THEN
                REPEAT
                    FromLineCounter := FromLineCounter + 1;
                    IF IsTimeForUpdate THEN
                        Window.UPDATE(1, FromLineCounter);
                    IF FromReturnRcptHeader."No." <> "Document No." THEN BEGIN
                        FromReturnRcptHeader.GET("Document No.");
                        TransferOldExtLines.ClearLineNumbers;
                    END;
                    FromSalesHeader.TRANSFERFIELDS(FromReturnRcptHeader);
                    FillExactCostRevLink :=
                      IsSalesFillExactCostRevLink(ToSalesHeader, 2, FromSalesHeader."Currency Code");
                    FromSalesLine.TRANSFERFIELDS(FromReturnRcptLine);
                    FromSalesLine."Appl.-from Item Entry" := 0;

                    IF "Document No." <> OldDocNo THEN BEGIN
                        OldDocNo := "Document No.";
                        InsertDocNoLine := TRUE;
                    END;

                    SplitLine := TRUE;
                    FilterPstdDocLnItemLedgEntries(ItemLedgEntry);
                    IF NOT SplitPstdSalesLinesPerILE(
                         ToSalesHeader, FromSalesHeader, ItemLedgEntry, FromSalesLineBuf,
                         FromSalesLine, NextLineNo, CopyItemTrkg, MissingExCostRevLink, FillExactCostRevLink, TRUE)
                    THEN
                        IF CopyItemTrkg THEN
                            SplitLine :=
                              SplitSalesDocLinesPerItemTrkg(
                                ItemLedgEntry, TempItemTrkgEntry, FromSalesLineBuf,
                                FromSalesLine, NextLineNo, NextItemTrkgEntryNo, MissingExCostRevLink, TRUE)
                        ELSE
                            SplitLine := FALSE;

                    IF NOT SplitLine THEN BEGIN
                        FromSalesLineBuf := FromSalesLine;
                        CopyLine := TRUE;
                    END ELSE
                        CopyLine := FromSalesLineBuf.FINDSET AND FillExactCostRevLink;

                    Window.UPDATE(1, FromLineCounter);
                    IF CopyLine THEN BEGIN
                        NextLineNo := GetLastToSalesLineNo(ToSalesHeader);
                        IF InsertDocNoLine THEN BEGIN
                            InsertOldSalesDocNoLine(ToSalesHeader, "Document No.", 3, NextLineNo);
                            InsertDocNoLine := FALSE;
                        END;
                        IF (FromSalesLineBuf.Type <> FromSalesLineBuf.Type::" ") OR
                           (FromSalesLineBuf."Attached to Line No." = 0)
                        THEN
                            REPEAT
                                ToLineCounter := ToLineCounter + 1;
                                IF IsTimeForUpdate THEN
                                    Window.UPDATE(2, ToLineCounter);
                                IF CopySalesLine(
                                  ToSalesHeader, ToSalesLine, FromSalesHeader, FromSalesLineBuf, NextLineNo, LinesNotCopied, FALSE)
                                THEN BEGIN
                                    CopyFromPstdSalesDocDimToLine(
                                      ToSalesLine, SalesDocType::"Posted Return Receipt",
                                      FromSalesShptLine, FromSalesInvLine, FromReturnRcptLine, FromSalesCrMemoLine);

                                    IF CopyItemTrkg THEN BEGIN
                                        IF SplitLine THEN BEGIN
                                            TempItemTrkgEntry.RESET;
                                            TempItemTrkgEntry.SETCURRENTKEY("Source ID", "Source Ref. No.");
                                            TempItemTrkgEntry.SETRANGE("Source ID", FromSalesLineBuf."Document No.");
                                            TempItemTrkgEntry.SETRANGE("Source Ref. No.", FromSalesLineBuf."Line No.");
                                            CollectItemTrkgPerPstDocLine(TempItemTrkgEntry, TempTrkgItemLedgEntry, FALSE);
                                        END ELSE
                                            ItemTrackingMgt.CollectItemTrkgPerPstdDocLine(TempTrkgItemLedgEntry, ItemLedgEntry);

                                        ItemTrackingMgt.CopyItemLedgEntryTrkgToSalesLn(
                                          TempTrkgItemLedgEntry, ToSalesLine,
                                          FillExactCostRevLink AND ExactCostRevMandatory, MissingExCostRevLink,
                                          FromSalesHeader."Prices Including VAT", ToSalesHeader."Prices Including VAT", TRUE);
                                    END;

                                    CopyReturnRcptExtTextToDoc(
                                      ToSalesHeader, ToSalesLine, FromReturnRcptLine, FromSalesHeader."Language Code",
                                      NextLineNo, FromSalesLineBuf."Appl.-from Item Entry" <> 0);
                                END;
                            UNTIL FromSalesLineBuf.NEXT = 0
                    END;
                UNTIL NEXT = 0;

        Window.CLOSE;
    end;

    local procedure CopyReturnRcptExtTextToDoc(ToSalesHeader: Record "Sales Header"; ToSalesLine: Record "Sales Line"; FromReturnRcptLine: Record "Return Receipt Line"; FromLanguageCode: Code[10]; var NextLineNo: Integer; ExactCostReverse: Boolean)
    var
        ToSalesLine2: Record "Sales Line";
        FromSalesShptLine: Record "Sales Shipment Line";
        FromSalesInvLine: Record "Sales Invoice Line";
        FromSalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        ToSalesLine2.SETRANGE("Document No.", ToSalesLine."Document No.");
        ToSalesLine2.SETRANGE("Attached to Line No.", ToSalesLine."Line No.");
        IF ToSalesLine2.ISEMPTY THEN
            WITH FromReturnRcptLine DO BEGIN
                SETRANGE("Document No.", "Document No.");
                SETRANGE("Attached to Line No.", "Line No.");
                IF FINDSET THEN
                    REPEAT
                        IF (ToSalesHeader."Language Code" <> FromLanguageCode) OR
                           (RecalculateLines AND NOT ExactCostReverse)
                        THEN BEGIN
                            IF TransferExtendedText.SalesCheckIfAnyExtText(ToSalesLine, FALSE) THEN BEGIN
                                TransferExtendedText.InsertSalesExtText(ToSalesLine);
                                NextLineNo := GetLastToSalesLineNo(ToSalesHeader);
                            END;
                        END ELSE BEGIN
                            CopySalesExtTextLines(
                              ToSalesLine2, ToSalesLine, Description, "Description 2", NextLineNo);
                            CopyFromPstdSalesDocDimToLine(
                              ToSalesLine2, SalesDocType::"Posted Return Receipt", FromSalesShptLine,
                              FromSalesInvLine, FromReturnRcptLine, FromSalesCrMemoLine);
                        END;
                    UNTIL NEXT = 0;
            END;
    end;

    local procedure SplitPstdSalesLinesPerILE(ToSalesHeader: Record "Sales Header"; FromSalesHeader: Record "Sales Header"; var ItemLedgEntry: Record "Item Ledger Entry"; var FromSalesLineBuf: Record "Sales Line"; FromSalesLine: Record "Sales Line"; var NextLineNo: Integer; var CopyItemTrkg: Boolean; var MissingExCostRevLink: Boolean; FillExactCostRevLink: Boolean; FromShptOrRcpt: Boolean): Boolean
    var
        OrgQtyBase: Decimal;
    begin
        IF FromShptOrRcpt THEN BEGIN
            FromSalesLineBuf.RESET;
            FromSalesLineBuf.DELETEALL;
        END ELSE
            FromSalesLineBuf.INIT;

        CopyItemTrkg := FALSE;

        IF (FromSalesLine.Type <> FromSalesLine.Type::Item) OR (FromSalesLine.Quantity = 0) THEN
            EXIT(FALSE);
        IF IsCopyItemTrkg(ItemLedgEntry, CopyItemTrkg, FillExactCostRevLink) OR
           NOT FillExactCostRevLink OR MoveNegLines OR
           NOT ExactCostRevMandatory
        THEN
            EXIT(FALSE);

        WITH ItemLedgEntry DO BEGIN
            FINDSET;
            IF Quantity >= 0 THEN BEGIN
                FromSalesLineBuf."Document No." := "Document No.";
                IF GetSalesDocType(ItemLedgEntry) IN
                   [FromSalesLineBuf."Document Type"::Order, FromSalesLineBuf."Document Type"::"Return Order"]
                THEN
                    FromSalesLineBuf."Shipment Line No." := 1;
                EXIT(FALSE);
            END;
            OrgQtyBase := FromSalesLine."Quantity (Base)";
            REPEAT
                IF "Shipped Qty. Not Returned" = 0 THEN
                    ERROR(Text030, "Document Type", "Document No.", "Document Line No.");
                FromSalesLineBuf := FromSalesLine;

                IF -"Shipped Qty. Not Returned" < ABS(FromSalesLine."Quantity (Base)") THEN BEGIN
                    IF FromSalesLine."Quantity (Base)" > 0 THEN
                        FromSalesLineBuf."Quantity (Base)" := -"Shipped Qty. Not Returned"
                    ELSE
                        FromSalesLineBuf."Quantity (Base)" := "Shipped Qty. Not Returned";
                    IF FromSalesLineBuf."Qty. per Unit of Measure" = 0 THEN
                        FromSalesLineBuf.Quantity := FromSalesLineBuf."Quantity (Base)"
                    ELSE
                        FromSalesLineBuf.Quantity :=
                          ROUND(FromSalesLineBuf."Quantity (Base)" / FromSalesLineBuf."Qty. per Unit of Measure", 0.00001);
                END;
                FromSalesLine."Quantity (Base)" := FromSalesLine."Quantity (Base)" - FromSalesLineBuf."Quantity (Base)";
                FromSalesLine.Quantity := FromSalesLine.Quantity - FromSalesLineBuf.Quantity;
                FromSalesLineBuf."Appl.-from Item Entry" := "Entry No.";
                FromSalesLineBuf."Line No." := NextLineNo;
                NextLineNo := NextLineNo + 1;
                FromSalesLineBuf."Document No." := "Document No.";
                IF GetSalesDocType(ItemLedgEntry) IN
                   [FromSalesLineBuf."Document Type"::Order, FromSalesLineBuf."Document Type"::"Return Order"]
                THEN
                    FromSalesLineBuf."Shipment Line No." := 1;

                IF NOT FromShptOrRcpt THEN
                    UpdateRevSalesLineAmount(
                      FromSalesLineBuf, OrgQtyBase,
                      FromSalesHeader."Prices Including VAT", ToSalesHeader."Prices Including VAT");

                FromSalesLineBuf.INSERT;
            UNTIL (NEXT = 0) OR (FromSalesLine."Quantity (Base)" = 0);

            IF (FromSalesLine."Quantity (Base)" <> 0) AND FillExactCostRevLink THEN
                MissingExCostRevLink := TRUE;
        END;
        EXIT(TRUE);
    end;

    local procedure SplitSalesDocLinesPerItemTrkg(var ItemLedgEntry: Record "Item Ledger Entry"; var TempItemTrkgEntry: Record "Reservation Entry" temporary; var FromSalesLineBuf: Record "Sales Line"; FromSalesLine: Record "Sales Line"; var NextLineNo: Integer; var NextItemTrkgEntryNo: Integer; var MissingExCostRevLink: Boolean; FromShptOrRcpt: Boolean): Boolean
    var
        SalesLineBuf: array[2] of Record "37" temporary;
        ReversibleQtyBase: Decimal;
        SignFactor: Integer;
        i: Integer;
    begin
        IF FromShptOrRcpt THEN BEGIN
            FromSalesLineBuf.RESET;
            FromSalesLineBuf.DELETEALL;
            TempItemTrkgEntry.RESET;
            TempItemTrkgEntry.DELETEALL;
        END ELSE
            FromSalesLineBuf.INIT;

        IF MoveNegLines OR NOT ExactCostRevMandatory THEN
            EXIT(FALSE);

        IF FromSalesLine."Quantity (Base)" < 0 THEN
            SignFactor := -1
        ELSE
            SignFactor := 1;

        WITH ItemLedgEntry DO BEGIN
            SETCURRENTKEY("Document No.", "Document Type", "Document Line No.");
            FINDSET;
            REPEAT
                SalesLineBuf[1] := FromSalesLine;
                SalesLineBuf[1]."Line No." := NextLineNo;
                SalesLineBuf[1]."Quantity (Base)" := 0;
                SalesLineBuf[1].Quantity := 0;
                SalesLineBuf[1]."Document No." := "Document No.";
                IF GetSalesDocType(ItemLedgEntry) IN
                   [SalesLineBuf[1]."Document Type"::Order, SalesLineBuf[1]."Document Type"::"Return Order"]
                THEN
                    SalesLineBuf[1]."Shipment Line No." := 1;
                SalesLineBuf[2] := SalesLineBuf[1];
                SalesLineBuf[2]."Line No." := SalesLineBuf[2]."Line No." + 1;

                IF NOT FromShptOrRcpt THEN BEGIN
                    SETRANGE("Document No.", "Document No.");
                    SETRANGE("Document Type", "Document Type");
                    SETRANGE("Document Line No.", "Document Line No.");
                END;
                REPEAT
                    i := 1;
                    IF NOT Positive THEN
                        "Shipped Qty. Not Returned" :=
                          "Shipped Qty. Not Returned" -
                          CalcDistributedQty(TempItemTrkgEntry, ItemLedgEntry, SalesLineBuf[2]."Line No." + 1);

                    IF -"Shipped Qty. Not Returned" < FromSalesLine."Quantity (Base)" * SignFactor THEN
                        ReversibleQtyBase := -"Shipped Qty. Not Returned" * SignFactor
                    ELSE
                        ReversibleQtyBase := FromSalesLine."Quantity (Base)";

                    IF ReversibleQtyBase <> 0 THEN BEGIN
                        IF NOT Positive THEN
                            IF IsSplitItemLedgEntry(ItemLedgEntry) THEN
                                i := 2;

                        SalesLineBuf[i]."Quantity (Base)" := SalesLineBuf[i]."Quantity (Base)" + ReversibleQtyBase;
                        IF SalesLineBuf[i]."Qty. per Unit of Measure" = 0 THEN
                            SalesLineBuf[i].Quantity := SalesLineBuf[i]."Quantity (Base)"
                        ELSE
                            SalesLineBuf[i].Quantity :=
                              ROUND(SalesLineBuf[i]."Quantity (Base)" / SalesLineBuf[i]."Qty. per Unit of Measure", 0.00001);
                        FromSalesLine."Quantity (Base)" := FromSalesLine."Quantity (Base)" - ReversibleQtyBase;

                        // Fill buffer with exact cost reversing link
                        InsertTempItemTrkgEntry(
                          ItemLedgEntry, TempItemTrkgEntry, -ABS(ReversibleQtyBase),
                          SalesLineBuf[i]."Line No.", NextItemTrkgEntryNo, TRUE);
                    END;
                UNTIL (NEXT = 0) OR (FromSalesLine."Quantity (Base)" = 0);

                FOR i := 1 TO 2 DO
                    IF SalesLineBuf[i]."Quantity (Base)" <> 0 THEN BEGIN
                        FromSalesLineBuf := SalesLineBuf[i];
                        FromSalesLineBuf.INSERT;
                        NextLineNo := SalesLineBuf[i]."Line No." + 1;
                    END;

                IF NOT FromShptOrRcpt THEN BEGIN
                    SETRANGE("Document No.");
                    SETRANGE("Document Type");
                    SETRANGE("Document Line No.");
                END;
            UNTIL (NEXT = 0) OR FromShptOrRcpt;

            IF (FromSalesLine."Quantity (Base)" <> 0) AND NOT Positive AND TempItemTrkgEntry.ISEMPTY THEN
                MissingExCostRevLink := TRUE;
        END;

        EXIT(TRUE);
    end;

    procedure CopyPurchRcptLinesToDoc(ToPurchHeader: Record "Purchase Header"; var FromPurchRcptLine: Record "Purch. Rcpt. Line"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        TempTrkgItemLedgEntry: Record "Item Ledger Entry" temporary;
        FromPurchHeader: Record "Purchase Header";
        FromPurchLine: Record "Purchase Line";
        ToPurchLine: Record "Purchase Line";
        FromPurchLineBuf: Record "Purchase Line" temporary;
        FromPurchRcptHeader: Record "Purch. Rcpt. Header";
        FromPurchInvLine: Record "Purch. Inv. Line";
        FromReturnShptLine: Record "Return Shipment Line";
        FromPurchCrMemoLine: Record "Purch. Cr. Memo Line";
        TempItemTrkgEntry: Record "Reservation Entry" temporary;
        ItemTrackingMgt: Codeunit "6500";
        OldDocNo: Code[20];
        NextLineNo: Integer;
        NextItemTrkgEntryNo: Integer;
        FromLineCounter: Integer;
        ToLineCounter: Integer;
        CopyItemTrkg: Boolean;
        FillExactCostRevLink: Boolean;
        SplitLine: Boolean;
        CopyLine: Boolean;
        InsertDocNoLine: Boolean;
    begin
        MissingExCostRevLink := FALSE;
        InitCurrency(ToPurchHeader."Currency Code");
        OpenWindow;

        WITH FromPurchRcptLine DO
            IF FINDSET THEN
                REPEAT
                    FromLineCounter := FromLineCounter + 1;
                    IF IsTimeForUpdate THEN
                        Window.UPDATE(1, FromLineCounter);
                    IF FromPurchRcptHeader."No." <> "Document No." THEN BEGIN
                        FromPurchRcptHeader.GET("Document No.");
                        TransferOldExtLines.ClearLineNumbers;
                    END;
                    FromPurchHeader.TRANSFERFIELDS(FromPurchRcptHeader);
                    FillExactCostRevLink :=
                      IsPurchFillExactCostRevLink(ToPurchHeader, 0, FromPurchHeader."Currency Code");
                    FromPurchLine.TRANSFERFIELDS(FromPurchRcptLine);
                    FromPurchLine."Appl.-to Item Entry" := 0;

                    IF "Document No." <> OldDocNo THEN BEGIN
                        OldDocNo := "Document No.";
                        InsertDocNoLine := TRUE;
                    END;

                    SplitLine := TRUE;
                    FilterPstdDocLnItemLedgEntries(ItemLedgEntry);
                    IF NOT SplitPstdPurchLinesPerILE(
                         ToPurchHeader, FromPurchHeader, ItemLedgEntry, FromPurchLineBuf,
                         FromPurchLine, NextLineNo, CopyItemTrkg, MissingExCostRevLink, FillExactCostRevLink, TRUE)
                    THEN
                        IF CopyItemTrkg THEN
                            SplitLine :=
                              SplitPurchDocLinesPerItemTrkg(
                                ItemLedgEntry, TempItemTrkgEntry, FromPurchLineBuf,
                                FromPurchLine, NextLineNo, NextItemTrkgEntryNo, MissingExCostRevLink, TRUE)
                        ELSE
                            SplitLine := FALSE;

                    IF NOT SplitLine THEN BEGIN
                        FromPurchLineBuf := FromPurchLine;
                        CopyLine := TRUE;
                    END ELSE
                        CopyLine := FromPurchLineBuf.FINDSET AND FillExactCostRevLink;

                    Window.UPDATE(1, FromLineCounter);
                    IF CopyLine THEN BEGIN
                        NextLineNo := GetLastToPurchLineNo(ToPurchHeader);
                        IF InsertDocNoLine THEN BEGIN
                            InsertOldPurchDocNoLine(ToPurchHeader, "Document No.", 1, NextLineNo);
                            InsertDocNoLine := FALSE;
                        END;
                        IF (FromPurchLineBuf.Type <> FromPurchLineBuf.Type::" ") OR
                           (FromPurchLineBuf."Attached to Line No." = 0)
                        THEN
                            REPEAT
                                ToLineCounter := ToLineCounter + 1;
                                IF IsTimeForUpdate THEN
                                    Window.UPDATE(2, ToLineCounter);
                                IF FromPurchLine."Prod. Order No." <> '' THEN
                                    FromPurchLine."Quantity (Base)" := 0;
                                IF CopyPurchLine(
                                  ToPurchHeader, ToPurchLine, FromPurchHeader, FromPurchLineBuf, NextLineNo, LinesNotCopied, FALSE)
                                THEN BEGIN
                                    CopyFromPstdPurchDocDimToLine(
                                      ToPurchLine, PurchDocType::"Posted Receipt",
                                      FromPurchRcptLine, FromPurchInvLine, FromReturnShptLine, FromPurchCrMemoLine);

                                    IF CopyItemTrkg THEN BEGIN
                                        IF SplitLine THEN BEGIN
                                            TempItemTrkgEntry.RESET;
                                            TempItemTrkgEntry.SETCURRENTKEY("Source ID", "Source Ref. No.");
                                            TempItemTrkgEntry.SETRANGE("Source ID", FromPurchLineBuf."Document No.");
                                            TempItemTrkgEntry.SETRANGE("Source Ref. No.", FromPurchLineBuf."Line No.");
                                            CollectItemTrkgPerPstDocLine(TempItemTrkgEntry, TempTrkgItemLedgEntry, TRUE);
                                        END ELSE
                                            ItemTrackingMgt.CollectItemTrkgPerPstdDocLine(TempTrkgItemLedgEntry, ItemLedgEntry);

                                        ItemTrackingMgt.CopyItemLedgEntryTrkgToPurchLn(
                                          TempTrkgItemLedgEntry, ToPurchLine,
                                          FillExactCostRevLink AND ExactCostRevMandatory, MissingExCostRevLink,
                                          FromPurchHeader."Prices Including VAT", ToPurchHeader."Prices Including VAT", TRUE);
                                    END;

                                    CopyPurchRcptExtTextToDoc(
                                      ToPurchHeader, ToPurchLine, FromPurchRcptLine, FromPurchHeader."Language Code",
                                      NextLineNo, FromPurchLineBuf."Appl.-to Item Entry" <> 0);
                                END;
                            UNTIL FromPurchLineBuf.NEXT = 0
                    END;
                UNTIL NEXT = 0;

        Window.CLOSE;
    end;

    local procedure CopyPurchRcptExtTextToDoc(ToPurchHeader: Record "Purchase Header"; ToPurchLine: Record "Purchase Line"; FromPurchRcptLine: Record "Purch. Rcpt. Line"; FromLanguageCode: Code[10]; var NextLineNo: Integer; ExactCostReverse: Boolean)
    var
        ToPurchLine2: Record "Purchase Line";
        FromPurchInvLine: Record "Purch. Inv. Line";
        FromReturnShptLine: Record "Return Shipment Line";
        FromPurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        ToPurchLine2.SETRANGE("Document No.", ToPurchLine."Document No.");
        ToPurchLine2.SETRANGE("Attached to Line No.", ToPurchLine."Line No.");
        IF ToPurchLine2.ISEMPTY THEN
            WITH FromPurchRcptLine DO BEGIN
                SETRANGE("Document No.", "Document No.");
                SETRANGE("Attached to Line No.", "Line No.");
                IF FINDSET THEN
                    REPEAT
                        IF (ToPurchHeader."Language Code" <> FromLanguageCode) OR
                           (RecalculateLines AND NOT ExactCostReverse)
                        THEN BEGIN
                            IF TransferExtendedText.PurchCheckIfAnyExtText(ToPurchLine, FALSE) THEN BEGIN
                                TransferExtendedText.InsertPurchExtText(ToPurchLine);
                                NextLineNo := GetLastToPurchLineNo(ToPurchHeader);
                            END;
                        END ELSE BEGIN
                            CopyPurchExtTextLines(
                              ToPurchLine2, ToPurchLine, Description, "Description 2", NextLineNo);
                            CopyFromPstdPurchDocDimToLine(
                              ToPurchLine2, PurchDocType::"Posted Receipt", FromPurchRcptLine,
                              FromPurchInvLine, FromReturnShptLine, FromPurchCrMemoLine);
                        END;
                    UNTIL NEXT = 0;
            END;
    end;

    procedure CopyPurchInvLinesToDoc(ToPurchHeader: Record "Purchase Header"; var FromPurchInvLine: Record "Purch. Inv. Line"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    var
        ItemLedgEntryBuf: Record "Item Ledger Entry" temporary;
        TempTrkgItemLedgEntry: Record "Item Ledger Entry" temporary;
        FromPurchHeader: Record "Purchase Header";
        FromPurchLine: Record "Purchase Line";
        FromPurchLine2: Record "Purchase Line";
        ToPurchLine: Record "Purchase Line";
        FromPurchLineBuf: Record "Purchase Line" temporary;
        FromPurchInvHeader: Record "Purch. Inv. Header";
        FromPurchRcptLine: Record "Purch. Rcpt. Line";
        FromReturnShptLine: Record "Return Shipment Line";
        FromPurchCrMemoLine: Record "Purch. Cr. Memo Line";
        TempItemTrkgEntry: Record "Reservation Entry" temporary;
        ItemTrackingMgt: Codeunit "6500";
        OldInvDocNo: Code[20];
        OldRcptDocNo: Code[20];
        NextLineNo: Integer;
        NextItemTrkgEntryNo: Integer;
        FromLineCounter: Integer;
        ToLineCounter: Integer;
        CopyItemTrkg: Boolean;
        SplitLine: Boolean;
        FillExactCostRevLink: Boolean;
    begin
        MissingExCostRevLink := FALSE;
        InitCurrency(ToPurchHeader."Currency Code");
        FromPurchLineBuf.RESET;
        FromPurchLineBuf.DELETEALL;
        TempItemTrkgEntry.RESET;
        TempItemTrkgEntry.DELETEALL;
        OpenWindow;

        // Fill purchase line buffer
        WITH FromPurchInvLine DO
            IF FINDSET THEN
                REPEAT
                    FromLineCounter := FromLineCounter + 1;
                    IF IsTimeForUpdate THEN
                        Window.UPDATE(1, FromLineCounter);
                    IF FromPurchInvHeader."No." <> "Document No." THEN BEGIN
                        FromPurchInvHeader.GET("Document No.");
                        TransferOldExtLines.ClearLineNumbers;
                    END;
                    FromPurchHeader.TRANSFERFIELDS(FromPurchInvHeader);
                    FillExactCostRevLink :=
                      IsPurchFillExactCostRevLink(ToPurchHeader, 1, FromPurchHeader."Currency Code");
                    FromPurchLine.TRANSFERFIELDS(FromPurchInvLine);
                    FromPurchLine."Appl.-to Item Entry" := 0;
                    // Reuse fields to buffer invoice line information
                    FromPurchLine."Receipt No." := "Document No.";
                    FromPurchLine."Receipt Line No." := 0;
                    FromPurchLine."Return Shipment No." := '';
                    FromPurchLine."Return Shipment Line No." := "Line No.";

                    SplitLine := TRUE;
                    GetItemLedgEntries(ItemLedgEntryBuf, TRUE);
                    IF NOT SplitPstdPurchLinesPerILE(
                         ToPurchHeader, FromPurchHeader, ItemLedgEntryBuf, FromPurchLineBuf,
                         FromPurchLine, NextLineNo, CopyItemTrkg, MissingExCostRevLink, FillExactCostRevLink, FALSE)
                    THEN
                        IF CopyItemTrkg THEN
                            SplitLine :=
                              SplitPurchDocLinesPerItemTrkg(
                                ItemLedgEntryBuf, TempItemTrkgEntry, FromPurchLineBuf,
                                FromPurchLine, NextLineNo, NextItemTrkgEntryNo, MissingExCostRevLink, FALSE)
                        ELSE
                            SplitLine := FALSE;

                    IF NOT SplitLine THEN BEGIN
                        FromPurchLine2 := FromPurchLineBuf;
                        FromPurchLineBuf := FromPurchLine;
                        FromPurchLineBuf."Document No." := FromPurchLine2."Document No.";
                        FromPurchLineBuf."Receipt Line No." := FromPurchLine2."Receipt Line No.";
                        FromPurchLineBuf."Line No." := NextLineNo;
                        NextLineNo := NextLineNo + 1;
                        IF NOT IsRecalculateAmount(
                             FromPurchHeader."Currency Code", ToPurchHeader."Currency Code",
                             FromPurchHeader."Prices Including VAT", ToPurchHeader."Prices Including VAT")
                        THEN
                            FromPurchLineBuf."Return Shipment No." := "Document No.";
                        ReCalcPurchLine(FromPurchHeader, ToPurchHeader, FromPurchLineBuf);
                        FromPurchLineBuf.INSERT;
                    END;
                UNTIL NEXT = 0;

        // Create purchase line from buffer
        Window.UPDATE(1, FromLineCounter);
        WITH FromPurchLineBuf DO BEGIN
            // Sorting according to Purchase Line Document No.,Line No.
            SETCURRENTKEY("Document Type", "Document No.", "Line No.");
            IF FINDSET THEN BEGIN
                NextLineNo := GetLastToPurchLineNo(ToPurchHeader);
                REPEAT
                    ToLineCounter := ToLineCounter + 1;
                    IF IsTimeForUpdate THEN
                        Window.UPDATE(2, ToLineCounter);
                    IF "Receipt No." <> OldInvDocNo THEN BEGIN
                        OldInvDocNo := "Receipt No.";
                        OldRcptDocNo := '';
                        InsertOldPurchDocNoLine(ToPurchHeader, OldInvDocNo, 2, NextLineNo);
                    END;
                    IF "Document No." <> OldRcptDocNo THEN BEGIN
                        OldRcptDocNo := "Document No.";
                        InsertOldPurchCombDocNoLine(ToPurchHeader, OldInvDocNo, OldRcptDocNo, NextLineNo, TRUE);
                    END;

                    IF (Type <> Type::" ") OR ("Attached to Line No." = 0) THEN BEGIN
                        // Empty buffer fields
                        FromPurchLine2 := FromPurchLineBuf;
                        FromPurchLine2."Receipt No." := '';
                        FromPurchLine2."Receipt Line No." := 0;
                        FromPurchLine2."Return Shipment No." := '';
                        FromPurchLine2."Return Shipment Line No." := 0;

                        IF CopyPurchLine(
                          ToPurchHeader, ToPurchLine, FromPurchHeader,
                          FromPurchLine2, NextLineNo, LinesNotCopied, "Return Shipment No." = '')
                        THEN BEGIN
                            FromPurchInvLine.GET("Receipt No.", "Return Shipment Line No.");
                            CopyFromPstdPurchDocDimToLine(
                              ToPurchLine, PurchDocType::"Posted Invoice",
                              FromPurchRcptLine, FromPurchInvLine, FromReturnShptLine, FromPurchCrMemoLine);

                            // copy item tracking
                            IF (Type = Type::Item) AND (Quantity <> 0) AND ("Prod. Order No." = '') THEN BEGIN
                                FromPurchInvLine."Document No." := OldInvDocNo;
                                FromPurchInvLine."Line No." := "Return Shipment Line No.";
                                FromPurchInvLine.GetItemLedgEntries(ItemLedgEntryBuf, TRUE);
                                IF IsCopyItemTrkg(ItemLedgEntryBuf, CopyItemTrkg, FillExactCostRevLink) THEN BEGIN
                                    IF ("Job No." <> '') THEN
                                        ItemLedgEntryBuf.SETFILTER("Entry Type", '<> %1', ItemLedgEntryBuf."Entry Type"::"Negative Adjmt.");
                                    IF MoveNegLines OR NOT ExactCostRevMandatory THEN
                                        ItemTrackingMgt.CollectItemTrkgPerPstdDocLine(TempTrkgItemLedgEntry, ItemLedgEntryBuf)
                                    ELSE BEGIN
                                        TempItemTrkgEntry.RESET;
                                        TempItemTrkgEntry.SETCURRENTKEY("Source ID", "Source Ref. No.");
                                        TempItemTrkgEntry.SETRANGE("Source ID", "Document No.");
                                        TempItemTrkgEntry.SETRANGE("Source Ref. No.", "Line No.");
                                        CollectItemTrkgPerPstDocLine(TempItemTrkgEntry, TempTrkgItemLedgEntry, TRUE);
                                    END;

                                    ItemTrackingMgt.CopyItemLedgEntryTrkgToPurchLn(
                                      TempTrkgItemLedgEntry, ToPurchLine,
                                      FillExactCostRevLink AND ExactCostRevMandatory,
                                      MissingExCostRevLink, FromPurchHeader."Prices Including VAT",
                                      ToPurchHeader."Prices Including VAT", FALSE);
                                END;
                            END;

                            CopyPurchInvExtTextToDoc(
                              ToPurchHeader, ToPurchLine, FromPurchHeader."Language Code", "Receipt No.",
                              "Return Shipment Line No.", NextLineNo, "Appl.-to Item Entry" <> 0);
                        END;
                    END;
                UNTIL NEXT = 0;
            END;
        END;

        Window.CLOSE;
    end;

    local procedure CopyPurchInvExtTextToDoc(ToPurchHeader: Record "Purchase Header"; ToPurchLine: Record "Purchase Line"; FromLanguageCode: Code[10]; FromInvDocNo: Code[20]; FromInvDocLineNo: Integer; var NextLineNo: Integer; ExactCostReverse: Boolean)
    var
        ToPurchLine2: Record "Purchase Line";
        FromPurchRcptLine: Record "Purch. Rcpt. Line";
        FromPurchInvLine: Record "Purch. Inv. Line";
        FromReturnShptLine: Record "Return Shipment Line";
        FromPurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        ToPurchLine2.SETRANGE("Document No.", ToPurchLine."Document No.");
        ToPurchLine2.SETRANGE("Attached to Line No.", ToPurchLine."Line No.");
        IF ToPurchLine2.ISEMPTY THEN
            WITH FromPurchInvLine DO BEGIN
                SETRANGE("Document No.", FromInvDocNo);
                SETRANGE("Attached to Line No.", FromInvDocLineNo);
                IF FINDSET THEN
                    REPEAT
                        IF (ToPurchHeader."Language Code" <> FromLanguageCode) OR
                           (RecalculateLines AND NOT ExactCostReverse)
                        THEN BEGIN
                            IF TransferExtendedText.PurchCheckIfAnyExtText(ToPurchLine, FALSE) THEN BEGIN
                                TransferExtendedText.InsertPurchExtText(ToPurchLine);
                                NextLineNo := GetLastToPurchLineNo(ToPurchHeader);
                            END;
                        END ELSE BEGIN
                            CopyPurchExtTextLines(
                              ToPurchLine2, ToPurchLine, Description, "Description 2", NextLineNo);
                            CopyFromPstdPurchDocDimToLine(
                              ToPurchLine2, PurchDocType::"Posted Invoice", FromPurchRcptLine,
                              FromPurchInvLine, FromReturnShptLine, FromPurchCrMemoLine);
                        END;
                    UNTIL NEXT = 0;
            END;
    end;

    procedure CopyPurchCrMemoLinesToDoc(ToPurchHeader: Record "Purchase Header"; var FromPurchCrMemoLine: Record "Purch. Cr. Memo Line"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    var
        ItemLedgEntryBuf: Record "Item Ledger Entry" temporary;
        TempTrkgItemLedgEntry: Record "Item Ledger Entry" temporary;
        FromPurchHeader: Record "Purchase Header";
        FromPurchLine: Record "Purchase Line";
        FromPurchLine2: Record "Purchase Line";
        ToPurchLine: Record "Purchase Line";
        FromPurchLineBuf: Record "Purchase Line" temporary;
        FromPurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        FromPurchRcptLine: Record "Purch. Rcpt. Line";
        FromReturnShptLine: Record "Return Shipment Line";
        FromPurchInvLine: Record "Purch. Inv. Line";
        TempItemTrkgEntry: Record "Reservation Entry" temporary;
        ItemTrackingMgt: Codeunit "6500";
        OldCrMemoDocNo: Code[20];
        OldReturnShptDocNo: Code[20];
        NextLineNo: Integer;
        NextItemTrkgEntryNo: Integer;
        FromLineCounter: Integer;
        ToLineCounter: Integer;
        CopyItemTrkg: Boolean;
        SplitLine: Boolean;
        FillExactCostRevLink: Boolean;
    begin
        MissingExCostRevLink := FALSE;
        InitCurrency(ToPurchHeader."Currency Code");
        FromPurchLineBuf.RESET;
        FromPurchLineBuf.DELETEALL;
        TempItemTrkgEntry.RESET;
        TempItemTrkgEntry.DELETEALL;
        OpenWindow;

        // Fill purchase line buffer
        WITH FromPurchCrMemoLine DO
            IF FINDSET THEN
                REPEAT
                    FromLineCounter := FromLineCounter + 1;
                    IF IsTimeForUpdate THEN
                        Window.UPDATE(1, FromLineCounter);
                    IF FromPurchCrMemoHeader."No." <> "Document No." THEN BEGIN
                        FromPurchCrMemoHeader.GET("Document No.");
                        TransferOldExtLines.ClearLineNumbers;
                    END;
                    FromPurchHeader.TRANSFERFIELDS(FromPurchCrMemoHeader);
                    FillExactCostRevLink :=
                      IsPurchFillExactCostRevLink(ToPurchHeader, 3, FromPurchHeader."Currency Code");
                    FromPurchLine.TRANSFERFIELDS(FromPurchCrMemoLine);
                    FromPurchLine."Appl.-to Item Entry" := 0;
                    // Reuse fields to buffer credit memo line information
                    FromPurchLine."Receipt No." := "Document No.";
                    FromPurchLine."Receipt Line No." := 0;
                    FromPurchLine."Return Shipment No." := '';
                    FromPurchLine."Return Shipment Line No." := "Line No.";

                    SplitLine := TRUE;
                    GetItemLedgEntries(ItemLedgEntryBuf, TRUE);
                    IF NOT SplitPstdPurchLinesPerILE(
                         ToPurchHeader, FromPurchHeader, ItemLedgEntryBuf, FromPurchLineBuf,
                         FromPurchLine, NextLineNo, CopyItemTrkg, MissingExCostRevLink, FillExactCostRevLink, FALSE)
                    THEN
                        IF CopyItemTrkg THEN
                            SplitLine :=
                              SplitPurchDocLinesPerItemTrkg(
                                ItemLedgEntryBuf, TempItemTrkgEntry, FromPurchLineBuf,
                                FromPurchLine, NextLineNo, NextItemTrkgEntryNo, MissingExCostRevLink, FALSE)
                        ELSE
                            SplitLine := FALSE;

                    IF NOT SplitLine THEN BEGIN
                        FromPurchLine2 := FromPurchLineBuf;
                        FromPurchLineBuf := FromPurchLine;
                        FromPurchLineBuf."Document No." := FromPurchLine2."Document No.";
                        FromPurchLineBuf."Receipt Line No." := FromPurchLine2."Receipt Line No.";
                        FromPurchLineBuf."Line No." := NextLineNo;
                        NextLineNo := NextLineNo + 1;
                        IF NOT IsRecalculateAmount(
                             FromPurchHeader."Currency Code", ToPurchHeader."Currency Code",
                             FromPurchHeader."Prices Including VAT", ToPurchHeader."Prices Including VAT")
                        THEN
                            FromPurchLineBuf."Return Shipment No." := "Document No.";
                        ReCalcPurchLine(FromPurchHeader, ToPurchHeader, FromPurchLineBuf);
                        FromPurchLineBuf.INSERT;
                    END;

                UNTIL NEXT = 0;

        // Create purchase line from buffer
        Window.UPDATE(1, FromLineCounter);
        WITH FromPurchLineBuf DO BEGIN
            // Sorting according to Purchase Line Document No.,Line No.
            SETCURRENTKEY("Document Type", "Document No.", "Line No.");
            IF FINDSET THEN BEGIN
                NextLineNo := GetLastToPurchLineNo(ToPurchHeader);
                REPEAT
                    ToLineCounter := ToLineCounter + 1;
                    IF IsTimeForUpdate THEN
                        Window.UPDATE(2, ToLineCounter);
                    IF "Receipt No." <> OldCrMemoDocNo THEN BEGIN
                        OldCrMemoDocNo := "Receipt No.";
                        OldReturnShptDocNo := '';
                        InsertOldPurchDocNoLine(ToPurchHeader, OldCrMemoDocNo, 4, NextLineNo);
                    END;
                    IF "Document No." <> OldReturnShptDocNo THEN BEGIN
                        OldReturnShptDocNo := "Document No.";
                        InsertOldPurchCombDocNoLine(ToPurchHeader, OldCrMemoDocNo, OldReturnShptDocNo, NextLineNo, FALSE);
                    END;

                    IF (Type <> Type::" ") OR ("Attached to Line No." = 0) THEN BEGIN
                        // Empty buffer fields
                        FromPurchLine2 := FromPurchLineBuf;
                        FromPurchLine2."Receipt No." := '';
                        FromPurchLine2."Receipt Line No." := 0;
                        FromPurchLine2."Return Shipment No." := '';
                        FromPurchLine2."Return Shipment Line No." := 0;

                        IF CopyPurchLine(
                          ToPurchHeader, ToPurchLine, FromPurchHeader,
                          FromPurchLine2, NextLineNo, LinesNotCopied, "Return Shipment No." = '')
                        THEN BEGIN
                            FromPurchCrMemoLine.GET("Receipt No.", "Return Shipment Line No.");
                            CopyFromPstdPurchDocDimToLine(
                              ToPurchLine, PurchDocType::"Posted Credit Memo",
                              FromPurchRcptLine, FromPurchInvLine, FromReturnShptLine, FromPurchCrMemoLine);

                            // copy item tracking
                            IF (Type = Type::Item) AND (Quantity <> 0) AND ("Prod. Order No." = '') THEN BEGIN
                                FromPurchCrMemoLine."Document No." := OldCrMemoDocNo;
                                FromPurchCrMemoLine."Line No." := "Return Shipment Line No.";
                                FromPurchCrMemoLine.GetItemLedgEntries(ItemLedgEntryBuf, TRUE);
                                IF IsCopyItemTrkg(ItemLedgEntryBuf, CopyItemTrkg, FillExactCostRevLink) THEN BEGIN
                                    IF ("Job No." <> '') THEN
                                        ItemLedgEntryBuf.SETFILTER("Entry Type", '<> %1', ItemLedgEntryBuf."Entry Type"::"Negative Adjmt.");
                                    IF MoveNegLines OR NOT ExactCostRevMandatory THEN
                                        ItemTrackingMgt.CollectItemTrkgPerPstdDocLine(TempTrkgItemLedgEntry, ItemLedgEntryBuf)
                                    ELSE BEGIN
                                        TempItemTrkgEntry.RESET;
                                        TempItemTrkgEntry.SETCURRENTKEY("Source ID", "Source Ref. No.");
                                        TempItemTrkgEntry.SETRANGE("Source ID", "Document No.");
                                        TempItemTrkgEntry.SETRANGE("Source Ref. No.", "Line No.");
                                        CollectItemTrkgPerPstDocLine(TempItemTrkgEntry, TempTrkgItemLedgEntry, TRUE);
                                    END;

                                    ItemTrackingMgt.CopyItemLedgEntryTrkgToPurchLn(
                                      TempTrkgItemLedgEntry, ToPurchLine,
                                      FillExactCostRevLink AND ExactCostRevMandatory, MissingExCostRevLink,
                                      FromPurchHeader."Prices Including VAT", ToPurchHeader."Prices Including VAT", FALSE);
                                END;
                            END;

                            CopyPurchInvExtTextToDoc(
                              ToPurchHeader, ToPurchLine, FromPurchHeader."Language Code", "Receipt No.",
                              "Return Shipment Line No.", NextLineNo, "Appl.-to Item Entry" <> 0);

                        END;
                    END;
                UNTIL NEXT = 0;
            END;
        END;

        Window.CLOSE;
    end;

    local procedure CopyPurchCrMemoExtTextToDoc(ToPurchHeader: Record "Purchase Header"; ToPurchLine: Record "Purchase Line"; FromLanguageCode: Code[10]; FromCrMemoDocNo: Code[20]; FromCrMemoDocLineNo: Integer; var NextLineNo: Integer; ExactCostReverse: Boolean)
    var
        ToPurchLine2: Record "Purchase Line";
        FromPurchRcptLine: Record "Purch. Rcpt. Line";
        FromPurchInvLine: Record "Purch. Inv. Line";
        FromPurchCrMemoLine: Record "Purch. Cr. Memo Line";
        FromReturnShptLine: Record "Return Shipment Line";
    begin
        ToPurchLine2.SETRANGE("Document No.", ToPurchLine."Document No.");
        ToPurchLine2.SETRANGE("Attached to Line No.", ToPurchLine."Line No.");
        IF ToPurchLine2.ISEMPTY THEN
            WITH FromPurchCrMemoLine DO BEGIN
                SETRANGE("Document No.", FromCrMemoDocNo);
                SETRANGE("Attached to Line No.", FromCrMemoDocLineNo);
                IF FINDSET THEN
                    REPEAT
                        IF (ToPurchHeader."Language Code" <> FromLanguageCode) OR
                           (RecalculateLines AND NOT ExactCostReverse)
                        THEN BEGIN
                            IF TransferExtendedText.PurchCheckIfAnyExtText(ToPurchLine, FALSE) THEN BEGIN
                                TransferExtendedText.InsertPurchExtText(ToPurchLine);
                                NextLineNo := GetLastToPurchLineNo(ToPurchHeader);
                            END;
                        END ELSE BEGIN
                            CopyPurchExtTextLines(
                              ToPurchLine2, ToPurchLine, Description, "Description 2", NextLineNo);
                            CopyFromPstdPurchDocDimToLine(
                              ToPurchLine2, PurchDocType::"Posted Credit Memo", FromPurchRcptLine,
                              FromPurchInvLine, FromReturnShptLine, FromPurchCrMemoLine);
                        END;
                    UNTIL NEXT = 0;
            END;
    end;

    procedure CopyPurchReturnShptLinesToDoc(ToPurchHeader: Record "Purchase Header"; var FromReturnShptLine: Record "Return Shipment Line"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        TempTrkgItemLedgEntry: Record "Item Ledger Entry" temporary;
        FromPurchHeader: Record "Purchase Header";
        FromPurchLine: Record "Purchase Line";
        ToPurchLine: Record "Purchase Line";
        FromPurchLineBuf: Record "Purchase Line" temporary;
        FromReturnShptHeader: Record "Return Shipment Header";
        FromPurchRcptLine: Record "Purch. Rcpt. Line";
        FromPurchInvLine: Record "Purch. Inv. Line";
        FromPurchCrMemoLine: Record "Purch. Cr. Memo Line";
        TempItemTrkgEntry: Record "Reservation Entry" temporary;
        ItemTrackingMgt: Codeunit "6500";
        OldDocNo: Code[20];
        NextLineNo: Integer;
        NextItemTrkgEntryNo: Integer;
        FromLineCounter: Integer;
        ToLineCounter: Integer;
        CopyItemTrkg: Boolean;
        SplitLine: Boolean;
        FillExactCostRevLink: Boolean;
        CopyLine: Boolean;
        InsertDocNoLine: Boolean;
    begin
        MissingExCostRevLink := FALSE;
        InitCurrency(ToPurchHeader."Currency Code");
        OpenWindow;

        WITH FromReturnShptLine DO
            IF FINDSET THEN
                REPEAT
                    FromLineCounter := FromLineCounter + 1;
                    IF IsTimeForUpdate THEN
                        Window.UPDATE(1, FromLineCounter);
                    IF FromReturnShptHeader."No." <> "Document No." THEN BEGIN
                        FromReturnShptHeader.GET("Document No.");
                        TransferOldExtLines.ClearLineNumbers;
                    END;
                    FromPurchHeader.TRANSFERFIELDS(FromReturnShptHeader);
                    FillExactCostRevLink :=
                      IsPurchFillExactCostRevLink(ToPurchHeader, 2, FromPurchHeader."Currency Code");
                    FromPurchLine.TRANSFERFIELDS(FromReturnShptLine);
                    FromPurchLine."Appl.-to Item Entry" := 0;

                    IF "Document No." <> OldDocNo THEN BEGIN
                        OldDocNo := "Document No.";
                        InsertDocNoLine := TRUE;
                    END;

                    SplitLine := TRUE;
                    FilterPstdDocLnItemLedgEntries(ItemLedgEntry);
                    IF NOT SplitPstdPurchLinesPerILE(
                         ToPurchHeader, FromPurchHeader, ItemLedgEntry, FromPurchLineBuf,
                         FromPurchLine, NextLineNo, CopyItemTrkg, MissingExCostRevLink, FillExactCostRevLink, TRUE)
                    THEN
                        IF CopyItemTrkg THEN
                            SplitLine :=
                              SplitPurchDocLinesPerItemTrkg(
                                ItemLedgEntry, TempItemTrkgEntry, FromPurchLineBuf,
                                FromPurchLine, NextLineNo, NextItemTrkgEntryNo, MissingExCostRevLink, TRUE)
                        ELSE
                            SplitLine := FALSE;

                    IF NOT SplitLine THEN BEGIN
                        FromPurchLineBuf := FromPurchLine;
                        CopyLine := TRUE;
                    END ELSE
                        CopyLine := FromPurchLineBuf.FINDSET AND FillExactCostRevLink;

                    Window.UPDATE(1, FromLineCounter);
                    IF CopyLine THEN BEGIN
                        NextLineNo := GetLastToPurchLineNo(ToPurchHeader);
                        IF InsertDocNoLine THEN BEGIN
                            InsertOldPurchDocNoLine(ToPurchHeader, "Document No.", 3, NextLineNo);
                            InsertDocNoLine := FALSE;
                        END;
                        IF (FromPurchLineBuf.Type <> FromPurchLineBuf.Type::" ") OR
                           (FromPurchLineBuf."Attached to Line No." = 0)
                        THEN
                            REPEAT
                                ToLineCounter := ToLineCounter + 1;
                                IF IsTimeForUpdate THEN
                                    Window.UPDATE(2, ToLineCounter);
                                IF CopyPurchLine(
                                  ToPurchHeader, ToPurchLine, FromPurchHeader, FromPurchLineBuf, NextLineNo, LinesNotCopied, FALSE)
                                THEN BEGIN
                                    CopyFromPstdPurchDocDimToLine(
                                      ToPurchLine, PurchDocType::"Posted Return Shipment",
                                      FromPurchRcptLine, FromPurchInvLine, FromReturnShptLine, FromPurchCrMemoLine);

                                    IF CopyItemTrkg THEN BEGIN
                                        IF SplitLine THEN BEGIN
                                            TempItemTrkgEntry.RESET;
                                            TempItemTrkgEntry.SETCURRENTKEY("Source ID", "Source Ref. No.");
                                            TempItemTrkgEntry.SETRANGE("Source ID", FromPurchLineBuf."Document No.");
                                            TempItemTrkgEntry.SETRANGE("Source Ref. No.", FromPurchLineBuf."Line No.");
                                            CollectItemTrkgPerPstDocLine(TempItemTrkgEntry, TempTrkgItemLedgEntry, TRUE);
                                        END ELSE
                                            ItemTrackingMgt.CollectItemTrkgPerPstdDocLine(TempTrkgItemLedgEntry, ItemLedgEntry);

                                        ItemTrackingMgt.CopyItemLedgEntryTrkgToPurchLn(
                                          TempTrkgItemLedgEntry, ToPurchLine,
                                          FillExactCostRevLink AND ExactCostRevMandatory, MissingExCostRevLink,
                                          FromPurchHeader."Prices Including VAT", ToPurchHeader."Prices Including VAT", TRUE);
                                    END;

                                    CopyPurchReturnShptExtTxtToDoc(
                                      ToPurchHeader, ToPurchLine, FromReturnShptLine, FromPurchHeader."Language Code",
                                      NextLineNo, FromPurchLineBuf."Appl.-to Item Entry" <> 0);
                                END;
                            UNTIL FromPurchLineBuf.NEXT = 0
                    END;
                UNTIL NEXT = 0;

        Window.CLOSE;
    end;

    local procedure CopyPurchReturnShptExtTxtToDoc(ToPurchHeader: Record "Purchase Header"; ToPurchLine: Record "Purchase Line"; FromReturnShptLine: Record "Return Shipment Line"; FromLanguageCode: Code[10]; var NextLineNo: Integer; ExactCostReverse: Boolean)
    var
        ToPurchLine2: Record "Purchase Line";
        FromPurchRcptLine: Record "Purch. Rcpt. Line";
        FromPurchInvLine: Record "Purch. Inv. Line";
        FromPurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        ToPurchLine2.SETRANGE("Document No.", ToPurchLine."Document No.");
        ToPurchLine2.SETRANGE("Attached to Line No.", ToPurchLine."Line No.");
        IF ToPurchLine2.ISEMPTY THEN
            WITH FromReturnShptLine DO BEGIN
                SETRANGE("Document No.", "Document No.");
                SETRANGE("Attached to Line No.", "Line No.");
                IF FINDSET THEN
                    REPEAT
                        IF (ToPurchHeader."Language Code" <> FromLanguageCode) OR
                           (RecalculateLines AND NOT ExactCostReverse)
                        THEN BEGIN
                            IF TransferExtendedText.PurchCheckIfAnyExtText(ToPurchLine, FALSE) THEN BEGIN
                                TransferExtendedText.InsertPurchExtText(ToPurchLine);
                                NextLineNo := GetLastToPurchLineNo(ToPurchHeader);
                            END;
                        END ELSE BEGIN
                            CopyPurchExtTextLines(
                              ToPurchLine2, ToPurchLine, Description, "Description 2", NextLineNo);
                            CopyFromPstdPurchDocDimToLine(
                              ToPurchLine2, PurchDocType::"Posted Return Shipment", FromPurchRcptLine,
                              FromPurchInvLine, FromReturnShptLine, FromPurchCrMemoLine);
                        END;
                    UNTIL NEXT = 0;
            END;
    end;

    local procedure SplitPstdPurchLinesPerILE(ToPurchHeader: Record "Purchase Header"; FromPurchHeader: Record "Purchase Header"; var ItemLedgEntry: Record "Item Ledger Entry"; var FromPurchLineBuf: Record "Purchase Line"; FromPurchLine: Record "Purchase Line"; var NextLineNo: Integer; var CopyItemTrkg: Boolean; var MissingExCostRevLink: Boolean; FillExactCostRevLink: Boolean; FromShptOrRcpt: Boolean): Boolean
    var
        OrgQtyBase: Decimal;
        ApplyRec: Record "Item Application Entry";
        AllAreFixed: Boolean;
    begin
        IF FromShptOrRcpt THEN BEGIN
            FromPurchLineBuf.RESET;
            FromPurchLineBuf.DELETEALL;
        END ELSE
            FromPurchLineBuf.INIT;

        CopyItemTrkg := FALSE;

        IF (FromPurchLine.Type <> FromPurchLine.Type::Item) OR (FromPurchLine.Quantity = 0) OR
           (FromPurchLine."Job No." <> '') OR (FromPurchLine."Prod. Order No." <> '')
        THEN
            EXIT(FALSE);
        IF IsCopyItemTrkg(ItemLedgEntry, CopyItemTrkg, FillExactCostRevLink) OR
           NOT FillExactCostRevLink OR MoveNegLines OR
           NOT ExactCostRevMandatory
        THEN
            EXIT(FALSE);

        WITH ItemLedgEntry DO BEGIN
            FINDSET;
            IF Quantity <= 0 THEN BEGIN
                FromPurchLineBuf."Document No." := "Document No.";
                IF GetPurchDocType(ItemLedgEntry) IN
                   [FromPurchLineBuf."Document Type"::Order, FromPurchLineBuf."Document Type"::"Return Order"]
                THEN
                    FromPurchLineBuf."Receipt Line No." := 1;
                EXIT(FALSE);
            END;
            OrgQtyBase := FromPurchLine."Quantity (Base)";
            REPEAT
                IF "Remaining Quantity" = 0 THEN BEGIN
                    AllAreFixed := TRUE;
                    ApplyRec.AppliedOutbndEntryExists("Entry No.", FALSE);
                    IF ApplyRec.FINDFIRST THEN
                        REPEAT
                            AllAreFixed := AllAreFixed AND ApplyRec.Fixed;
                        UNTIL ApplyRec.NEXT = 0;
                    IF AllAreFixed THEN
                        ERROR(Text030, "Document Type", "Document No.", "Document Line No.");
                END;
                IF NOT ApplyFully THEN BEGIN
                    ApplyRec.AppliedOutbndEntryExists("Entry No.", FALSE);
                    IF ApplyRec.FINDFIRST THEN
                        SkippedLine := SkippedLine OR ApplyRec.FINDFIRST;
                END;
                IF ApplyFully THEN BEGIN
                    ApplyRec.AppliedOutbndEntryExists("Entry No.", FALSE);
                    IF ApplyRec.FINDFIRST THEN
                        REPEAT
                            SomeAreFixed := SomeAreFixed OR ApplyRec.Fixed;
                        UNTIL ApplyRec.NEXT = 0;
                END;

                IF AskApply AND ("Item Tracking" = "Item Tracking"::None) THEN
                    IF NOT ("Remaining Quantity" > 0) OR ("Item Tracking" <> "Item Tracking"::None) THEN ConfirmApply;
                IF AskApply THEN
                    IF "Remaining Quantity" < ABS(FromPurchLine."Quantity (Base)") THEN ConfirmApply;
                IF ("Remaining Quantity" > 0) OR ApplyFully THEN BEGIN
                    FromPurchLineBuf := FromPurchLine;
                    IF "Remaining Quantity" < ABS(FromPurchLine."Quantity (Base)") THEN BEGIN
                        IF NOT ApplyFully THEN BEGIN
                            IF FromPurchLine."Quantity (Base)" > 0 THEN
                                FromPurchLineBuf."Quantity (Base)" := "Remaining Quantity"
                            ELSE
                                FromPurchLineBuf."Quantity (Base)" := -"Remaining Quantity";
                            ConvertFromBase(
                              FromPurchLineBuf.Quantity, FromPurchLineBuf."Quantity (Base)", FromPurchLineBuf."Qty. per Unit of Measure");
                        END
                        ELSE BEGIN
                            ReappDone := TRUE;
                            FromPurchLineBuf."Quantity (Base)" := FromPurchLine."Quantity (Base)" - ApplyRec.Returned("Entry No.");
                            FromPurchLineBuf."Quantity (Base)" :=
                              Sign(ItemLedgEntry.Quantity) * ItemLedgEntry.Quantity - ApplyRec.Returned("Entry No.");
                            ConvertFromBase(
                              FromPurchLineBuf.Quantity, FromPurchLineBuf."Quantity (Base)", FromPurchLineBuf."Qty. per Unit of Measure");
                        END;
                    END;
                    FromPurchLine."Quantity (Base)" := FromPurchLine."Quantity (Base)" - FromPurchLineBuf."Quantity (Base)";
                    FromPurchLine.Quantity := FromPurchLine.Quantity - FromPurchLineBuf.Quantity;
                    FromPurchLineBuf."Appl.-to Item Entry" := "Entry No.";
                    FromPurchLineBuf."Line No." := NextLineNo;
                    NextLineNo := NextLineNo + 1;
                    FromPurchLineBuf."Document No." := "Document No.";
                    IF GetPurchDocType(ItemLedgEntry) IN
                       [FromPurchLineBuf."Document Type"::Order, FromPurchLineBuf."Document Type"::"Return Order"]
                    THEN
                        FromPurchLineBuf."Receipt Line No." := 1;

                    IF NOT FromShptOrRcpt THEN
                        UpdateRevPurchLineAmount(
                          FromPurchLineBuf, OrgQtyBase,
                          FromPurchHeader."Prices Including VAT", ToPurchHeader."Prices Including VAT");
                    IF (FromPurchLineBuf.Quantity <> 0) THEN
                        FromPurchLineBuf.INSERT
                    ELSE
                        SkippedLine := TRUE;
                END
                ELSE
                    IF "Remaining Quantity" = 0 THEN
                        SkippedLine := TRUE;
            UNTIL (NEXT = 0) OR (FromPurchLine."Quantity (Base)" = 0);

            IF (FromPurchLine."Quantity (Base)" <> 0) AND FillExactCostRevLink THEN
                MissingExCostRevLink := TRUE;
        END;

        EXIT(TRUE);
    end;

    local procedure SplitPurchDocLinesPerItemTrkg(var ItemLedgEntry: Record "Item Ledger Entry"; var TempItemTrkgEntry: Record "Reservation Entry" temporary; var FromPurchLineBuf: Record "Purchase Line"; FromPurchLine: Record "Purchase Line"; var NextLineNo: Integer; var NextItemTrkgEntryNo: Integer; var MissingExCostRevLink: Boolean; FromShptOrRcpt: Boolean): Boolean
    var
        PurchLineBuf: array[2] of Record "39" temporary;
        RemainingQtyBase: Decimal;
        SignFactor: Integer;
        i: Integer;
        ApplyRec: Record "Item Application Entry";
    begin
        IF FromShptOrRcpt THEN BEGIN
            FromPurchLineBuf.RESET;
            FromPurchLineBuf.DELETEALL;
            TempItemTrkgEntry.RESET;
            TempItemTrkgEntry.DELETEALL;
        END ELSE
            FromPurchLineBuf.INIT;

        IF MoveNegLines OR NOT ExactCostRevMandatory THEN
            EXIT(FALSE);

        IF FromPurchLine."Quantity (Base)" < 0 THEN
            SignFactor := -1
        ELSE
            SignFactor := 1;

        WITH ItemLedgEntry DO BEGIN
            SETCURRENTKEY("Document No.", "Document Type", "Document Line No.");
            FINDSET;
            REPEAT
                PurchLineBuf[1] := FromPurchLine;
                PurchLineBuf[1]."Line No." := NextLineNo;
                PurchLineBuf[1]."Quantity (Base)" := 0;
                PurchLineBuf[1].Quantity := 0;
                PurchLineBuf[1]."Document No." := "Document No.";
                IF GetPurchDocType(ItemLedgEntry) IN
                   [PurchLineBuf[1]."Document Type"::Order, PurchLineBuf[1]."Document Type"::"Return Order"]
                THEN
                    PurchLineBuf[1]."Receipt Line No." := 1;
                PurchLineBuf[2] := PurchLineBuf[1];
                PurchLineBuf[2]."Line No." := PurchLineBuf[2]."Line No." + 1;

                IF NOT FromShptOrRcpt THEN BEGIN
                    SETRANGE("Document No.", "Document No.");
                    SETRANGE("Document Type", "Document Type");
                    SETRANGE("Document Line No.", "Document Line No.");
                END;
                REPEAT
                    i := 1;
                    IF Positive THEN
                        "Remaining Quantity" :=
                          "Remaining Quantity" -
                          CalcDistributedQty(TempItemTrkgEntry, ItemLedgEntry, PurchLineBuf[2]."Line No." + 1);

                    IF "Remaining Quantity" < FromPurchLine."Quantity (Base)" * SignFactor THEN BEGIN
                        IF ("Item Tracking" = "Item Tracking"::None) AND AskApply THEN ConfirmApply;
                        IF (NOT ApplyFully) OR ("Item Tracking" <> "Item Tracking"::None) THEN
                            RemainingQtyBase := "Remaining Quantity" * SignFactor
                        ELSE
                            RemainingQtyBase := FromPurchLine."Quantity (Base)" - ApplyRec.Returned("Entry No.");
                    END ELSE
                        RemainingQtyBase := FromPurchLine."Quantity (Base)";

                    IF RemainingQtyBase <> 0 THEN BEGIN
                        IF Positive THEN
                            IF IsSplitItemLedgEntry(ItemLedgEntry) THEN
                                i := 2;

                        PurchLineBuf[i]."Quantity (Base)" := PurchLineBuf[i]."Quantity (Base)" + RemainingQtyBase;
                        IF PurchLineBuf[i]."Qty. per Unit of Measure" = 0 THEN
                            PurchLineBuf[i].Quantity := PurchLineBuf[i]."Quantity (Base)"
                        ELSE
                            PurchLineBuf[i].Quantity :=
                              ROUND(PurchLineBuf[i]."Quantity (Base)" / PurchLineBuf[i]."Qty. per Unit of Measure", 0.00001);
                        FromPurchLine."Quantity (Base)" := FromPurchLine."Quantity (Base)" - RemainingQtyBase;

                        // Fill buffer with exact cost reversing link for remaining quantity
                        InsertTempItemTrkgEntry(
                          ItemLedgEntry, TempItemTrkgEntry, ABS(RemainingQtyBase),
                          PurchLineBuf[i]."Line No.", NextItemTrkgEntryNo, TRUE);
                    END;
                UNTIL (NEXT = 0) OR (FromPurchLine."Quantity (Base)" = 0);

                FOR i := 1 TO 2 DO
                    IF PurchLineBuf[i]."Quantity (Base)" <> 0 THEN BEGIN
                        FromPurchLineBuf := PurchLineBuf[i];
                        FromPurchLineBuf.INSERT;
                        NextLineNo := PurchLineBuf[i]."Line No." + 1;
                    END;

                IF NOT FromShptOrRcpt THEN BEGIN
                    SETRANGE("Document No.");
                    SETRANGE("Document Type");
                    SETRANGE("Document Line No.");
                END;
            UNTIL (NEXT = 0) OR FromShptOrRcpt;
            IF (FromPurchLine."Quantity (Base)" <> 0) AND Positive AND TempItemTrkgEntry.ISEMPTY THEN
                MissingExCostRevLink := TRUE;
        END;

        EXIT(TRUE);
    end;

    local procedure CalcDistributedQty(var TempItemTrkgEntry: Record "Reservation Entry" temporary; ItemLedgEntry: Record "Item Ledger Entry"; NextLineNo: Integer): Decimal
    begin
        WITH ItemLedgEntry DO BEGIN
            TempItemTrkgEntry.RESET;
            TempItemTrkgEntry.SETCURRENTKEY("Source ID", "Source Ref. No.");
            TempItemTrkgEntry.SETRANGE("Source ID", "Document No.");
            TempItemTrkgEntry.SETFILTER("Source Ref. No.", '<%1', NextLineNo);
            TempItemTrkgEntry.SETRANGE("Appl.-to Item Entry", "Entry No.");
            TempItemTrkgEntry.CALCSUMS("Quantity (Base)");
            TempItemTrkgEntry.RESET;
            EXIT(TempItemTrkgEntry."Quantity (Base)");
        END;
    end;

    local procedure IsSplitItemLedgEntry(OrgItemLedgEntry: Record "Item Ledger Entry"): Boolean
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        WITH OrgItemLedgEntry DO BEGIN
            ItemLedgEntry.SETCURRENTKEY("Document No.");
            ItemLedgEntry.SETRANGE("Document No.", "Document No.");
            ItemLedgEntry.SETRANGE("Document Type", "Document Type");
            ItemLedgEntry.SETRANGE("Document Line No.", "Document Line No.");
            ItemLedgEntry.SETRANGE("Lot No.", "Lot No.");
            ItemLedgEntry.SETRANGE("Serial No.", "Serial No.");
            ItemLedgEntry.SETFILTER("Entry No.", '<%1', "Entry No.");
            EXIT(NOT ItemLedgEntry.ISEMPTY);
        END;
    end;

    local procedure IsCopyItemTrkg(var ItemLedgEntry: Record "Item Ledger Entry"; var CopyItemTrkg: Boolean; FillExactCostRevLink: Boolean): Boolean
    begin
        WITH ItemLedgEntry DO BEGIN
            IF ISEMPTY THEN
                EXIT(TRUE);
            SETFILTER("Lot No.", '<>''''');
            IF NOT ISEMPTY THEN BEGIN
                IF FillExactCostRevLink THEN
                    CopyItemTrkg := TRUE;
                EXIT(TRUE);
            END;
            SETRANGE("Lot No.");
            SETFILTER("Serial No.", '<>''''');
            IF NOT ISEMPTY THEN BEGIN
                IF FillExactCostRevLink THEN
                    CopyItemTrkg := TRUE;
                EXIT(TRUE);
            END;
            SETRANGE("Serial No.");
        END;
        EXIT(FALSE);
    end;

    procedure InsertTempItemTrkgEntry(ItemLedgEntry: Record "Item Ledger Entry"; var TempItemTrkgEntry: Record "Reservation Entry"; QtyBase: Decimal; DocLineNo: Integer; var NextEntryNo: Integer; FillExactCostRevLink: Boolean)
    begin
        IF QtyBase = 0 THEN
            EXIT;

        WITH ItemLedgEntry DO BEGIN
            TempItemTrkgEntry.INIT;
            TempItemTrkgEntry."Entry No." := NextEntryNo;
            NextEntryNo := NextEntryNo + 1;
            IF NOT FillExactCostRevLink THEN
                TempItemTrkgEntry."Reservation Status" := TempItemTrkgEntry."Reservation Status"::Prospect;
            TempItemTrkgEntry."Source ID" := "Document No.";
            TempItemTrkgEntry."Source Ref. No." := DocLineNo;
            TempItemTrkgEntry."Appl.-to Item Entry" := "Entry No.";
            TempItemTrkgEntry."Quantity (Base)" := QtyBase;
            TempItemTrkgEntry.INSERT;
        END;
    end;

    procedure CollectItemTrkgPerPstDocLine(var TempItemTrkgEntry: Record "Reservation Entry" temporary; var TempTrkgItemLedgEntry: Record "Item Ledger Entry" temporary; FromPurchase: Boolean)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        TempTrkgItemLedgEntry.RESET;
        TempTrkgItemLedgEntry.DELETEALL;

        WITH TempItemTrkgEntry DO
            IF FINDSET THEN
                REPEAT
                    ItemLedgEntry.GET("Appl.-to Item Entry");
                    TempTrkgItemLedgEntry := ItemLedgEntry;
                    IF "Reservation Status" = "Reservation Status"::Prospect THEN
                        TempTrkgItemLedgEntry."Entry No." := -TempTrkgItemLedgEntry."Entry No.";
                    IF FromPurchase THEN
                        TempTrkgItemLedgEntry."Remaining Quantity" := "Quantity (Base)"
                    ELSE
                        TempTrkgItemLedgEntry."Shipped Qty. Not Returned" := "Quantity (Base)";
                    TempTrkgItemLedgEntry."Document No." := "Source ID";
                    TempTrkgItemLedgEntry."Document Line No." := "Source Ref. No.";
                    TempTrkgItemLedgEntry.INSERT;
                UNTIL NEXT = 0;
    end;

    local procedure GetLastToSalesLineNo(ToSalesHeader: Record "Sales Header"): Decimal
    var
        ToSalesLine: Record "Sales Line";
    begin
        ToSalesLine.LOCKTABLE;
        ToSalesLine.SETRANGE("Document Type", ToSalesHeader."Document Type");
        ToSalesLine.SETRANGE("Document No.", ToSalesHeader."No.");
        IF ToSalesLine.FINDLAST THEN
            EXIT(ToSalesLine."Line No.");
        EXIT(0);
    end;

    local procedure GetLastToPurchLineNo(ToPurchHeader: Record "Purchase Header"): Decimal
    var
        ToPurchLine: Record "Purchase Line";
    begin
        ToPurchLine.LOCKTABLE;
        ToPurchLine.SETRANGE("Document Type", ToPurchHeader."Document Type");
        ToPurchLine.SETRANGE("Document No.", ToPurchHeader."No.");
        IF ToPurchLine.FINDLAST THEN
            EXIT(ToPurchLine."Line No.");
        EXIT(0);
    end;

    local procedure CopySalesExtTextLines(var ToSalesLine2: Record "Sales Line"; ToSalesLine: Record "Sales Line"; Description: Text[50]; Description2: Text[50]; var NextLineNo: Integer)
    begin
        NextLineNo := NextLineNo + 10000;
        ToSalesLine2.INIT;
        ToSalesLine2."Line No." := NextLineNo;
        ToSalesLine2."Document Type" := ToSalesLine."Document Type";
        ToSalesLine2."Document No." := ToSalesLine."Document No.";
        ToSalesLine2.Description := Description;
        ToSalesLine2."Description 2" := Description2;
        ToSalesLine2."Attached to Line No." := ToSalesLine."Line No.";
        ToSalesLine2.INSERT;
    end;

    local procedure CopyPurchExtTextLines(var ToPurchLine2: Record "Purchase Line"; ToPurchLine: Record "Purchase Line"; Description: Text[50]; Description2: Text[50]; var NextLineNo: Integer)
    begin
        NextLineNo := NextLineNo + 10000;
        ToPurchLine2.INIT;
        ToPurchLine2."Line No." := NextLineNo;
        ToPurchLine2."Document Type" := ToPurchLine."Document Type";
        ToPurchLine2."Document No." := ToPurchLine."Document No.";
        ToPurchLine2.Description := Description;
        ToPurchLine2."Description 2" := Description2;
        ToPurchLine2."Attached to Line No." := ToPurchLine."Line No.";
        ToPurchLine2.INSERT;
    end;

    local procedure InsertOldSalesDocNoLine(ToSalesHeader: Record "Sales Header"; OldDocNo: Code[20]; OldDocType: Integer; var NextLineNo: Integer)
    var
        ToSalesLine2: Record "Sales Line";
    begin
        NextLineNo := NextLineNo + 10000;
        ToSalesLine2.INIT;
        ToSalesLine2."Line No." := NextLineNo;
        ToSalesLine2."Document Type" := ToSalesHeader."Document Type";
        ToSalesLine2."Document No." := ToSalesHeader."No.";
        ToSalesLine2.Description := STRSUBSTNO(Text015, SELECTSTR(OldDocType, Text013), OldDocNo);
        ToSalesLine2.INSERT;
    end;

    local procedure InsertOldSalesCombDocNoLine(ToSalesHeader: Record "Sales Header"; OldDocNo: Code[20]; OldDocNo2: Code[20]; var NextLineNo: Integer; CopyFromInvoice: Boolean)
    var
        ToSalesLine2: Record "Sales Line";
    begin
        NextLineNo := NextLineNo + 10000;
        ToSalesLine2.INIT;
        ToSalesLine2."Line No." := NextLineNo;
        ToSalesLine2."Document Type" := ToSalesHeader."Document Type";
        ToSalesLine2."Document No." := ToSalesHeader."No.";
        IF CopyFromInvoice THEN
            ToSalesLine2.Description :=
              STRSUBSTNO(
                Text018,
                COPYSTR(SELECTSTR(1, Text016) + OldDocNo, 1, 23),
                COPYSTR(SELECTSTR(2, Text016) + OldDocNo2, 1, 23))
        ELSE
            ToSalesLine2.Description :=
              STRSUBSTNO(
                Text018,
                COPYSTR(SELECTSTR(3, Text016) + OldDocNo, 1, 23),
                COPYSTR(SELECTSTR(4, Text016) + OldDocNo2, 1, 23));
        ToSalesLine2.INSERT;
    end;

    local procedure InsertOldPurchDocNoLine(ToPurchHeader: Record "Purchase Header"; OldDocNo: Code[20]; OldDocType: Integer; var NextLineNo: Integer)
    var
        ToPurchLine2: Record "Purchase Line";
    begin
        NextLineNo := NextLineNo + 10000;
        ToPurchLine2.INIT;
        ToPurchLine2."Line No." := NextLineNo;
        ToPurchLine2."Document Type" := ToPurchHeader."Document Type";
        ToPurchLine2."Document No." := ToPurchHeader."No.";
        ToPurchLine2.Description := STRSUBSTNO(Text015, SELECTSTR(OldDocType, Text014), OldDocNo);
        ToPurchLine2.INSERT;
    end;

    local procedure InsertOldPurchCombDocNoLine(ToPurchHeader: Record "Purchase Header"; OldDocNo: Code[20]; OldDocNo2: Code[20]; var NextLineNo: Integer; CopyFromInvoice: Boolean)
    var
        ToPurchLine2: Record "Purchase Line";
    begin
        NextLineNo := NextLineNo + 10000;
        ToPurchLine2.INIT;
        ToPurchLine2."Line No." := NextLineNo;
        ToPurchLine2."Document Type" := ToPurchHeader."Document Type";
        ToPurchLine2."Document No." := ToPurchHeader."No.";
        IF CopyFromInvoice THEN
            ToPurchLine2.Description :=
              STRSUBSTNO(
                Text018,
                COPYSTR(SELECTSTR(1, Text017) + OldDocNo, 1, 23),
                COPYSTR(SELECTSTR(2, Text017) + OldDocNo2, 1, 23))
        ELSE
            ToPurchLine2.Description :=
              STRSUBSTNO(
                Text018,
                COPYSTR(SELECTSTR(3, Text017) + OldDocNo, 1, 23),
                COPYSTR(SELECTSTR(4, Text017) + OldDocNo2, 1, 23));
        ToPurchLine2.INSERT;
    end;

    procedure IsSalesFillExactCostRevLink(ToSalesHeader: Record "Sales Header"; FromDocType: Option "Sales Shipment","Sales Invoice","Sales Return Receipt","Sales Credit Memo"; CurrencyCode: Code[10]): Boolean
    begin
        WITH ToSalesHeader DO
            CASE FromDocType OF
                FromDocType::"Sales Shipment":
                    EXIT("Document Type" IN ["Document Type"::"Return Order", "Document Type"::"Credit Memo"]);
                FromDocType::"Sales Invoice":
                    EXIT(
                      ("Document Type" IN ["Document Type"::"Return Order", "Document Type"::"Credit Memo"]) AND
                      ("Currency Code" = CurrencyCode));
                FromDocType::"Sales Return Receipt":
                    EXIT("Document Type" IN ["Document Type"::Order, "Document Type"::Invoice]);
                FromDocType::"Sales Credit Memo":
                    EXIT(
                      ("Document Type" IN ["Document Type"::Order, "Document Type"::Invoice]) AND
                      ("Currency Code" = CurrencyCode));
            END;
        EXIT(FALSE);
    end;

    procedure IsPurchFillExactCostRevLink(ToPurchHeader: Record "Purchase Header"; FromDocType: Option "Purchase Receipt","Purchase Invoice","Purchase Return Shipment","Purchase Credit Memo"; CurrencyCode: Code[10]): Boolean
    begin
        WITH ToPurchHeader DO
            CASE FromDocType OF
                FromDocType::"Purchase Receipt":
                    EXIT("Document Type" IN ["Document Type"::"Return Order", "Document Type"::"Credit Memo"]);
                FromDocType::"Purchase Invoice":
                    EXIT(
                      ("Document Type" IN ["Document Type"::"Return Order", "Document Type"::"Credit Memo"]) AND
                      ("Currency Code" = CurrencyCode));
                FromDocType::"Purchase Return Shipment":
                    EXIT("Document Type" IN ["Document Type"::Order, "Document Type"::Invoice]);
                FromDocType::"Purchase Credit Memo":
                    EXIT(
                      ("Document Type" IN ["Document Type"::Order, "Document Type"::Invoice]) AND
                      ("Currency Code" = CurrencyCode));
            END;
        EXIT(FALSE);
    end;

    local procedure GetSalesDocType(ItemLedgEntry: Record "Item Ledger Entry"): Integer
    var
        SalesLine: Record "Sales Line";
    begin
        WITH ItemLedgEntry DO
            CASE "Document Type" OF
                "Document Type"::"Sales Shipment":
                    EXIT(SalesLine."Document Type"::Order);
                "Document Type"::"Sales Invoice":
                    EXIT(SalesLine."Document Type"::Invoice);
                "Document Type"::"Sales Credit Memo":
                    EXIT(SalesLine."Document Type"::"Credit Memo");
                "Document Type"::"Sales Return Receipt":
                    EXIT(SalesLine."Document Type"::"Return Order");
            END;
    end;

    local procedure GetPurchDocType(ItemLedgEntry: Record "Item Ledger Entry"): Integer
    var
        PurchLine: Record "Purchase Line";
    begin
        WITH ItemLedgEntry DO
            CASE "Document Type" OF
                "Document Type"::"Purchase Receipt":
                    EXIT(PurchLine."Document Type"::Order);
                "Document Type"::"Purchase Invoice":
                    EXIT(PurchLine."Document Type"::Invoice);
                "Document Type"::"Purchase Credit Memo":
                    EXIT(PurchLine."Document Type"::"Credit Memo");
                "Document Type"::"Purchase Return Shipment":
                    EXIT(PurchLine."Document Type"::"Return Order");
            END;
    end;

    local procedure GetItem(ItemNo: Code[20])
    begin
        IF ItemNo <> Item."No." THEN
            IF NOT Item.GET(ItemNo) THEN
                Item.INIT;
    end;

    procedure CalcVAT(var Value: Decimal; VATPercentage: Decimal; FromPricesInclVAT: Boolean; ToPricesInclVAT: Boolean; RndgPrecision: Decimal)
    begin
        IF (ToPricesInclVAT = FromPricesInclVAT) OR (Value = 0) THEN
            EXIT;

        IF ToPricesInclVAT THEN
            Value := ROUND(Value * (100 + VATPercentage) / 100, RndgPrecision)
        ELSE
            Value := ROUND(Value * 100 / (100 + VATPercentage), RndgPrecision);
    end;

    local procedure ReCalcSalesLine(FromSalesHeader: Record "Sales Header"; ToSalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        CurrExchRate: Record "Currency Exchange Rate";
        SalesLineAmount: Decimal;
    begin
        WITH ToSalesHeader DO BEGIN
            IF NOT IsRecalculateAmount(
                 FromSalesHeader."Currency Code", "Currency Code",
                 FromSalesHeader."Prices Including VAT", "Prices Including VAT")
            THEN
                EXIT;

            IF FromSalesHeader."Currency Code" <> "Currency Code" THEN BEGIN
                IF SalesLine.Quantity <> 0 THEN
                    SalesLineAmount := SalesLine."Unit Price" * SalesLine.Quantity
                ELSE
                    SalesLineAmount := SalesLine."Unit Price";
                IF FromSalesHeader."Currency Code" <> '' THEN BEGIN
                    SalesLineAmount :=
                      CurrExchRate.ExchangeAmtFCYToLCY(
                        FromSalesHeader."Posting Date", FromSalesHeader."Currency Code",
                        SalesLineAmount, FromSalesHeader."Currency Factor");
                    SalesLine."Line Discount Amount" :=
                      CurrExchRate.ExchangeAmtFCYToLCY(
                        FromSalesHeader."Posting Date", FromSalesHeader."Currency Code",
                        SalesLine."Line Discount Amount", FromSalesHeader."Currency Factor");
                    SalesLine."Inv. Discount Amount" :=
                      CurrExchRate.ExchangeAmtFCYToLCY(
                        FromSalesHeader."Posting Date", FromSalesHeader."Currency Code",
                        SalesLine."Inv. Discount Amount", FromSalesHeader."Currency Factor");
                END;

                IF "Currency Code" <> '' THEN BEGIN
                    SalesLineAmount :=
                      CurrExchRate.ExchangeAmtLCYToFCY(
                        "Posting Date", "Currency Code", SalesLineAmount, "Currency Factor");
                    SalesLine."Line Discount Amount" :=
                      CurrExchRate.ExchangeAmtLCYToFCY(
                        "Posting Date", "Currency Code", SalesLine."Line Discount Amount", "Currency Factor");
                    SalesLine."Inv. Discount Amount" :=
                      CurrExchRate.ExchangeAmtLCYToFCY(
                        "Posting Date", "Currency Code", SalesLine."Inv. Discount Amount", "Currency Factor");
                END;
            END;

            SalesLine."Currency Code" := "Currency Code";
            IF SalesLine.Quantity <> 0 THEN BEGIN
                SalesLineAmount := ROUND(SalesLineAmount, Currency."Amount Rounding Precision");
                SalesLine."Unit Price" := ROUND(SalesLineAmount / SalesLine.Quantity, Currency."Unit-Amount Rounding Precision");
            END ELSE
                SalesLine."Unit Price" := ROUND(SalesLineAmount, Currency."Unit-Amount Rounding Precision");
            SalesLine."Line Discount Amount" := ROUND(SalesLine."Line Discount Amount", Currency."Amount Rounding Precision");
            SalesLine."Inv. Discount Amount" := ROUND(SalesLine."Inv. Discount Amount", Currency."Amount Rounding Precision");

            CalcVAT(
              SalesLine."Unit Price", SalesLine."VAT %", FromSalesHeader."Prices Including VAT",
              "Prices Including VAT", Currency."Unit-Amount Rounding Precision");
            CalcVAT(
              SalesLine."Line Discount Amount", SalesLine."VAT %", FromSalesHeader."Prices Including VAT",
              "Prices Including VAT", Currency."Amount Rounding Precision");
            CalcVAT(
              SalesLine."Inv. Discount Amount", SalesLine."VAT %", FromSalesHeader."Prices Including VAT",
              "Prices Including VAT", Currency."Amount Rounding Precision");
        END;
    end;

    local procedure ReCalcPurchLine(FromPurchHeader: Record "Purchase Header"; ToPurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line")
    var
        CurrExchRate: Record "Currency Exchange Rate";
        PurchLineAmount: Decimal;
    begin
        WITH ToPurchHeader DO BEGIN
            IF NOT IsRecalculateAmount(
                 FromPurchHeader."Currency Code", "Currency Code",
                 FromPurchHeader."Prices Including VAT", "Prices Including VAT")
            THEN
                EXIT;

            IF FromPurchHeader."Currency Code" <> "Currency Code" THEN BEGIN
                IF PurchLine.Quantity <> 0 THEN
                    PurchLineAmount := PurchLine."Direct Unit Cost" * PurchLine.Quantity
                ELSE
                    PurchLineAmount := PurchLine."Direct Unit Cost";
                IF FromPurchHeader."Currency Code" <> '' THEN BEGIN
                    PurchLineAmount :=
                      CurrExchRate.ExchangeAmtFCYToLCY(
                        FromPurchHeader."Posting Date", FromPurchHeader."Currency Code",
                        PurchLineAmount, FromPurchHeader."Currency Factor");
                    PurchLine."Line Discount Amount" :=
                      CurrExchRate.ExchangeAmtFCYToLCY(
                        FromPurchHeader."Posting Date", FromPurchHeader."Currency Code",
                        PurchLine."Line Discount Amount", FromPurchHeader."Currency Factor");
                    PurchLine."Inv. Discount Amount" :=
                      CurrExchRate.ExchangeAmtFCYToLCY(
                        FromPurchHeader."Posting Date", FromPurchHeader."Currency Code",
                        PurchLine."Inv. Discount Amount", FromPurchHeader."Currency Factor");
                END;

                IF "Currency Code" <> '' THEN BEGIN
                    PurchLineAmount :=
                      CurrExchRate.ExchangeAmtLCYToFCY(
                        "Posting Date", "Currency Code", PurchLineAmount, "Currency Factor");
                    PurchLine."Line Discount Amount" :=
                      CurrExchRate.ExchangeAmtLCYToFCY(
                        "Posting Date", "Currency Code", PurchLine."Line Discount Amount", "Currency Factor");
                    PurchLine."Inv. Discount Amount" :=
                      CurrExchRate.ExchangeAmtLCYToFCY(
                        "Posting Date", "Currency Code", PurchLine."Inv. Discount Amount", "Currency Factor");
                END;
            END;

            PurchLine."Currency Code" := "Currency Code";
            IF PurchLine.Quantity <> 0 THEN BEGIN
                PurchLineAmount := ROUND(PurchLineAmount, Currency."Amount Rounding Precision");
                PurchLine."Direct Unit Cost" := ROUND(PurchLineAmount / PurchLine.Quantity, Currency."Unit-Amount Rounding Precision");
            END ELSE
                PurchLine."Direct Unit Cost" := ROUND(PurchLineAmount, Currency."Unit-Amount Rounding Precision");
            PurchLine."Line Discount Amount" := ROUND(PurchLine."Line Discount Amount", Currency."Amount Rounding Precision");
            PurchLine."Inv. Discount Amount" := ROUND(PurchLine."Inv. Discount Amount", Currency."Amount Rounding Precision");

            CalcVAT(
              PurchLine."Direct Unit Cost", PurchLine."VAT %", FromPurchHeader."Prices Including VAT",
              "Prices Including VAT", Currency."Unit-Amount Rounding Precision");
            CalcVAT(
              PurchLine."Line Discount Amount", PurchLine."VAT %", FromPurchHeader."Prices Including VAT",
              "Prices Including VAT", Currency."Amount Rounding Precision");
            CalcVAT(
              PurchLine."Inv. Discount Amount", PurchLine."VAT %", FromPurchHeader."Prices Including VAT",
              "Prices Including VAT", Currency."Amount Rounding Precision");
        END;
    end;

    local procedure IsRecalculateAmount(FromCurrencyCode: Code[10]; ToCurrencyCode: Code[10]; FromPricesInclVAT: Boolean; ToPricesInclVAT: Boolean): Boolean
    begin
        EXIT(
          (FromCurrencyCode <> ToCurrencyCode) OR
          (FromPricesInclVAT <> ToPricesInclVAT));
    end;

    procedure UpdateRevSalesLineAmount(var SalesLine: Record "Sales Line"; OrgQtyBase: Decimal; FromPricesInclVAT: Boolean; ToPricesInclVAT: Boolean)
    var
        Amount: Decimal;
    begin
        IF (OrgQtyBase = 0) OR (SalesLine.Quantity = 0) THEN
            EXIT;

        Amount := SalesLine.Quantity * SalesLine."Unit Price";
        CalcVAT(
          Amount, SalesLine."VAT %", FromPricesInclVAT, ToPricesInclVAT, Currency."Amount Rounding Precision");
        SalesLine."Unit Price" := Amount / SalesLine.Quantity;
        SalesLine."Line Discount Amount" :=
          SalesLine.Quantity * SalesLine."Unit Price" * (SalesLine."Line Discount %" / 100);
        Amount := ROUND(SalesLine."Inv. Discount Amount" / OrgQtyBase * SalesLine."Quantity (Base)", Currency."Amount Rounding Precision");
        CalcVAT(
          Amount, SalesLine."VAT %", FromPricesInclVAT, ToPricesInclVAT, Currency."Amount Rounding Precision");
        SalesLine."Inv. Discount Amount" := Amount;
    end;

    procedure CalculateRevSalesLineAmount(var SalesLine: Record "Sales Line"; OrgQtyBase: Decimal; FromPricesInclVAT: Boolean; ToPricesInclVAT: Boolean)
    var
        UnitPrice: Decimal;
        LineDiscAmt: Decimal;
        InvDiscAmt: Decimal;
    begin
        UpdateRevSalesLineAmount(SalesLine, OrgQtyBase, FromPricesInclVAT, ToPricesInclVAT);

        UnitPrice := SalesLine."Unit Price";
        LineDiscAmt := SalesLine."Line Discount Amount";
        InvDiscAmt := SalesLine."Inv. Discount Amount";

        SalesLine.VALIDATE("Unit Price", UnitPrice);
        SalesLine.VALIDATE("Line Discount Amount", LineDiscAmt);
        SalesLine.VALIDATE("Inv. Discount Amount", InvDiscAmt);
    end;

    procedure UpdateRevPurchLineAmount(var PurchLine: Record "Purchase Line"; OrgQtyBase: Decimal; FromPricesInclVAT: Boolean; ToPricesInclVAT: Boolean)
    var
        Amount: Decimal;
    begin
        IF (OrgQtyBase = 0) OR (PurchLine.Quantity = 0) THEN
            EXIT;

        Amount := PurchLine.Quantity * PurchLine."Direct Unit Cost";
        CalcVAT(
          Amount, PurchLine."VAT %", FromPricesInclVAT, ToPricesInclVAT, Currency."Amount Rounding Precision");
        PurchLine."Direct Unit Cost" := Amount / PurchLine.Quantity;
        PurchLine."Line Discount Amount" :=
          PurchLine.Quantity * PurchLine."Direct Unit Cost" * (PurchLine."Line Discount %" / 100);
        Amount := ROUND(PurchLine."Inv. Discount Amount" / OrgQtyBase * PurchLine."Quantity (Base)", Currency."Amount Rounding Precision");
        CalcVAT(
          Amount, PurchLine."VAT %", FromPricesInclVAT, ToPricesInclVAT, Currency."Amount Rounding Precision");
        PurchLine."Inv. Discount Amount" := Amount;
    end;

    procedure CalculateRevPurchLineAmount(var PurchLine: Record "Purchase Line"; OrgQtyBase: Decimal; FromPricesInclVAT: Boolean; ToPricesInclVAT: Boolean)
    var
        DirectUnitCost: Decimal;
        LineDiscAmt: Decimal;
        InvDiscAmt: Decimal;
    begin
        UpdateRevPurchLineAmount(PurchLine, OrgQtyBase, FromPricesInclVAT, ToPricesInclVAT);

        DirectUnitCost := PurchLine."Direct Unit Cost";
        LineDiscAmt := PurchLine."Line Discount Amount";
        InvDiscAmt := PurchLine."Inv. Discount Amount";

        PurchLine.VALIDATE("Direct Unit Cost", DirectUnitCost);
        PurchLine.VALIDATE("Line Discount Amount", LineDiscAmt);
        PurchLine.VALIDATE("Inv. Discount Amount", InvDiscAmt);
    end;

    local procedure InitCurrency(CurrencyCode: Code[10])
    begin
        IF CurrencyCode <> '' THEN
            Currency.GET(CurrencyCode)
        ELSE
            Currency.InitRoundingPrecision;

        Currency.TESTFIELD("Unit-Amount Rounding Precision");
        Currency.TESTFIELD("Amount Rounding Precision");
    end;

    local procedure OpenWindow()
    begin
        Window.OPEN(
          Text022 +
          Text023 +
          Text024);
        WindowUpdateTime := TIME;
    end;

    local procedure IsTimeForUpdate(): Boolean
    begin
        IF TIME - WindowUpdateTime >= 1000 THEN BEGIN
            WindowUpdateTime := TIME;
            EXIT(TRUE);
        END;
        EXIT(FALSE);
    end;

    procedure UTlocalCall(localFunctionName: Text[30]; var param: array[20] of Variant; var return: Variant)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ItemLedgEntryBuf: Record "Item Ledger Entry" temporary;
        ToSalesHeader: Record "Sales Header";
        FromSalesHeader: Record "Sales Header";
        FromSalesLineBuf: Record "Sales Line" temporary;
        FromSalesLine: Record "Sales Line";
        ToPurchHeader: Record "Purchase Header";
        FromPurchHeader: Record "Purchase Header";
        FromPurchLineBuf: Record "Purchase Line" temporary;
        FromPurchLine: Record "Purchase Line";
        FromSalesShptLine: Record "Sales Shipment Line";
        FromSalesInvLine: Record "Sales Invoice Line";
        FromReturnRcptLine: Record "Return Receipt Line";
        FromPurchRcptLine: Record "Purch. Rcpt. Line";
        FromPurchInvLine: Record "Purch. Inv. Line";
        FromReturnShptLine: Record "Return Shipment Line";
        TempItemTrkgEntry: Record "Reservation Entry" temporary;
        FromDocType: Integer;
        i: Integer;
        NextLineNo: Integer;
        NextItemTrkgEntryNo: Integer;
        CopyItemTrkg: Boolean;
        MissingExCostRevLink: Boolean;
        IsSplitILE: Boolean;
    begin
        CASE localFunctionName OF
            'SplitPstdSalesLinesPerILE':
                BEGIN
                    ToSalesHeader := param[1];
                    FromSalesHeader := param[2];
                    FromDocType := param[3];
                    FromDocType := FromDocType - 1;
                    CASE FromDocType OF
                        0:
                            BEGIN
                                FromSalesShptLine := param[4];
                                FromSalesLine.TRANSFERFIELDS(FromSalesShptLine);
                                FromSalesShptLine.FilterPstdDocLnItemLedgEntries(ItemLedgEntry);

                                IsSplitILE :=
                                  SplitPstdSalesLinesPerILE(
                                    ToSalesHeader, FromSalesHeader, ItemLedgEntry,
                                    FromSalesLineBuf, FromSalesLine, NextLineNo, CopyItemTrkg, MissingExCostRevLink,
                                    IsSalesFillExactCostRevLink(ToSalesHeader, FromDocType, FromSalesHeader."Currency Code"), TRUE);
                            END;
                        1:
                            BEGIN
                                FromSalesInvLine := param[4];
                                FromSalesLine.TRANSFERFIELDS(FromSalesInvLine);
                                FromSalesInvLine.GetItemLedgEntries(ItemLedgEntryBuf, TRUE);
                                IsSplitILE :=
                                  SplitPstdSalesLinesPerILE(
                                    ToSalesHeader, FromSalesHeader, ItemLedgEntryBuf,
                                    FromSalesLineBuf, FromSalesLine, NextLineNo, CopyItemTrkg, MissingExCostRevLink,
                                    IsSalesFillExactCostRevLink(ToSalesHeader, FromDocType, FromSalesHeader."Currency Code"), FALSE);
                            END;
                    END;
                    param[5] := CopyItemTrkg;
                    param[6] := MissingExCostRevLink;
                    i := 10;
                    IF IsSplitILE THEN BEGIN
                        return := TRUE;
                        FromSalesLineBuf.FINDSET;
                        REPEAT
                            param[i] := FromSalesLineBuf;
                            i := i + 1;
                        UNTIL FromSalesLineBuf.NEXT = 0;
                        param[8] := i - 10;
                    END ELSE BEGIN
                        return := FALSE;
                        param[8] := 1;
                        param[i] := FromSalesLineBuf;
                    END;
                END;

            'SplitSalesDocLinesPerItemTrkg':
                BEGIN
                    FromDocType := param[1];
                    CASE FromDocType OF
                        1:
                            BEGIN
                                FromSalesShptLine := param[2];
                                FromSalesLine.TRANSFERFIELDS(FromSalesShptLine);
                                FromSalesShptLine.FilterPstdDocLnItemLedgEntries(ItemLedgEntry);
                                IsSplitILE :=
                                  SplitSalesDocLinesPerItemTrkg(
                                    ItemLedgEntry, TempItemTrkgEntry, FromSalesLineBuf, FromSalesLine,
                                    NextLineNo, NextItemTrkgEntryNo, MissingExCostRevLink, TRUE);
                            END;
                        2:
                            BEGIN
                                FromSalesInvLine := param[2];
                                FromSalesLine.TRANSFERFIELDS(FromSalesInvLine);
                                FromSalesInvLine.GetItemLedgEntries(ItemLedgEntryBuf, TRUE);
                                IsSplitILE :=
                                  SplitSalesDocLinesPerItemTrkg(
                                    ItemLedgEntryBuf, TempItemTrkgEntry, FromSalesLineBuf,
                                    FromSalesLine, NextLineNo, NextItemTrkgEntryNo, MissingExCostRevLink, FALSE);
                            END;
                        3:
                            BEGIN
                                FromReturnRcptLine := param[2];
                                FromSalesLine.TRANSFERFIELDS(FromReturnRcptLine);
                                FromReturnRcptLine.FilterPstdDocLnItemLedgEntries(ItemLedgEntry);
                                IsSplitILE :=
                                  SplitSalesDocLinesPerItemTrkg(
                                    ItemLedgEntry, TempItemTrkgEntry, FromSalesLineBuf,
                                    FromSalesLine, NextLineNo, NextItemTrkgEntryNo, MissingExCostRevLink, TRUE);
                            END;
                    END;
                    param[3] := MissingExCostRevLink;
                    i := 5;
                    TempItemTrkgEntry.RESET;
                    TempItemTrkgEntry.FINDSET;
                    REPEAT
                        param[i] := TempItemTrkgEntry;
                        i := i + 1;
                    UNTIL TempItemTrkgEntry.NEXT = 0;
                    param[4] := i - 5;

                    IF IsSplitILE THEN BEGIN
                        return := TRUE;
                        i := 12;
                        FromSalesLineBuf.FINDSET;
                        REPEAT
                            param[i] := FromSalesLineBuf;
                            i := i + 1;
                        UNTIL FromSalesLineBuf.NEXT = 0;
                        param[11] := i - 12;
                    END ELSE BEGIN
                        return := FALSE;
                        param[11] := 1;
                        param[12] := FromSalesLineBuf;
                    END;
                END;
            'SplitPstdPurchLinesPerILE':
                BEGIN
                    ToPurchHeader := param[1];
                    FromPurchHeader := param[2];
                    FromDocType := param[3];
                    FromDocType := FromDocType - 1;
                    CASE FromDocType OF
                        0:
                            BEGIN
                                FromPurchRcptLine := param[4];
                                FromPurchLine.TRANSFERFIELDS(FromPurchRcptLine);
                                FromPurchRcptLine.FilterPstdDocLnItemLedgEntries(ItemLedgEntry);
                                IsSplitILE :=
                                  SplitPstdPurchLinesPerILE(
                                    ToPurchHeader, FromPurchHeader, ItemLedgEntry,
                                    FromPurchLineBuf, FromPurchLine, NextLineNo, CopyItemTrkg, MissingExCostRevLink,
                                    IsPurchFillExactCostRevLink(ToPurchHeader, FromDocType, FromPurchHeader."Currency Code"), TRUE);
                            END;
                        1:
                            BEGIN
                                FromPurchInvLine := param[4];
                                FromPurchLine.TRANSFERFIELDS(FromPurchInvLine);
                                FromPurchInvLine.GetItemLedgEntries(ItemLedgEntryBuf, TRUE);
                                IsSplitILE :=
                                  SplitPstdPurchLinesPerILE(
                                    ToPurchHeader, FromPurchHeader, ItemLedgEntryBuf,
                                    FromPurchLineBuf, FromPurchLine, NextLineNo, CopyItemTrkg, MissingExCostRevLink,
                                    IsPurchFillExactCostRevLink(ToPurchHeader, FromDocType, FromPurchHeader."Currency Code"), FALSE);
                            END;
                    END;
                    param[5] := CopyItemTrkg;
                    param[6] := MissingExCostRevLink;
                    i := 10;
                    IF IsSplitILE THEN BEGIN
                        return := TRUE;
                        FromPurchLineBuf.FINDSET;
                        REPEAT
                            param[i] := FromPurchLineBuf;
                            i := i + 1;
                        UNTIL FromPurchLineBuf.NEXT = 0;
                        param[8] := i - 10;
                    END ELSE BEGIN
                        return := FALSE;
                        param[8] := 1;
                        param[i] := FromPurchLineBuf;
                    END;
                END;
            'SplitPurchDocLinesPerItemTrkg':
                BEGIN
                    FromDocType := param[1];
                    CASE FromDocType OF
                        1:
                            BEGIN
                                FromPurchRcptLine := param[2];
                                FromPurchLine.TRANSFERFIELDS(FromPurchRcptLine);
                                FromPurchRcptLine.FilterPstdDocLnItemLedgEntries(ItemLedgEntry);
                                IsSplitILE :=
                                  SplitPurchDocLinesPerItemTrkg(
                                    ItemLedgEntry, TempItemTrkgEntry, FromPurchLineBuf,
                                    FromPurchLine, NextLineNo, NextItemTrkgEntryNo, MissingExCostRevLink, TRUE);
                            END;
                        2:
                            BEGIN
                                FromPurchInvLine := param[2];
                                FromPurchLine.TRANSFERFIELDS(FromPurchInvLine);
                                FromPurchInvLine.GetItemLedgEntries(ItemLedgEntryBuf, TRUE);
                                IsSplitILE :=
                                  SplitPurchDocLinesPerItemTrkg(
                                    ItemLedgEntryBuf, TempItemTrkgEntry, FromPurchLineBuf,
                                    FromPurchLine, NextLineNo, NextItemTrkgEntryNo, MissingExCostRevLink, FALSE);
                            END;
                        3:
                            BEGIN
                                FromReturnShptLine := param[2];
                                FromPurchLine.TRANSFERFIELDS(FromReturnShptLine);
                                FromReturnShptLine.FilterPstdDocLnItemLedgEntries(ItemLedgEntry);
                                IsSplitILE :=
                                  SplitPurchDocLinesPerItemTrkg(
                                    ItemLedgEntry, TempItemTrkgEntry, FromPurchLineBuf,
                                    FromPurchLine, NextLineNo, NextItemTrkgEntryNo, MissingExCostRevLink, TRUE);
                            END;
                    END;
                    param[3] := MissingExCostRevLink;
                    i := 5;
                    TempItemTrkgEntry.RESET;
                    TempItemTrkgEntry.FINDSET;
                    REPEAT
                        param[i] := TempItemTrkgEntry;
                        i := i + 1;
                    UNTIL TempItemTrkgEntry.NEXT = 0;
                    param[4] := i - 5;

                    IF IsSplitILE THEN BEGIN
                        return := TRUE;
                        i := 13;
                        FromPurchLineBuf.FINDSET;
                        REPEAT
                            param[i] := FromPurchLineBuf;
                            i := i + 1;
                        UNTIL FromPurchLineBuf.NEXT = 0;
                        param[12] := i - 13;
                    END ELSE BEGIN
                        return := FALSE;
                        param[12] := 1;
                        param[13] := FromPurchLineBuf;
                    END;
                END;
            ELSE
                ERROR('Local function %1 is not included for test.', localFunctionName);
        END;
    end;

    procedure ConfirmApply()
    begin
        AskApply := FALSE;
        ApplyFully := FALSE;
    end;

    procedure ConvertFromBase(var Quantity: Decimal; "Quantity (Base)": Decimal; "Qty. per Unit of Measure": Decimal)
    begin
        IF "Qty. per Unit of Measure" = 0 THEN
            Quantity := "Quantity (Base)"
        ELSE
            Quantity :=
              ROUND("Quantity (Base)" / "Qty. per Unit of Measure", 0.00001);
    end;

    procedure Sign(Quantity: Decimal): Decimal
    begin
        IF Quantity < 0 THEN
            EXIT(-1);
        EXIT(1);
    end;

    procedure ShowMessageReapply(OriginalQuantity: Boolean)
    var
        Text: Text[1024];
    begin
        Text := '';
        IF SkippedLine THEN
            Text := Text029;
        IF OriginalQuantity AND ReappDone THEN
            IF Text = '' THEN
                Text := Text025;
        IF SomeAreFixed THEN
            MESSAGE(Text031);
        IF Text <> '' THEN
            MESSAGE(Text);
    end;

    procedure CopyOptionType(var ToConfigurationID: Code[30]; var FromConfigurationID: Code[30])
    var
        lFromOptionTypeValueHeader: Record "10012712";
        lFromOptionTypeValueEntry: Record "10012713";
        lNewOptionTypeValueHeader: Record "10012712";
        lNewOptionTypeValueEntry: Record "10012713";
    begin
        //CopyOptionType
        //LS

        lFromOptionTypeValueHeader.GET(FromConfigurationID);
        lNewOptionTypeValueHeader.INIT;
        lNewOptionTypeValueHeader.TRANSFERFIELDS(lFromOptionTypeValueHeader);
        lNewOptionTypeValueHeader."Configuration ID" := ToConfigurationID;
        lNewOptionTypeValueHeader.VALIDATE("Item No.");
        lNewOptionTypeValueHeader.INSERT(TRUE);

        lFromOptionTypeValueEntry.RESET;
        lFromOptionTypeValueEntry.SETFILTER("Configuration ID", FromConfigurationID);
        IF lFromOptionTypeValueEntry.FINDSET THEN
            REPEAT
                lNewOptionTypeValueEntry.INIT;
                lNewOptionTypeValueEntry.TRANSFERFIELDS(lFromOptionTypeValueEntry);
                lNewOptionTypeValueEntry."Configuration ID" := ToConfigurationID;
                lNewOptionTypeValueEntry.INSERT(TRUE);
            UNTIL lFromOptionTypeValueEntry.NEXT = 0;
    end;

    procedure CopySalesLineSPOAddInfo(var ToSalesLine: Record "Sales Line"; var FromSalesLine: Record "Sales Line")
    begin
        //CopySalesLineSPOAddInfo
        //LS - Copy Special Order Additional Information

        ToSalesLine."Retail Special Order" := TRUE;
        ToSalesLine."Delivering Method" := FromSalesLine."Delivering Method";
        ToSalesLine."Vendor Delivers to" := FromSalesLine."Vendor Delivers to";
        ToSalesLine.Sourcing := FromSalesLine.Sourcing;
        ToSalesLine."Deliver from" := FromSalesLine."Deliver from";
        ToSalesLine."Delivery Location Code" := FromSalesLine."Delivery Location Code";
        ToSalesLine."SPO Prepayment %" := FromSalesLine."SPO Prepayment %";
        ToSalesLine."Total Payment" := FromSalesLine."Total Payment";
        ToSalesLine."Whse Process" := FromSalesLine."Whse Process";
        ToSalesLine.Status := FromSalesLine.Status;
        ToSalesLine."Delivery Status" := FromSalesLine."Delivery Status";
        ToSalesLine."Configuration ID" := ToSalesLine."Document No." + '.' + FORMAT(ToSalesLine."Line No.");
        ToSalesLine."Mandatory Options Exist" := FromSalesLine."Mandatory Options Exist";
        ToSalesLine."Whse Status" := FromSalesLine."Whse Status";
        ToSalesLine."Delivery Reference No" := FromSalesLine."Delivery Reference No";
        ToSalesLine."Delivery User ID" := FromSalesLine."Delivery User ID";
        ToSalesLine."Delivery Date Time" := FromSalesLine."Delivery Date Time";
        ToSalesLine.Counter := FromSalesLine.Counter;
        ToSalesLine."Option Value Text" := FromSalesLine."Option Value Text";
        ToSalesLine."Estimated Delivery Date" := FromSalesLine."Estimated Delivery Date";
        ToSalesLine."No later than Date" := FromSalesLine."No later than Date";
        ToSalesLine."Payment-At Order Entry-Limit" := FromSalesLine."Payment-At Order Entry-Limit";
        ToSalesLine."Payment-At Delivery-Limit" := FromSalesLine."Payment-At Delivery-Limit";
        ToSalesLine."Return Policy" := FromSalesLine."Return Policy";
        ToSalesLine."Non Refund Amount" := FromSalesLine."Non Refund Amount";
        ToSalesLine."Sourcing Status" := FromSalesLine."Sourcing Status";
        ToSalesLine."Payment-At PurchaseOrder-Limit" := FromSalesLine."Payment-At PurchaseOrder-Limit";
        ToSalesLine."SPO Document Method" := FromSalesLine."SPO Document Method";
        ToSalesLine."Store Sales Location" := FromSalesLine."Store Sales Location";
        ToSalesLine."SPO Whse Location" := FromSalesLine."SPO Whse Location";
        ToSalesLine."Vendor No." := FromSalesLine."Vendor No.";
        ToSalesLine."Item Tracking No." := FromSalesLine."Item Tracking No.";

        //ToSalesLine.MODIFY;
    end;

    procedure CopyPstOptionType(ToConfigurationID: Code[30]; FromConfigurationID: Code[30])
    var
        lFromPstOptionTypeValueHeader: Record "10012728";
        lFromPstOptionTypeValueEntry: Record "10012729";
        lNewOptionTypeValueHeader: Record "10012712";
        lNewOptionTypeValueEntry: Record "10012713";
    begin
        //CopyPstOptionType
        //LS

        lFromPstOptionTypeValueHeader.GET(FromConfigurationID);
        lNewOptionTypeValueHeader.INIT;
        lNewOptionTypeValueHeader.TRANSFERFIELDS(lFromPstOptionTypeValueHeader);
        lNewOptionTypeValueHeader."Configuration ID" := ToConfigurationID;
        lNewOptionTypeValueHeader.VALIDATE("Item No.");
        lNewOptionTypeValueHeader.INSERT(TRUE);

        lFromPstOptionTypeValueEntry.RESET;
        lFromPstOptionTypeValueEntry.SETFILTER("Configuration ID", FromConfigurationID);
        IF lFromPstOptionTypeValueEntry.FINDSET THEN
            REPEAT
                lNewOptionTypeValueEntry.INIT;
                lNewOptionTypeValueEntry.TRANSFERFIELDS(lFromPstOptionTypeValueEntry);
                lNewOptionTypeValueEntry."Configuration ID" := ToConfigurationID;
                lNewOptionTypeValueEntry.INSERT(TRUE);
            UNTIL lFromPstOptionTypeValueEntry.NEXT = 0;
    end;

    procedure CheckInventory(ItemNo: Code[20]; LocationCode: Code[20]; Quantity: Decimal; PickLocation: Code[20])
    var
        SalesSetup: Record "Sales & Receivables Setup";
        ItemRec: Record Item;
        LocationRec: Record Location;
        NetAvailability: Decimal;
        HRUinvtLookupForm: Form "50089";
    begin
        //APNT   T049424 ---
        SalesSetup.GET;
        IF SalesSetup."Block Negative Sales on PSO" THEN BEGIN
            CLEAR(ItemRec);
            CLEAR(LocationRec);
            IF ItemRec.GET(ItemNo) THEN BEGIN
                IF ItemRec."Furniture Item" THEN BEGIN
                    IF LocationRec.GET(LocationCode) THEN BEGIN
                        IF LocationRec."Location Type" <> LocationRec."Location Type"::Store THEN BEGIN
                            CLEAR(HRUinvtLookupForm);
                            CLEAR(NetAvailability);
                            HRUinvtLookupForm.SETRECORD(LocationRec);
                            NetAvailability := HRUinvtLookupForm.GetInventoryExternal(ItemNo);
                            IF (Quantity > 0) AND (Quantity > NetAvailability) THEN
                                ERROR('Quantity %1 is greater than Net Availability %2', Quantity, NetAvailability);
                        END;
                    END;
                END;
            END;
        END;

        SalesSetup.GET;
        IF SalesSetup."Block Negative Sales on PSO" THEN BEGIN
            CLEAR(ItemRec);
            CLEAR(LocationRec);
            IF ItemRec.GET(ItemNo) THEN BEGIN
                IF NOT ItemRec."Furniture Item" THEN BEGIN
                    IF LocationRec.GET(PickLocation) THEN BEGIN
                        IF LocationRec."Sales Order Check" THEN BEGIN
                            CLEAR(HRUinvtLookupForm);
                            CLEAR(NetAvailability);
                            HRUinvtLookupForm.SETRECORD(LocationRec);
                            NetAvailability := HRUinvtLookupForm.GetInventoryExternal(ItemRec."No.");
                            IF (Quantity > 0) AND (Quantity > NetAvailability) THEN
                                ERROR('Quantity %1 is greater than Net Availability %2', Quantity, NetAvailability);
                        END;
                    END;
                END;
            END;
        END;
        // APNT   T049424  +++
    end;
}

