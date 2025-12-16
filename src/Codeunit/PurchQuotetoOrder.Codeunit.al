codeunit 96 "Purch.-Quote to Order"
{
    // DP = changes made by DVS

    TableNo = 38;

    trigger OnRun()
    var
        OldPurchCommentLine: Record "Purch. Comment Line";
        FromDocDim: Record "Document Dimension";
        ToDocDim: Record "Document Dimension";
        Vend: Record Vendor;
    begin
        TESTFIELD("Document Type", "Document Type"::Quote);
        Vend.GET("Buy-from Vendor No.");
        Vend.CheckBlockedVendOnDocs(Vend, FALSE);

        PurchOrderHeader := Rec;
        PurchOrderHeader."Document Type" := PurchOrderHeader."Document Type"::Order;
        PurchOrderHeader."No. Printed" := 0;
        PurchOrderHeader.Status := PurchOrderHeader.Status::Open;
        PurchOrderHeader."No." := '';
        PurchOrderHeader."Quote No." := "No.";

        PurchOrderLine.LOCKTABLE;
        PurchOrderHeader.INSERT(TRUE);

        FromDocDim.SETRANGE("Table ID", DATABASE::"Purchase Header");
        FromDocDim.SETRANGE("Document Type", "Document Type");
        FromDocDim.SETRANGE("Document No.", "No.");

        ToDocDim.SETRANGE("Table ID", DATABASE::"Purchase Header");
        ToDocDim.SETRANGE("Document Type", PurchOrderHeader."Document Type");
        ToDocDim.SETRANGE("Document No.", PurchOrderHeader."No.");
        ToDocDim.DELETEALL;

        DocDim.MoveDocDimToDocDim(
          FromDocDim,
          DATABASE::"Purchase Header",
          PurchOrderHeader."No.",
          PurchOrderHeader."Document Type",
          0);

        PurchOrderHeader."Order Date" := "Order Date";
        IF "Posting Date" <> 0D THEN
            PurchOrderHeader."Posting Date" := "Posting Date";
        PurchOrderHeader."Document Date" := "Document Date";
        PurchOrderHeader."Expected Receipt Date" := "Expected Receipt Date";
        PurchOrderHeader."Shortcut Dimension 1 Code" := "Shortcut Dimension 1 Code";
        PurchOrderHeader."Shortcut Dimension 2 Code" := "Shortcut Dimension 2 Code";
        PurchOrderHeader."Date Received" := 0D;
        PurchOrderHeader."Time Received" := 0T;
        PurchOrderHeader."Date Sent" := 0D;
        PurchOrderHeader."Time Sent" := 0T;

        PurchOrderHeader."Location Code" := "Location Code";
        PurchOrderHeader."Inbound Whse. Handling Time" := "Inbound Whse. Handling Time";
        PurchOrderHeader."Ship-to Name" := "Ship-to Name";
        PurchOrderHeader."Ship-to Name 2" := "Ship-to Name 2";
        PurchOrderHeader."Ship-to Address" := "Ship-to Address";
        PurchOrderHeader."Ship-to Address 2" := "Ship-to Address 2";
        PurchOrderHeader."Ship-to City" := "Ship-to City";
        PurchOrderHeader."Ship-to Post Code" := "Ship-to Post Code";
        PurchOrderHeader."Ship-to County" := "Ship-to County";
        PurchOrderHeader."Ship-to Country/Region Code" := "Ship-to Country/Region Code";
        PurchOrderHeader."Ship-to Contact" := "Ship-to Contact";

        PurchOrderHeader."Prepayment %" := Vend."Prepayment %";
        IF PurchOrderHeader."Posting Date" = 0D THEN
            PurchOrderHeader."Posting Date" := WORKDATE;

        //DP6.01.01 START
        PurchOrderHeader."Ref. Document Type" := "Ref. Document Type";
        PurchOrderHeader."Ref. Document No." := "Ref. Document No.";
        //DP6.01.01 STOP

        PurchOrderHeader.MODIFY;

        PurchQuoteLine.SETRANGE("Document Type", "Document Type");
        PurchQuoteLine.SETRANGE("Document No.", "No.");

        FromDocDim.SETRANGE("Table ID", DATABASE::"Purchase Line");
        ToDocDim.SETRANGE("Table ID", DATABASE::"Purchase Line");

        IF PurchQuoteLine.FINDSET THEN
            REPEAT
                PurchOrderLine := PurchQuoteLine;
                PurchOrderLine."Document Type" := PurchOrderHeader."Document Type";
                PurchOrderLine."Document No." := PurchOrderHeader."No.";
                ReservePurchLine.TransferPurchLineToPurchLine(
                  PurchQuoteLine, PurchOrderLine, PurchQuoteLine."Outstanding Qty. (Base)");
                PurchOrderLine."Shortcut Dimension 1 Code" := PurchQuoteLine."Shortcut Dimension 1 Code";
                PurchOrderLine."Shortcut Dimension 2 Code" := PurchQuoteLine."Shortcut Dimension 2 Code";

                IF Vend."Prepayment %" <> 0 THEN
                    PurchOrderLine."Prepayment %" := Vend."Prepayment %";
                PrepmtMgt.SetPurchPrepaymentPct(PurchOrderLine, PurchOrderHeader."Posting Date");
                PurchOrderLine.VALIDATE("Prepayment %");

                PurchOrderLine.INSERT;

                ReservePurchLine.VerifyQuantity(PurchOrderLine, PurchQuoteLine);

                FromDocDim.SETRANGE("Line No.", PurchQuoteLine."Line No.");

                ToDocDim.SETRANGE("Line No.", PurchOrderLine."Line No.");
                ToDocDim.DELETEALL;

                DocDim.MoveDocDimToDocDim(
                  FromDocDim,
                  DATABASE::"Purchase Line",
                  PurchOrderHeader."No.",
                  PurchOrderHeader."Document Type",
                  PurchOrderLine."Line No.");
            UNTIL PurchQuoteLine.NEXT = 0;

        PurchSetup.GET;
        IF PurchSetup."Archive Quotes and Orders" THEN
            ArchiveManagement.ArchPurchDocumentNoConfirm(Rec);

        IF PurchSetup."Default Posting Date" = PurchSetup."Default Posting Date"::"No Date" THEN BEGIN
            PurchOrderHeader."Posting Date" := WORKDATE;
            PurchOrderHeader.MODIFY;
        END;

        PurchCommentLine.SETRANGE("Document Type", "Document Type");
        PurchCommentLine.SETRANGE("No.", "No.");
        IF NOT PurchCommentLine.ISEMPTY THEN BEGIN
            PurchCommentLine.LOCKTABLE;
            IF PurchCommentLine.FINDSET THEN
                REPEAT
                    OldPurchCommentLine := PurchCommentLine;
                    PurchCommentLine.DELETE;
                    PurchCommentLine."Document Type" := PurchOrderHeader."Document Type";
                    PurchCommentLine."No." := PurchOrderHeader."No.";
                    PurchCommentLine.INSERT;
                    PurchCommentLine := OldPurchCommentLine;
                UNTIL PurchCommentLine.NEXT = 0;
        END;
        PurchOrderHeader.COPYLINKS(Rec);

        ItemChargeAssgntPurch.RESET;
        ItemChargeAssgntPurch.SETRANGE("Document Type", "Document Type");
        ItemChargeAssgntPurch.SETRANGE("Document No.", "No.");

        WHILE ItemChargeAssgntPurch.FINDFIRST DO BEGIN
            ItemChargeAssgntPurch.DELETE;
            ItemChargeAssgntPurch."Document Type" := PurchOrderHeader."Document Type";
            ItemChargeAssgntPurch."Document No." := PurchOrderHeader."No.";
            IF NOT (ItemChargeAssgntPurch."Applies-to Doc. Type" IN
              [ItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt,
               ItemChargeAssgntPurch."Applies-to Doc. Type"::"Return Shipment"])
            THEN BEGIN
                ItemChargeAssgntPurch."Applies-to Doc. Type" := PurchOrderHeader."Document Type";
                ItemChargeAssgntPurch."Applies-to Doc. No." := PurchOrderHeader."No.";
            END;
            ItemChargeAssgntPurch.INSERT;
        END;

        DELETELINKS;
        DELETE;
        PurchQuoteLine.DELETEALL;
        FromDocDim.SETFILTER("Table ID", '%1|%2', DATABASE::"Purchase Header", DATABASE::"Purchase Line");
        FromDocDim.SETRANGE("Line No.");
        FromDocDim.DELETEALL;

        COMMIT;
    end;

    var
        PurchQuoteLine: Record "Purchase Line";
        PurchOrderHeader: Record "Purchase Header";
        PurchOrderLine: Record "Purchase Line";
        PurchCommentLine: Record "Purch. Comment Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        ReservePurchLine: Codeunit "99000834";
        DocDim: Codeunit "408";
        PrepmtMgt: Codeunit "441";
        PurchSetup: Record "Purchases & Payables Setup";
        ArchiveManagement: Codeunit "5063";

    procedure GetPurchOrderHeader(var PurchHeader: Record "Purchase Header")
    begin
        PurchHeader := PurchOrderHeader;
    end;
}

