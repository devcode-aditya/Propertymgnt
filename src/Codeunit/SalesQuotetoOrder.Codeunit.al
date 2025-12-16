codeunit 86 "Sales-Quote to Order"
{
    // DP = changes made by DVS

    TableNo = 36;

    trigger OnRun()
    var
        OldSalesCommentLine: Record "Sales Comment Line";
        FromDocDim: Record "Document Dimension";
        ToDocDim: Record "Document Dimension";
        Opp: Record Opportunity;
        OpportunityEntry: Record "Opportunity Entry";
        TempOpportunityEntry: Record "Opportunity Entry" temporary;
        Cust: Record Customer;
    begin
        TESTFIELD("Document Type", "Document Type"::Quote);
        Cust.GET("Sell-to Customer No.");
        Cust.CheckBlockedCustOnDocs(Cust, "Document Type"::Order, TRUE, FALSE);
        CALCFIELDS("Amount Including VAT");
        SalesOrderHeader := Rec;
        IF GUIALLOWED AND NOT HideValidationDialog THEN
            CustCheckCreditLimit.SalesHeaderCheck(SalesOrderHeader);
        SalesOrderHeader."Document Type" := SalesOrderHeader."Document Type"::Order;

        SalesQuoteLine.SETRANGE("Document Type", "Document Type");
        SalesQuoteLine.SETRANGE("Document No.", "No.");
        SalesQuoteLine.SETRANGE(Type, SalesQuoteLine.Type::Item);
        SalesQuoteLine.SETFILTER("No.", '<>%1', '');
        IF SalesQuoteLine.FINDSET THEN
            REPEAT
                IF (SalesQuoteLine."Outstanding Quantity" > 0) THEN BEGIN
                    SalesLine := SalesQuoteLine;
                    SalesLine.VALIDATE("Reserved Qty. (Base)", 0);
                    SalesLine."Line No." := 0;
                    IF GUIALLOWED AND NOT HideValidationDialog THEN
                        ItemCheckAvail.SalesLineCheck(SalesLine);
                END;
            UNTIL SalesQuoteLine.NEXT = 0;

        Opp.RESET;
        Opp.SETCURRENTKEY("Sales Document Type", "Sales Document No.");
        Opp.SETRANGE("Sales Document Type", Opp."Sales Document Type"::Quote);
        Opp.SETRANGE("Sales Document No.", "No.");
        Opp.SETRANGE(Status, Opp.Status::"In Progress");
        IF Opp.FINDFIRST THEN
            IF CONFIRM(Text000 + Text001 + Text002, TRUE) THEN BEGIN
                TempOpportunityEntry.DELETEALL;
                TempOpportunityEntry.INIT;
                TempOpportunityEntry.VALIDATE("Opportunity No.", Opp."No.");
                TempOpportunityEntry."Sales Cycle Code" := Opp."Sales Cycle Code";
                TempOpportunityEntry."Contact No." := Opp."Contact No.";
                TempOpportunityEntry."Contact Company No." := Opp."Contact Company No.";
                TempOpportunityEntry."Salesperson Code" := Opp."Salesperson Code";
                TempOpportunityEntry."Campaign No." := Opp."Campaign No.";
                TempOpportunityEntry."Action Taken" := TempOpportunityEntry."Action Taken"::Won;
                TempOpportunityEntry.INSERT;
                TempOpportunityEntry.SETRANGE("Action Taken", TempOpportunityEntry."Action Taken"::Won);
                FORM.RUNMODAL(FORM::"Close Opportunity", TempOpportunityEntry);
                Opp.RESET;
                Opp.SETCURRENTKEY("Sales Document Type", "Sales Document No.");
                Opp.SETRANGE("Sales Document Type", Opp."Sales Document Type"::Quote);
                Opp.SETRANGE("Sales Document No.", "No.");
                Opp.SETRANGE(Status, Opp.Status::"In Progress");
                IF Opp.FINDFIRST THEN
                    ERROR(Text003)
                ELSE BEGIN
                    COMMIT;
                    GET("Document Type", "No.");
                END;
            END ELSE
                ERROR(Text004);

        SalesOrderHeader."No. Printed" := 0;
        SalesOrderHeader.Status := SalesOrderHeader.Status::Open;
        SalesOrderHeader."No." := '';
        SalesOrderHeader."Quote No." := "No.";
        SalesOrderLine.LOCKTABLE;
        SalesOrderHeader.INSERT(TRUE);

        FromDocDim.SETRANGE("Table ID", DATABASE::"Sales Header");
        FromDocDim.SETRANGE("Document Type", "Document Type");
        FromDocDim.SETRANGE("Document No.", "No.");

        ToDocDim.SETRANGE("Table ID", DATABASE::"Sales Header");
        ToDocDim.SETRANGE("Document Type", SalesOrderHeader."Document Type");
        ToDocDim.SETRANGE("Document No.", SalesOrderHeader."No.");
        ToDocDim.DELETEALL;

        DocDim.MoveDocDimToDocDim(
          FromDocDim,
          DATABASE::"Sales Header",
          SalesOrderHeader."No.",
          SalesOrderHeader."Document Type",
          0);

        SalesOrderHeader."Order Date" := "Order Date";
        IF "Posting Date" <> 0D THEN
            SalesOrderHeader."Posting Date" := "Posting Date";
        SalesOrderHeader."Document Date" := "Document Date";
        SalesOrderHeader."Shipment Date" := "Shipment Date";
        SalesOrderHeader."Shortcut Dimension 1 Code" := "Shortcut Dimension 1 Code";
        SalesOrderHeader."Shortcut Dimension 2 Code" := "Shortcut Dimension 2 Code";
        SalesOrderHeader."Date Sent" := 0D;
        SalesOrderHeader."Time Sent" := 0T;

        SalesOrderHeader."Location Code" := "Location Code";
        SalesOrderHeader."Outbound Whse. Handling Time" := "Outbound Whse. Handling Time";
        SalesOrderHeader."Ship-to Name" := "Ship-to Name";
        SalesOrderHeader."Ship-to Name 2" := "Ship-to Name 2";
        SalesOrderHeader."Ship-to Address" := "Ship-to Address";
        SalesOrderHeader."Ship-to Address 2" := "Ship-to Address 2";
        SalesOrderHeader."Ship-to City" := "Ship-to City";
        SalesOrderHeader."Ship-to Post Code" := "Ship-to Post Code";
        SalesOrderHeader."Ship-to County" := "Ship-to County";
        SalesOrderHeader."Ship-to Country/Region Code" := "Ship-to Country/Region Code";
        SalesOrderHeader."Ship-to Contact" := "Ship-to Contact";

        SalesOrderHeader."Prepayment %" := Cust."Prepayment %";
        IF SalesOrderHeader."Posting Date" = 0D THEN
            SalesOrderHeader."Posting Date" := WORKDATE;

        //DP6.01.01 START
        SalesOrderHeader."Ref. Document Type" := "Ref. Document Type";
        SalesOrderHeader."Ref. Document No." := "Ref. Document No.";
        //DP6.01.01 STOP

        SalesOrderHeader.MODIFY;

        SalesQuoteLine.RESET;
        SalesQuoteLine.SETRANGE("Document Type", "Document Type");
        SalesQuoteLine.SETRANGE("Document No.", "No.");

        FromDocDim.SETRANGE("Table ID", DATABASE::"Sales Line");
        ToDocDim.SETRANGE("Table ID", DATABASE::"Sales Line");

        IF SalesQuoteLine.FINDSET THEN
            REPEAT
                SalesOrderLine := SalesQuoteLine;
                SalesOrderLine."Document Type" := SalesOrderHeader."Document Type";
                SalesOrderLine."Document No." := SalesOrderHeader."No.";
                ReserveSalesLine.TransferSaleLineToSalesLine(
                  SalesQuoteLine, SalesOrderLine, SalesQuoteLine."Outstanding Qty. (Base)");
                SalesOrderLine."Shortcut Dimension 1 Code" := SalesQuoteLine."Shortcut Dimension 1 Code";
                SalesOrderLine."Shortcut Dimension 2 Code" := SalesQuoteLine."Shortcut Dimension 2 Code";

                IF Cust."Prepayment %" <> 0 THEN
                    SalesOrderLine."Prepayment %" := Cust."Prepayment %";
                PrepmtMgt.SetSalesPrepaymentPct(SalesOrderLine, SalesOrderHeader."Posting Date");
                SalesOrderLine.VALIDATE("Prepayment %");

                SalesOrderLine.INSERT;

                ReserveSalesLine.VerifyQuantity(SalesOrderLine, SalesQuoteLine);

                IF SalesOrderLine.Reserve = SalesOrderLine.Reserve::Always THEN BEGIN
                    SalesOrderLine.AutoReserve;
                END;

                FromDocDim.SETRANGE("Line No.", SalesQuoteLine."Line No.");

                ToDocDim.SETRANGE("Line No.", SalesOrderLine."Line No.");
                ToDocDim.DELETEALL;
                DocDim.MoveDocDimToDocDim(
                  FromDocDim,
                  DATABASE::"Sales Line",
                  SalesOrderHeader."No.",
                  SalesOrderHeader."Document Type",
                  SalesOrderLine."Line No.");
            UNTIL SalesQuoteLine.NEXT = 0;

        SalesSetup.GET;
        IF SalesSetup."Archive Quotes and Orders" THEN
            ArchiveManagement.ArchSalesDocumentNoConfirm(Rec);

        IF SalesSetup."Default Posting Date" = SalesSetup."Default Posting Date"::"No Date" THEN BEGIN
            SalesOrderHeader."Posting Date" := 0D;
            SalesOrderHeader.MODIFY;
        END;

        SalesCommentLine.SETRANGE("Document Type", "Document Type");
        SalesCommentLine.SETRANGE("No.", "No.");
        IF NOT SalesCommentLine.ISEMPTY THEN BEGIN
            SalesCommentLine.LOCKTABLE;
            IF SalesCommentLine.FINDSET THEN
                REPEAT
                    OldSalesCommentLine := SalesCommentLine;
                    SalesCommentLine.DELETE;
                    SalesCommentLine."Document Type" := SalesOrderHeader."Document Type";
                    SalesCommentLine."No." := SalesOrderHeader."No.";
                    SalesCommentLine.INSERT;
                    SalesCommentLine := OldSalesCommentLine;
                UNTIL SalesCommentLine.NEXT = 0;
        END;
        SalesOrderHeader.COPYLINKS(Rec);

        ItemChargeAssgntSales.RESET;
        ItemChargeAssgntSales.SETRANGE("Document Type", "Document Type");
        ItemChargeAssgntSales.SETRANGE("Document No.", "No.");
        WHILE ItemChargeAssgntSales.FINDFIRST DO BEGIN
            ItemChargeAssgntSales.DELETE;
            ItemChargeAssgntSales."Document Type" := SalesOrderHeader."Document Type";
            ItemChargeAssgntSales."Document No." := SalesOrderHeader."No.";
            IF NOT (ItemChargeAssgntSales."Applies-to Doc. Type" IN
                    [ItemChargeAssgntSales."Applies-to Doc. Type"::Shipment,
                     ItemChargeAssgntSales."Applies-to Doc. Type"::"Return Receipt"])
            THEN BEGIN
                ItemChargeAssgntSales."Applies-to Doc. Type" := SalesOrderHeader."Document Type";
                ItemChargeAssgntSales."Applies-to Doc. No." := SalesOrderHeader."No.";
            END;
            ItemChargeAssgntSales.INSERT;
        END;

        Opp.RESET;
        Opp.SETCURRENTKEY("Sales Document Type", "Sales Document No.");
        Opp.SETRANGE("Sales Document Type", Opp."Sales Document Type"::Quote);
        Opp.SETRANGE("Sales Document No.", "No.");
        IF Opp.FINDFIRST THEN BEGIN
            IF Opp.Status = Opp.Status::Won THEN BEGIN
                Opp."Sales Document Type" := Opp."Sales Document Type"::Order;
                Opp."Sales Document No." := SalesOrderHeader."No.";
                Opp.MODIFY;
                OpportunityEntry.RESET;
                OpportunityEntry.SETCURRENTKEY(Active, "Opportunity No.");
                OpportunityEntry.SETRANGE(Active, TRUE);
                OpportunityEntry.SETRANGE("Opportunity No.", Opp."No.");
                IF OpportunityEntry.FINDFIRST THEN BEGIN
                    OpportunityEntry."Calcd. Current Value (LCY)" := OpportunityEntry.GetSalesDocValue(SalesOrderHeader);
                    OpportunityEntry.MODIFY;
                END;
            END ELSE
                IF Opp.Status = Opp.Status::Lost THEN BEGIN
                    Opp."Sales Document Type" := Opp."Sales Document Type"::" ";
                    Opp."Sales Document No." := '';
                    Opp.MODIFY;
                END;
        END;

        DELETELINKS;
        DELETE;
        SalesQuoteLine.DELETEALL;
        FromDocDim.SETFILTER("Table ID", '%1|%2', DATABASE::"Sales Header", DATABASE::"Sales Line");
        FromDocDim.SETRANGE("Line No.");
        FromDocDim.DELETEALL;

        COMMIT;
        CLEAR(CustCheckCreditLimit);
        CLEAR(ItemCheckAvail);
    end;

    var
        Text000: Label 'An Open Opportunity is linked to this quote.\';
        Text001: Label 'It has to be closed before an Order can be made.\';
        Text002: Label 'Do you wish to close this Opportunity now?';
        Text003: Label 'Wizard Aborted';
        SalesQuoteLine: Record "Sales Line";
        SalesLine: Record "Sales Line";
        SalesOrderHeader: Record "Sales Header";
        SalesOrderLine: Record "Sales Line";
        SalesCommentLine: Record "Sales Comment Line";
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
        CustCheckCreditLimit: Codeunit "312";
        ItemCheckAvail: Codeunit "311";
        ReserveSalesLine: Codeunit "99000832";
        DocDim: Codeunit "408";
        PrepmtMgt: Codeunit "441";
        HideValidationDialog: Boolean;
        Text004: Label 'The Opportunity has not been closed. The program has aborted making the Order.';
        SalesDocLineComment: Record "Sales Comment Line";
        SalesSetup: Record "Sales & Receivables Setup";
        ArchiveManagement: Codeunit "5063";

    procedure GetSalesOrderHeader(var SalesHeader2: Record "Sales Header")
    begin
        SalesHeader2 := SalesOrderHeader;
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;
}

