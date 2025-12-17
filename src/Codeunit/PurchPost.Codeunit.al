codeunit 90 "Purch.-Post"
{
    // LS = Changes made by LS Retail
    // Code          Date      Name            Description
    // APNT-CO1.0    15.08.10  Tanweer         Added Code for Costing Customization
    // APNT-IC1.0    16.02.12  Tanweer         Added code for IC Customization
    // APNT-CO2.0    06.05.12  Ashish          Added Code for Costing Customization
    // APNT-CO2.1    05.07.12  Shameema        Added function and code for posted charges if unposted
    // DP = changes made by DVS
    // APNT-HRU1.0   10.03.14  Sangeeta        Added code for HRU Customization (Task ID - T002991)
    // APNT-INB1.0   15.04.15                  Added code to skip intercompany confirmation message
    // APNT-WMS1.0   22.03.17  Sujith          Added code for WMS Palm customization
    // APNT-T027996  02.07.19  Sujith          Added code for Warehouse employee posting restrictions.
    // GC            24.11.19  Ganesh          code added purch credit memo external doc error
    // T029871       04.11.19  Aarti           Added code for HHT serial/lo no customization
    // SP-03-02-2020           Sumit           Added for reflecting same description as mentioned in Purch. Order/Inv./Cr. Memo lines
    //                                         for G/L account in "Gen. Journal Line" & "G/L Entry"(through codeunit 12) table if
    //                                         G/L description is true in GLS (Table 98)
    // 20210404      04-Apr-21 KPS             Merged code for allowing PO's having only G/L Accounts to post w/o
    //                                            location restriction OTRS#5797757
    // T044145       13.07.22   Sujith         Added code for CRF_22_0859

    Permissions = TableData 36 = m,
                  TableData 37 = m,
                  TableData 39 = imd,
                  TableData 49 = imd,
                  TableData 93 = imd,
                  TableData 94 = imd,
                  TableData 110 = imd,
                  TableData 111 = imd,
                  TableData 120 = imd,
                  TableData 121 = imd,
                  TableData 122 = imd,
                  TableData 123 = imd,
                  TableData 124 = imd,
                  TableData 125 = imd,
                  TableData 223 = imd,
                  TableData 357 = imd,
                  TableData 359 = imd,
                  TableData 6507 = ri,
                  TableData 6508 = rid,
                  TableData 6650 = imd,
                  TableData 6651 = imd;
    TableNo = 38;

    trigger OnRun()
    var
        ItemChargeAssgntPurch: Record "5805";
        TempJnlLineDim: Record "Gen. Journal Line Dimension" temporary;
        ItemEntryRelation: Record "6507";
        TempInvoicingSpecification: Record "Tracking Specification" temporary;
        DummyTrackingSpecification: Record "Tracking Specification";
        Vendor: Record Vendor;
        ICHandledInboxTransaction: Record "IC Inbox Transaction";
        ICPartner: Record "IC Partner";
        SalesSetup: Record "Sales & Receivables Setup";
        SalesCommentLine: Record "Sales Comment Line";
        PurchInvHdr: Record "Purch. Inv. Header";
        PurchHeader2: Record "Purchase Header";
        ICInboxPurchHdr: Record "IC Inbox Purchase Header";
        SalesHeader: Record "Sales Header";
        UpdateAnalysisView: Codeunit "410";
        UpdateItemAnalysisView: Codeunit "7150";
        CostBaseAmount: Decimal;
        TrackingSpecificationExists: Boolean;
        EndLoop: Boolean;
        TempPrePmtAmtToDeduct: Decimal;
        TempDocDim2: Record "Document Dimension" temporary;
        xICTHeader: Record "10000777";
        xItemLedgerEntry: Record "Item Ledger Entry";
        VendorPerformanceMgt: Codeunit "10012211";
        DocGroupLine: Record "10012222";
        GLReg: Record "G/L Register";
        ItemRec: Record "Item Register";
        PurchLines: Record "Purchase Line";
        ICOutboxExport: Codeunit "431";
        PremiseMgmtSetup: Record "Premise Management Setup";
        WorkOrderLine: Record "Work Order Line";
        PurchRcptHdr: Record "Purch. Rcpt. Header";
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseEmployee2: Record "Warehouse Employee";
        PurchaseLine2: Record "Purchase Line";
        PurchLine1: Record "Purchase Line";
        HHTTransactions: Record "HHT Transactions";
        HHTTransHdr: Record "HHT Trans Hdr";
    begin
        //APNT-CO1.0
        CALCFIELDS("Total Landed Cost (LCY)");
        IF ("Total Landed Cost (LCY)" <> 0) AND ("Document Type" = "Document Type"::"Credit Memo") THEN BEGIN
            IF "No Item Charges" = FALSE THEN BEGIN
                PurchLines.RESET;
                PurchLines.SETRANGE("Document Type", "Document Type");
                PurchLines.SETRANGE("Document No.", "No.");
                PurchLines.SETFILTER(Type, '%1|%2', PurchLines.Type::Item, PurchLines.Type::"Fixed Asset");
                IF PurchLines.FIND('-') THEN
                    REPEAT
                        IF PurchLines."Indirect Cost %" = 0 THEN
                            ERROR('Please calculate Item Charges before posting.');
                    UNTIL PurchLines.NEXT = 0;
            END;
        END;
        //APNT-CO1.0
        //>> 20210404 Merged by KPS on 04-Apr-2021
        //APNT-T027996 +
        PurchaseLine2.RESET;
        PurchaseLine2.SETFILTER("Document Type", '%1|%2', PurchaseLine2."Document Type"::Order,
        PurchaseLine2."Document Type"::"Return Order");
        PurchaseLine2.SETRANGE("Document No.", "No.");
        PurchaseLine2.SETFILTER(Type, '<>%1&<>%2', PurchaseLine2.Type::" ", PurchaseLine2.Type::"G/L Account");
        IF PurchaseLine2.FINDFIRST THEN
            CheckLines := TRUE;
        //<< End of merging by KPS on 04-Apr-2021

        //APNT-T027996 +
        CLEAR(InvtSetup);
        InvtSetup.GET;
        IF InvtSetup."Restrict Order Posting" THEN BEGIN
            WarehouseEmployee.RESET;
            WarehouseEmployee.SETRANGE("User ID", USERID);
            IF WarehouseEmployee.FINDFIRST THEN BEGIN
                CLEAR(PurchaseLine2);
                PurchaseLine2.RESET;
                PurchaseLine2.SETFILTER("Document Type", '%1|%2', PurchaseLine2."Document Type"::Order,
                PurchaseLine2."Document Type"::"Return Order");
                PurchaseLine2.SETRANGE("Document No.", "No.");
                IF "Document Type" = "Document Type"::Order THEN
                    PurchaseLine2.SETFILTER("Qty. to Receive", '<>%1', 0)
                ELSE
                    IF "Document Type" = "Document Type"::"Return Order" THEN
                        PurchaseLine2.SETFILTER("Return Qty. to Ship", '<>%1', 0);
                IF PurchaseLine2.FINDFIRST THEN
                    REPEAT
                        WarehouseEmployee2.RESET;
                        WarehouseEmployee2.SETRANGE("User ID", USERID);
                        WarehouseEmployee2.SETFILTER("Location Code", '%1|%2', PurchaseLine2."Location Code", '');
                        WarehouseEmployee2.SETRANGE(Purchase, TRUE);
                        IF NOT WarehouseEmployee2.FINDFIRST THEN
                            ERROR('You do not have permissions to post Purchase %2 %1.', "No.", PurchaseLine2."Document Type");
                    UNTIL PurchaseLine2.NEXT = 0;
            END ELSE
                ERROR('You do not have permissions to post Purchase %2 %1.', "No.", "Document Type");
        END;
        //APNT-T027996 +

        IF PostingDateExists AND (ReplacePostingDate OR ("Posting Date" = 0D)) THEN BEGIN
            "Posting Date" := PostingDate;
            VALIDATE("Currency Code");
        END;

        IF PostingDateExists AND (ReplaceDocumentDate OR ("Document Date" = 0D)) THEN
            VALIDATE("Document Date", PostingDate);

        CLEARALL;
        PurchHeader.COPY(Rec);
        WITH PurchHeader DO BEGIN
            TESTFIELD("Document Type");
            TESTFIELD("Buy-from Vendor No.");
            TESTFIELD("Pay-to Vendor No.");
            TESTFIELD("Posting Date");
            TESTFIELD("Document Date");
            IF GenJnlCheckLine.DateNotAllowed("Posting Date") THEN
                FIELDERROR("Posting Date", Text045);

            CASE "Document Type" OF
                "Document Type"::Order:
                    Ship := FALSE;
                "Document Type"::Invoice:
                    BEGIN
                        Receive := TRUE;
                        Invoice := TRUE;
                        Ship := FALSE;
                    END;
                "Document Type"::"Return Order":
                    Receive := FALSE;
                "Document Type"::"Credit Memo":
                    BEGIN
                        Receive := FALSE;
                        Invoice := TRUE;
                        Ship := TRUE;
                    END;
            END;

            IF NOT (Receive OR Invoice OR Ship) THEN
                ERROR(
                  Text025,
                  FIELDCAPTION(Receive), FIELDCAPTION(Invoice), FIELDCAPTION(Ship));

            /*
            //APNT-T009914
            CreateBinLedgerEntries(Rec);
            //APNT-T009914
            */

            WhseReference := "Posting from Whse. Ref.";
            "Posting from Whse. Ref." := 0;

            //LS -
            GetGLSetup;
            LSRetailSetup.GET();
            //LS +

            IF Invoice THEN
                CreatePrepmtLines(PurchHeader, TempPrepmtPurchLine, PrepmtDocDim, TRUE);
            CopyAndCheckDocDimToTempDocDim;

            CopyAprvlToTempApprvl;

            Vend.GET("Buy-from Vendor No.");
            Vend.CheckBlockedVendOnDocs(Vend, TRUE);
            //T044145 -
            CompanyInformation.GET();
            IF CompanyInformation."Enable Vendor Approval Process" THEN
                Vend.CheckVendorStatus(Vend, TRUE);
            //T044145 +
            IF "Pay-to Vendor No." <> "Buy-from Vendor No." THEN BEGIN
                Vend.GET("Pay-to Vendor No.");
                Vend.CheckBlockedVendOnDocs(Vend, TRUE);
                //T044145 -
                CompanyInformation.GET();
                IF CompanyInformation."Enable Vendor Approval Process" THEN
                    Vend.CheckVendorStatus(Vend, TRUE);
                //T044145 +
            END;

            IF "Send IC Document" AND ("IC Direction" = "IC Direction"::Outgoing) AND
               ("Document Type" IN ["Document Type"::Order, "Document Type"::"Return Order"]) THEN
                IF NOT CONFIRM(Text058) THEN
                    ERROR('');

            IF Invoice AND ("IC Direction" = "IC Direction"::Incoming) THEN BEGIN
                IF "Document Type" = "Document Type"::Order THEN BEGIN
                    IF "Vendor Order No." <> '' THEN BEGIN //APNT-INB1.0 NEW LINE
                        PurchHeader2.SETRANGE("Document Type", "Document Type"::Invoice);
                        PurchHeader2.SETRANGE("Vendor Order No.", "Vendor Order No.");
                        IF PurchHeader2.FINDFIRST THEN
                            IF NOT CONFIRM(Text052, TRUE, PurchHeader."No.", PurchHeader2."No.") THEN
                                ERROR('');
                        ICInboxPurchHdr.SETRANGE("Document Type", "Document Type"::Invoice);
                        ICInboxPurchHdr.SETRANGE("Vendor Order No.", "Vendor Order No.");
                        IF ICInboxPurchHdr.FINDFIRST THEN
                            IF NOT CONFIRM(Text053, TRUE, PurchHeader."No.", ICInboxPurchHdr."No.") THEN
                                ERROR('');
                        PurchInvHdr.SETRANGE("Vendor Order No.", "Vendor Order No.");
                        IF PurchInvHdr.FINDFIRST THEN
                            IF NOT CONFIRM(Text054, FALSE, PurchInvHdr."No.", PurchHeader."No.") THEN
                                ERROR('');
                    END;  //APNT-INB1.0 NEW LINE
                END;
                IF ("Document Type" = "Document Type"::Invoice) AND ("Vendor Order No." <> '') THEN BEGIN
                    IF "Vendor Order No." <> '' THEN BEGIN //APNT-INB1.0 NEW LINE
                        PurchHeader2.SETRANGE("Document Type", "Document Type"::Order);
                        PurchHeader2.SETRANGE("Vendor Order No.", "Vendor Order No.");
                        IF PurchHeader2.FINDFIRST THEN
                            IF NOT CONFIRM(Text055, TRUE, PurchHeader2."No.", PurchHeader."No.") THEN
                                ERROR('');
                        ICInboxPurchHdr.SETRANGE("Document Type", "Document Type"::Order);
                        ICInboxPurchHdr.SETRANGE("Vendor Order No.", "Vendor Order No.");
                        IF ICInboxPurchHdr.FINDFIRST THEN
                            IF NOT CONFIRM(Text056, TRUE, PurchHeader."No.", ICInboxPurchHdr."No.") THEN
                                ERROR('');
                        PurchInvHdr.SETRANGE("Vendor Order No.", "Vendor Order No.");
                        IF PurchInvHdr.FINDFIRST THEN
                            IF NOT CONFIRM(Text057, FALSE, PurchInvHdr."No.", PurchHeader."No.") THEN
                                ERROR('');
                    END; //APNT-INB1.0 NEW LINE
                END;
            END;

            IF Invoice THEN BEGIN
                PurchLine.RESET;
                PurchLine.SETRANGE("Document Type", "Document Type");
                PurchLine.SETRANGE("Document No.", "No.");
                PurchLine.SETFILTER(Quantity, '<>0');
                IF "Document Type" IN ["Document Type"::Order, "Document Type"::"Return Order"] THEN
                    PurchLine.SETFILTER("Qty. to Invoice", '<>0');
                Invoice := NOT PurchLine.ISEMPTY;
                IF Invoice AND (NOT Receive) AND
                   ("Document Type" = "Document Type"::Order)
                THEN BEGIN
                    Invoice := FALSE;
                    PurchLine.FINDSET;
                    REPEAT
                        Invoice := (PurchLine."Quantity Received" - PurchLine."Quantity Invoiced") <> 0;
                    UNTIL Invoice OR (PurchLine.NEXT = 0);
                END ELSE
                    IF Invoice AND (NOT (Ship)) AND
                       ("Document Type" = "Document Type"::"Return Order")
                    THEN BEGIN
                        Invoice := FALSE;
                        PurchLine.FINDSET;
                        REPEAT
                            Invoice := (PurchLine."Return Qty. Shipped" - PurchLine."Quantity Invoiced") <> 0;
                        UNTIL Invoice OR (PurchLine.NEXT = 0);
                    END;
            END;

            IF Invoice THEN
                CopyAndCheckItemCharge(PurchHeader);

            IF Receive THEN BEGIN
                PurchLine.RESET;
                PurchLine.SETRANGE("Document Type", "Document Type");
                PurchLine.SETRANGE("Document No.", "No.");
                PurchLine.SETFILTER(Quantity, '<>0');
                IF "Document Type" = "Document Type"::Order THEN
                    PurchLine.SETFILTER("Qty. to Receive", '<>0');
                PurchLine.SETRANGE("Receipt No.", '');
                Receive := PurchLine.FINDFIRST;
                WhseReceive := TempWhseRcptHeader.FINDFIRST;
                WhseShip := TempWhseShptHeader.FINDFIRST;
                InvtPickPutaway := WhseReference <> 0;
                IF Receive THEN
                    CheckTrackingSpecification(PurchLine);
                IF Receive AND NOT (WhseReceive OR WhseShip OR InvtPickPutaway) THEN
                    CheckWarehouse(PurchLine);

                //APNT-WMS1.0
                // Check External Document number
                IF PurchSetup."Ext. Doc. No. Mandatory" OR
                  ("Vendor Invoice No." <> '')
                THEN BEGIN
                    IF PurchLine."Qty. to Receive" <> 0 THEN BEGIN
                        CLEAR(PurchRcptHdr);
                        PurchRcptHdr.RESET;
                        PurchRcptHdr.SETCURRENTKEY("Vendor Invoice No.");
                        PurchRcptHdr.SETRANGE("Vendor Invoice No.", "Vendor Invoice No.");
                        PurchRcptHdr.SETRANGE("Buy-from Vendor No.", "Buy-from Vendor No.");
                        IF PurchRcptHdr.FINDFIRST THEN BEGIN
                            //PurchLine1.SETRANGE(PurchLine1."Document No.",PurchRcptHdr."Order No.");
                            //PurchLine1.SETFILTER(PurchLine1."Qty. to Receive",'<>%1',0);
                            //IF PurchLine1.FINDFIRST THEN BEGIN
                            ERROR(
                              Text50001,
                               "Vendor Invoice No.");
                            //END;
                        END;
                    END;
                END;
                //APNT-WMS1.0
            END;

            IF Ship THEN BEGIN
                PurchLine.RESET;
                PurchLine.SETRANGE("Document Type", "Document Type");
                PurchLine.SETRANGE("Document No.", "No.");
                PurchLine.SETFILTER(Quantity, '<>0');
                PurchLine.SETFILTER("Return Qty. to Ship", '<>0');
                PurchLine.SETRANGE("Return Shipment No.", '');
                Ship := PurchLine.FINDFIRST;
                WhseReceive := TempWhseRcptHeader.FINDFIRST;
                WhseShip := TempWhseShptHeader.FINDFIRST;
                InvtPickPutaway := WhseReference <> 0;
                IF Ship THEN
                    CheckTrackingSpecification(PurchLine);
                IF Ship AND NOT (WhseShip OR WhseReceive OR InvtPickPutaway) THEN
                    CheckWarehouse(PurchLine);
            END;

            IF NOT (Receive OR Invoice OR Ship) THEN
                IF NOT OnlyAssgntPosting THEN
                    ERROR(Text001);

            IF Invoice THEN BEGIN
                PurchLine.RESET;
                PurchLine.SETRANGE("Document Type", "Document Type");
                PurchLine.SETRANGE("Document No.", "No.");
                PurchLine.SETFILTER("Sales Order Line No.", '<>0');
                IF PurchLine.FINDSET THEN
                    REPEAT
                        SalesOrderLine.GET(
                          SalesOrderLine."Document Type"::Order,
                          PurchLine."Sales Order No.", PurchLine."Sales Order Line No.");
                        IF Receive AND
                           Invoice AND
                           (PurchLine."Qty. to Invoice" <> 0) AND
                           (PurchLine."Qty. to Receive" <> 0)
                        THEN
                            ERROR(Text002);
                        IF ABS(PurchLine."Quantity Received" - PurchLine."Quantity Invoiced") <
                           ABS(PurchLine."Qty. to Invoice")
                        THEN BEGIN
                            PurchLine."Qty. to Invoice" := PurchLine."Quantity Received" - PurchLine."Quantity Invoiced";
                            PurchLine."Qty. to Invoice (Base)" := PurchLine."Qty. Received (Base)" - PurchLine."Qty. Invoiced (Base)";
                        END;
                        IF ABS(PurchLine.Quantity - (PurchLine."Qty. to Invoice" + PurchLine."Quantity Invoiced")) <
                           ABS(SalesOrderLine.Quantity - SalesOrderLine."Quantity Invoiced")
                        THEN
                            ERROR(
                              Text003 +
                              Text004,
                              PurchLine."Sales Order No.");
                    UNTIL PurchLine.NEXT = 0;
            END;

            IF Invoice THEN BEGIN
                IF NOT ("Document Type" IN ["Document Type"::"Return Order", "Document Type"::"Credit Memo"]) THEN
                    TESTFIELD("Due Date");
                IF GUIALLOWED THEN
                    Window.OPEN(
                      '#1#################################\\' +
                      Text005 +
                      Text006 +
                      Text007 +
                      Text008)
            END ELSE
                IF GUIALLOWED THEN
                    Window.OPEN(
                      '#1############################\\' +
                      Text009);

            IF GUIALLOWED THEN
                Window.UPDATE(1, STRSUBSTNO('%1 %2', "Document Type", "No."));

            //LS  GetGLSetup;
            PurchSetup.GET;
            GetCurrency;

            IF Invoice AND PurchSetup."Ext. Doc. No. Mandatory" THEN
                IF "Document Type" IN ["Document Type"::Order, "Document Type"::Invoice] THEN
                    TESTFIELD("Vendor Invoice No.")
                ELSE
                    TESTFIELD("Vendor Cr. Memo No.");

            IF Receive AND ("Receiving No." = '') THEN
                IF ("Document Type" = "Document Type"::Order) OR
                   (("Document Type" = "Document Type"::Invoice) AND PurchSetup."Receipt on Invoice")
                THEN BEGIN
                    TESTFIELD("Receiving No. Series");
                    "Receiving No." := NoSeriesMgt.GetNextNo("Receiving No. Series", "Posting Date", TRUE);
                    ModifyHeader := TRUE;
                END;

            IF Ship AND ("Return Shipment No." = '') THEN
                IF ("Document Type" = "Document Type"::"Return Order") OR
                   (("Document Type" = "Document Type"::"Credit Memo") AND PurchSetup."Return Shipment on Credit Memo")
                THEN BEGIN
                    TESTFIELD("Return Shipment No. Series");
                    "Return Shipment No." := NoSeriesMgt.GetNextNo("Return Shipment No. Series", "Posting Date", TRUE);
                    ModifyHeader := TRUE;
                END;

            IF Invoice AND ("Posting No." = '') THEN BEGIN
                IF ("No. Series" <> '') OR
                   ("Document Type" IN ["Document Type"::Order, "Document Type"::"Return Order"])
                THEN
                    TESTFIELD("Posting No. Series");
                IF ("No. Series" <> "Posting No. Series") OR
                   ("Document Type" IN ["Document Type"::Order, "Document Type"::"Return Order"])
                THEN BEGIN
                    "Posting No." := NoSeriesMgt.GetNextNo("Posting No. Series", "Posting Date", TRUE);
                    ModifyHeader := TRUE;
                END;
            END;

            IF NOT ItemChargeAssgntOnly THEN BEGIN
                PurchLine.RESET;
                PurchLine.SETRANGE("Document Type", "Document Type");
                PurchLine.SETRANGE("Document No.", "No.");
                PurchLine.SETFILTER("Sales Order Line No.", '<>0');
                IF PurchLine.FINDSET THEN BEGIN
                    DropShipOrder := TRUE;
                    IF Receive THEN
                        REPEAT
                            IF SalesOrderHeader."No." <> PurchLine."Sales Order No." THEN BEGIN
                                SalesOrderHeader.GET(
                                  SalesOrderHeader."Document Type"::Order,
                                  PurchLine."Sales Order No.");
                                SalesOrderHeader.TESTFIELD("Bill-to Customer No.");
                                IF SalesOrderHeader."Shipping No." = '' THEN BEGIN
                                    SalesOrderHeader.TESTFIELD("Shipping No. Series");
                                    SalesOrderHeader."Shipping No." :=
                                      NoSeriesMgt.GetNextNo(SalesOrderHeader."Shipping No. Series", "Posting Date", TRUE);
                                    IF NOT RECORDLEVELLOCKING THEN
                                        LOCKTABLE(TRUE, TRUE);
                                    SalesOrderHeader.MODIFY;
                                    ModifyHeader := TRUE;
                                END;
                            END;
                        UNTIL PurchLine.NEXT = 0;
                END;
            END;
            IF ModifyHeader THEN BEGIN
                MODIFY;
                COMMIT;
            END;

            IF PurchSetup."Calc. Inv. Discount" AND
               (Status <> Status::Open) AND
               NOT ItemChargeAssgntOnly
            THEN BEGIN
                PurchLine.RESET;
                PurchLine.SETRANGE("Document Type", "Document Type");
                PurchLine.SETRANGE("Document No.", "No.");
                PurchLine.FINDFIRST;
                TempInvoice := Invoice;
                TempRcpt := Receive;
                TempReturn := Ship;
                PurchCalcDisc.RUN(PurchLine);
                GET("Document Type", "No.");
                Invoice := TempInvoice;
                Receive := TempRcpt;
                Ship := TempReturn;
                COMMIT;
            END;

            IF Receive OR Ship THEN
                ArchiveUnpostedOrder; // has a COMMIT;

            IF (Status = Status::Open) OR (Status = Status::"Pending Prepayment") THEN BEGIN
                TempInvoice := Invoice;
                TempRcpt := Receive;
                TempReturn := Ship;
                CODEUNIT.RUN(CODEUNIT::"Release Purchase Document", PurchHeader);
                Status := Status::Open;
                Invoice := TempInvoice;
                Receive := TempRcpt;
                Ship := TempReturn;
                MODIFY;
                COMMIT;
                Status := Status::Released;
            END;
            IF (PurchHeader."Buy-from IC Partner Code" <> '') AND (ICPartner.GET(PurchHeader."Buy-from IC Partner Code")) THEN
                ICPartner.TESTFIELD(Blocked, FALSE);
            IF (PurchHeader."Pay-to IC Partner Code" <> '') AND (ICPartner.GET(PurchHeader."Pay-to IC Partner Code")) THEN
                ICPartner.TESTFIELD(Blocked, FALSE);
            IF "Send IC Document" AND ("IC Status" = "IC Status"::New) AND ("IC Direction" = "IC Direction"::Outgoing) AND
               ("Document Type" IN ["Document Type"::Order, "Document Type"::"Return Order"])
            THEN BEGIN
                //APNT-IC1.0
                /*
                ICInOutBoxMgt.SendPurchDoc(Rec,TRUE);
                "IC Status" := "IC Status"::Pending;
                ModifyHeader := TRUE;
                */
                CLEAR(ICTransactionNo);
                IF ICPartner."Auto Post Outbox Transactions" THEN BEGIN
                    CLEAR(ICOutboxExport);
                    ICDirection := ICDirection::Outgoing;
                    ICTransactionNo := ICInOutBoxMgt.SendandPostPurchDoc(Rec, TRUE);
                    ICOutboxExport.AutoPostICOutbocTransaction(ICTransactionNo);
                    "IC Status" := "IC Status"::Sent;
                    ModifyHeader := TRUE;
                END ELSE BEGIN
                    ICDirection := ICDirection::Outgoing;
                    ICTransactionNo := ICInOutBoxMgt.SendandPostPurchDoc(Rec, TRUE);
                    "IC Status" := "IC Status"::Pending;
                    ModifyHeader := TRUE;
                END;
                //APNT-IC1.0
            END;
            IF "IC Direction" = "IC Direction"::Incoming THEN BEGIN
                CASE PurchHeader."Document Type" OF
                    PurchHeader."Document Type"::Invoice:
                        ICHandledInboxTransaction.SETRANGE("Document No.", PurchHeader."Vendor Invoice No.");
                    PurchHeader."Document Type"::Order:
                        ICHandledInboxTransaction.SETRANGE("Document No.", PurchHeader."Vendor Order No.");
                    PurchHeader."Document Type"::"Credit Memo":
                        ICHandledInboxTransaction.SETRANGE("Document No.", PurchHeader."Vendor Cr. Memo No.");
                    PurchHeader."Document Type"::"Return Order":
                        ICHandledInboxTransaction.SETRANGE("Document No.", PurchHeader."Vendor Order No.");
                END;
                Vendor.GET(PurchHeader."Buy-from Vendor No.");
                ICHandledInboxTransaction.SETRANGE("IC Partner Code", Vendor."IC Partner Code");
                ICHandledInboxTransaction.LOCKTABLE;
                IF ICHandledInboxTransaction.FINDFIRST THEN BEGIN
                    ICHandledInboxTransaction.Status := ICHandledInboxTransaction.Status::Posted;
                    ICHandledInboxTransaction.MODIFY;
                END;
            END;

            IF RECORDLEVELLOCKING THEN BEGIN
                DocDim.LOCKTABLE;
                PurchLine.LOCKTABLE;
                SalesOrderLine.LOCKTABLE;
                GLEntry.LOCKTABLE;
                IF GLEntry.FINDLAST THEN;
            END;

            SourceCodeSetup.GET;
            SrcCode := SourceCodeSetup.Purchases;

            //LS -
            IF BOUtils.IsInStorePermitted() THEN
                CASE PurchHeader."Document Type" OF
                    PurchHeader."Document Type"::Order:
                        InStoreMgt.SendPurchaseDocReceive(PurchHeader);
                    PurchHeader."Document Type"::"Return Order":
                        InStoreMgt.SendPurchaseDocShip(PurchHeader);
                END;
            //LS +

            //DP6.01.01 START
            WorkOrderLine.RESET;
            WorkOrderLine.SETRANGE("Converted Purch. Doc No.", "No.");
            IF WorkOrderLine.FINDFIRST THEN BEGIN
                PremiseMgmtSetup.GET;
                SrcCode := PremiseMgmtSetup."Default Source Code";
            END;
            //DP6.01.01 STOP

            // Insert receipt header
            IF Receive THEN BEGIN
                IF ("Document Type" = "Document Type"::Order) OR
                   (("Document Type" = "Document Type"::Invoice) AND PurchSetup."Receipt on Invoice")
                THEN BEGIN
                    IF DropShipOrder THEN BEGIN
                        PurchRcptHeader.LOCKTABLE;
                        PurchRcptLine.LOCKTABLE;
                        SalesShptHeader.LOCKTABLE;
                        SalesShptLine.LOCKTABLE;
                    END;
                    PurchRcptHeader.INIT;
                    PurchRcptHeader.TRANSFERFIELDS(PurchHeader);
                    PurchRcptHeader."No." := "Receiving No.";
                    //IF "Document Type" = "Document Type"::Order THEN BEGIN  //APNT-CO1.0
                    PurchRcptHeader."Order No. Series" := "No. Series";
                    PurchRcptHeader."Order No." := "No.";
                    //END; //APNT-CO1.0
                    //APNT-CO1.0
                    CALCFIELDS("Total Landed Cost (LCY)");
                    PurchRcptHeader."Total Landed Cost (LCY)" := "Total Landed Cost (LCY)";
                    PurchRcptHeader."Cost Factor" := "Cost Factor";
                    //APNT-CO1.0

                    PurchRcptHeader."No. Printed" := 0;
                    PurchRcptHeader."Source Code" := SrcCode;
                    PurchRcptHeader."User ID" := USERID;
                    //APNT-WMS1.0
                    PurchRcptHeader."Vendor Invoice No." := PurchHeader."Vendor Invoice No.";
                    //APNT-WMS1.0
                    PurchRcptHeader.INSERT;
                    //APNT-T009914
                    CreateBinLedgerEntries(Rec, PurchRcptHeader);
                    //APNT-T009914

                    //LS -
                    IF PurchHeader."Only Two Dimensions" THEN BEGIN
                        TempDocDim.SETRANGE(TempDocDim."Table ID", DATABASE::"Purchase Header");
                        TempDocDim.SETRANGE(TempDocDim."Line No.", 0);
                        DimMgt.MoveDocDimToPostedDocDim(TempDocDim, DATABASE::"Purch. Rcpt. Header", PurchRcptHeader."No.");
                    END ELSE BEGIN
                        DimMgt.MoveOneDocDimToPostedDocDim(
                          TempDocDim, DATABASE::"Purchase Header", "Document Type", "No.", 0,
                          DATABASE::"Purch. Rcpt. Header", PurchRcptHeader."No.");
                    END;
                    //LS +

                    ApprovalMgt.MoveApprvalEntryToPosted(TempApprovalEntry, DATABASE::"Purch. Rcpt. Header", PurchRcptHeader."No.");

                    IF PurchSetup."Copy Comments Order to Receipt" THEN BEGIN
                        CopyCommentLines(
                          "Document Type", PurchCommentLine."Document Type"::Receipt,
                          "No.", PurchRcptHeader."No.");
                        PurchRcptHeader.COPYLINKS(Rec);
                    END;
                    IF WhseReceive THEN BEGIN
                        WhseRcptHeader.GET(TempWhseRcptHeader."No.");
                        WhsePostRcpt.CreatePostedRcptHeader(PostedWhseRcptHeader, WhseRcptHeader, "Receiving No.", "Posting Date");
                    END;
                    IF WhseShip THEN BEGIN
                        WhseShptHeader.GET(TempWhseShptHeader."No.");
                        WhsePostShpt.CreatePostedShptHeader(PostedWhseShptHeader, WhseShptHeader, "Receiving No.", "Posting Date");
                    END;
                END;
                IF SalesHeader.GET("Document Type", PurchLine."Sales Order No.") THEN
                    ServItemMgt.CopyReservationEntry(SalesHeader);
            END;
            // Insert return shipment header
            IF Ship THEN
                IF ("Document Type" = "Document Type"::"Return Order") OR
                   (("Document Type" = "Document Type"::"Credit Memo") AND PurchSetup."Return Shipment on Credit Memo")
                THEN BEGIN
                    ReturnShptHeader.INIT;
                    ReturnShptHeader.TRANSFERFIELDS(PurchHeader);
                    ReturnShptHeader."No." := "Return Shipment No.";
                    IF "Document Type" = "Document Type"::"Return Order" THEN BEGIN
                        ReturnShptHeader."Return Order No. Series" := "No. Series";
                        ReturnShptHeader."Return Order No." := "No.";
                    END;
                    ReturnShptHeader."No. Series" := "Return Shipment No. Series";
                    ReturnShptHeader."No. Printed" := 0;
                    ReturnShptHeader."Source Code" := SrcCode;
                    ReturnShptHeader."User ID" := USERID;
                    ReturnShptHeader.INSERT;
                    //LS -
                    IF PurchHeader."Only Two Dimensions" THEN BEGIN
                        TempDocDim.SETRANGE(TempDocDim."Table ID", DATABASE::"Purchase Header");
                        TempDocDim.SETRANGE(TempDocDim."Line No.", 0);
                        DimMgt.MoveDocDimToPostedDocDim(TempDocDim, DATABASE::"Return Shipment Header", ReturnShptHeader."No.");
                    END ELSE BEGIN
                        DimMgt.MoveOneDocDimToPostedDocDim(
                          TempDocDim, DATABASE::"Purchase Header", "Document Type", "No.", 0,
                          DATABASE::"Return Shipment Header", ReturnShptHeader."No.");
                    END;
                    //LS +

                    ApprovalMgt.MoveApprvalEntryToPosted(TempApprovalEntry, DATABASE::"Return Shipment Header", ReturnShptHeader."No.");

                    IF PurchSetup."Copy Cmts Ret.Ord. to Ret.Shpt" THEN BEGIN
                        CopyCommentLines(
                          "Document Type", PurchCommentLine."Document Type"::"Posted Return Shipment",
                          "No.", ReturnShptHeader."No.");
                        ReturnShptHeader.COPYLINKS(Rec);
                    END;
                    IF WhseShip THEN BEGIN
                        WhseShptHeader.GET(TempWhseShptHeader."No.");
                        WhsePostShpt.CreatePostedShptHeader(PostedWhseShptHeader, WhseShptHeader, "Return Shipment No.", "Posting Date");
                    END;
                    IF WhseReceive THEN BEGIN
                        WhseRcptHeader.GET(TempWhseRcptHeader."No.");
                        WhsePostRcpt.CreatePostedRcptHeader(PostedWhseRcptHeader, WhseRcptHeader, "Return Shipment No.", "Posting Date");
                    END;
                END;

            // Insert invoice header or credit memo header
            IF Invoice THEN
                IF "Document Type" IN ["Document Type"::Order, "Document Type"::Invoice] THEN BEGIN
                    PurchInvHeader.INIT;
                    PurchInvHeader.TRANSFERFIELDS(PurchHeader);
                    IF "Document Type" = "Document Type"::Order THEN BEGIN
                        PurchInvHeader."Pre-Assigned No. Series" := '';
                        PurchInvHeader."No." := "Posting No.";
                        PurchInvHeader."Order No. Series" := "No. Series";
                        PurchInvHeader."Order No." := "No.";
                        //APNT-CO1.0
                        CALCFIELDS("Total Landed Cost (LCY)");
                        PurchInvHeader."Total Landed Cost (LCY)" := "Total Landed Cost (LCY)";
                        PurchInvHeader."Cost Factor" := "Cost Factor";
                        //APNT-CO1.0
                        IF GUIALLOWED THEN
                            Window.UPDATE(1, STRSUBSTNO(Text010, "Document Type", "No.", PurchInvHeader."No."));
                    END ELSE BEGIN
                        IF "Posting No." <> '' THEN BEGIN
                            PurchInvHeader."No." := "Posting No.";
                            IF GUIALLOWED THEN
                                Window.UPDATE(1, STRSUBSTNO(Text010, "Document Type", "No.", PurchInvHeader."No."));
                        END;
                        PurchInvHeader."Pre-Assigned No. Series" := "No. Series";
                        PurchInvHeader."Pre-Assigned No." := "No.";
                    END;
                    PurchInvHeader."Source Code" := SrcCode;
                    PurchInvHeader."User ID" := USERID;
                    PurchInvHeader."No. Printed" := 0;
                    PurchInvHeader.INSERT;
                    //LS -
                    IF PurchHeader."Only Two Dimensions" THEN BEGIN
                        TempDocDim.SETRANGE(TempDocDim."Table ID", DATABASE::"Purchase Header");
                        TempDocDim.SETRANGE(TempDocDim."Line No.", 0);
                        DimMgt.MoveDocDimToPostedDocDim(TempDocDim, DATABASE::"Purch. Inv. Header", PurchInvHeader."No.");
                    END ELSE BEGIN
                        DimMgt.MoveOneDocDimToPostedDocDim(
                          TempDocDim, DATABASE::"Purchase Header", "Document Type", "No.", 0,
                          DATABASE::"Purch. Inv. Header", PurchInvHeader."No.");
                    END;
                    //LS +

                    ApprovalMgt.MoveApprvalEntryToPosted(TempApprovalEntry, DATABASE::"Purch. Inv. Header", PurchInvHeader."No.");

                    IF PurchSetup."Copy Comments Order to Invoice" THEN BEGIN
                        CopyCommentLines(
                          "Document Type", PurchCommentLine."Document Type"::"Posted Invoice",
                          "No.", PurchInvHeader."No.");
                        PurchInvHeader.COPYLINKS(Rec);
                    END;
                    GenJnlLineDocType := GenJnlLine."Document Type"::Invoice;
                    GenJnlLineDocNo := PurchInvHeader."No.";
                    GenJnlLineExtDocNo := "Vendor Invoice No.";
                END ELSE BEGIN // Credit Memo
                    PurchCrMemoHeader.INIT;
                    PurchCrMemoHeader.TRANSFERFIELDS(PurchHeader);
                    IF "Document Type" = "Document Type"::"Return Order" THEN BEGIN
                        PurchCrMemoHeader."No." := "Posting No.";
                        PurchCrMemoHeader."Pre-Assigned No. Series" := '';
                        PurchCrMemoHeader."Return Order No. Series" := "No. Series";
                        PurchCrMemoHeader."Return Order No." := "No.";
                        //APNT-CO1.0
                        CALCFIELDS("Total Landed Cost (LCY)");
                        PurchCrMemoHeader."Total Landed Cost (LCY)" := "Total Landed Cost (LCY)";
                        PurchCrMemoHeader."Cost Factor" := "Cost Factor";
                        //APNT-CO1.0
                        IF GUIALLOWED THEN
                            Window.UPDATE(1, STRSUBSTNO(Text011, "Document Type", "No.", PurchCrMemoHeader."No."));
                    END ELSE BEGIN
                        PurchCrMemoHeader."Pre-Assigned No. Series" := "No. Series";
                        PurchCrMemoHeader."Pre-Assigned No." := "No.";
                        IF "Posting No." <> '' THEN BEGIN
                            PurchCrMemoHeader."No." := "Posting No.";
                            IF GUIALLOWED THEN
                                Window.UPDATE(1, STRSUBSTNO(Text011, "Document Type", "No.", PurchCrMemoHeader."No."));
                        END;
                    END;
                    PurchCrMemoHeader."Source Code" := SrcCode;
                    PurchCrMemoHeader."User ID" := USERID;
                    PurchCrMemoHeader."No. Printed" := 0;
                    PurchCrMemoHeader.INSERT(TRUE);
                    //LS -
                    IF PurchHeader."Only Two Dimensions" THEN BEGIN
                        TempDocDim.SETRANGE(TempDocDim."Table ID", DATABASE::"Purchase Header");
                        TempDocDim.SETRANGE(TempDocDim."Line No.", 0);
                        DimMgt.MoveDocDimToPostedDocDim(TempDocDim, DATABASE::"Purch. Cr. Memo Hdr.", PurchCrMemoHeader."No.");
                    END ELSE BEGIN
                        DimMgt.MoveOneDocDimToPostedDocDim(
                          TempDocDim, DATABASE::"Purchase Header", "Document Type", "No.", 0,
                          DATABASE::"Purch. Cr. Memo Hdr.", PurchCrMemoHeader."No.");
                    END;
                    //LS +

                    ApprovalMgt.MoveApprvalEntryToPosted(TempApprovalEntry, DATABASE::"Purch. Cr. Memo Hdr.", PurchCrMemoHeader."No.");

                    IF PurchSetup."Copy Cmts Ret.Ord. to Cr. Memo" THEN BEGIN
                        CopyCommentLines(
                          "Document Type", PurchCommentLine."Document Type"::"Posted Credit Memo",
                          "No.", PurchCrMemoHeader."No.");
                        PurchCrMemoHeader.COPYLINKS(Rec);
                    END;
                    GenJnlLineDocType := GenJnlLine."Document Type"::"Credit Memo";
                    GenJnlLineDocNo := PurchCrMemoHeader."No.";
                    GenJnlLineExtDocNo := "Vendor Cr. Memo No.";
                END;

            //T029871 <<
            HHTTransactions.RESET;
            HHTTransactions.SETRANGE("Transaction No.", "No.");
            IF "Document Type" = "Document Type"::Order THEN
                HHTTransactions.SETRANGE("Transaction Type", 'PI')
            ELSE
                IF "Document Type" = "Document Type"::"Credit Memo" THEN
                    HHTTransactions.SETRANGE("Transaction Type", 'PR')
                ELSE
                    IF "Document Type" = "Document Type"::"Return Order" THEN
                        HHTTransactions.SETRANGE("Transaction Type", 'PR');
            IF HHTTransactions.FINDFIRST THEN
                REPEAT
                    HHTTransactions.Closed := TRUE;
                    HHTTransactions."Closed By" := USERID;
                    HHTTransactions."Closed Date" := TODAY;
                    HHTTransactions."Closed Time" := TIME;
                    HHTTransactions.MODIFY;
                UNTIL HHTTransactions.NEXT = 0;

            HHTTransHdr.RESET;
            HHTTransHdr.SETRANGE("Transaction No.", "No.");
            IF "Document Type" = "Document Type"::Order THEN
                HHTTransHdr.SETRANGE("Transaction Type", 'PI')
            ELSE
                IF "Document Type" = "Document Type"::"Credit Memo" THEN
                    HHTTransHdr.SETRANGE("Transaction Type", 'PR')
                ELSE
                    IF "Document Type" = "Document Type"::"Return Order" THEN
                        HHTTransHdr.SETRANGE("Transaction Type", 'PR');
            IF HHTTransHdr.FINDFIRST THEN BEGIN
                HHTTransHdr.Closed := TRUE;
                HHTTransHdr."Closed By" := USERID;
                HHTTransHdr."Closed Date" := TODAY;
                HHTTransHdr."Closed Time" := TIME;
                HHTTransHdr.MODIFY;
            END;
            //T029871 >>

            // Lines
            InvPostingBuffer[1].DELETEALL;
            DropShptPostBuffer.DELETEALL;
            EverythingInvoiced := TRUE;

            PurchLine.RESET;
            PurchLine.SETRANGE("Document Type", "Document Type");
            PurchLine.SETRANGE("Document No.", "No.");
            LineCount := 0;
            RoundingLineInserted := FALSE;
            MergePurchLines(PurchHeader, PurchLine, TempPrepmtPurchLine, CombinedPurchLineTemp);

            TempVATAmountLineRemainder.DELETEALL;
            PurchLine.CalcVATAmountLines(1, PurchHeader, CombinedPurchLineTemp, TempVATAmountLine);

            IF PurchLine.FINDSET THEN
                REPEAT
                    JobPurchLine := PurchLine;
                    ItemJnlRollRndg := FALSE;
                    LineCount := LineCount + 1;
                    IF GUIALLOWED THEN
                        Window.UPDATE(2, LineCount);
                    IF Invoice THEN
                        TestPrepmtAmount;
                    IF PurchLine.Type = PurchLine.Type::"Charge (Item)" THEN BEGIN
                        PurchLine.TESTFIELD(Amount);
                        PurchLine.TESTFIELD("Job No.", '');
                    END;
                    IF PurchLine.Type = PurchLine.Type::Item THEN
                        CostBaseAmount := PurchLine."Line Amount";
                    IF PurchLine."Qty. per Unit of Measure" = 0 THEN
                        PurchLine."Qty. per Unit of Measure" := 1;
                    IF PurchLine.Type = PurchLine.Type::"Fixed Asset" THEN BEGIN
                        PurchLine.TESTFIELD("Job No.", '');
                        PurchLine.TESTFIELD("Depreciation Book Code");
                        PurchLine.TESTFIELD("FA Posting Type");
                        FA.GET(PurchLine."No.");
                        DeprBook.GET(PurchLine."Depreciation Book Code");
                        FA.TESTFIELD("Budgeted Asset", FALSE);
                        IF PurchLine."Budgeted FA No." <> '' THEN BEGIN
                            FA.GET(PurchLine."Budgeted FA No.");
                            FA.TESTFIELD("Budgeted Asset", TRUE);
                        END;
                        IF PurchLine."FA Posting Type" = PurchLine."FA Posting Type"::Maintenance THEN BEGIN
                            PurchLine.TESTFIELD("Insurance No.", '');
                            PurchLine.TESTFIELD("Depr. until FA Posting Date", FALSE);
                            PurchLine.TESTFIELD("Depr. Acquisition Cost", FALSE);
                            DeprBook.TESTFIELD("G/L Integration - Maintenance", TRUE);
                        END;
                        IF PurchLine."FA Posting Type" = PurchLine."FA Posting Type"::"Acquisition Cost" THEN BEGIN
                            PurchLine.TESTFIELD("Maintenance Code", '');
                            DeprBook.TESTFIELD("G/L Integration - Acq. Cost", TRUE);
                        END;
                        IF PurchLine."Insurance No." <> '' THEN BEGIN
                            FASetup.GET;
                            FASetup.TESTFIELD("Insurance Depr. Book", PurchLine."Depreciation Book Code");
                        END;
                    END ELSE BEGIN
                        PurchLine.TESTFIELD("Depreciation Book Code", '');
                        PurchLine.TESTFIELD("FA Posting Type", 0);
                        PurchLine.TESTFIELD("Maintenance Code", '');
                        PurchLine.TESTFIELD("Insurance No.", '');
                        PurchLine.TESTFIELD("Depr. until FA Posting Date", FALSE);
                        PurchLine.TESTFIELD("Depr. Acquisition Cost", FALSE);
                        PurchLine.TESTFIELD("Budgeted FA No.", '');
                        PurchLine.TESTFIELD("FA Posting Date", 0D);
                        PurchLine.TESTFIELD("Salvage Value", 0);
                        PurchLine.TESTFIELD("Duplicate in Depreciation Book", '');
                        PurchLine.TESTFIELD("Use Duplication List", FALSE);
                    END;

                    CASE "Document Type" OF
                        "Document Type"::Order:
                            PurchLine.TESTFIELD("Return Qty. to Ship", 0);
                        "Document Type"::Invoice:
                            BEGIN
                                IF PurchLine."Receipt No." = '' THEN
                                    PurchLine.TESTFIELD("Qty. to Receive", PurchLine.Quantity);
                                PurchLine.TESTFIELD("Return Qty. to Ship", 0);
                                PurchLine.TESTFIELD("Qty. to Invoice", PurchLine.Quantity);
                            END;
                        "Document Type"::"Return Order":
                            PurchLine.TESTFIELD("Qty. to Receive", 0);
                        "Document Type"::"Credit Memo":
                            BEGIN
                                IF PurchLine."Return Shipment No." = '' THEN
                                    PurchLine.TESTFIELD("Return Qty. to Ship", PurchLine.Quantity);
                                PurchLine.TESTFIELD("Qty. to Receive", 0);
                                PurchLine.TESTFIELD("Qty. to Invoice", PurchLine.Quantity);
                            END;
                    END;

                    IF NOT (Receive OR RoundingLineInserted) THEN BEGIN
                        PurchLine."Qty. to Receive" := 0;
                        PurchLine."Qty. to Receive (Base)" := 0;
                    END;

                    IF NOT (Ship OR RoundingLineInserted) THEN BEGIN
                        PurchLine."Return Qty. to Ship" := 0;
                        PurchLine."Return Qty. to Ship (Base)" := 0;
                    END;

                    IF ("Document Type" = "Document Type"::Invoice) AND (PurchLine."Receipt No." <> '') THEN BEGIN
                        PurchLine."Quantity Received" := PurchLine.Quantity;
                        PurchLine."Qty. Received (Base)" := PurchLine."Quantity (Base)";
                        PurchLine."Qty. to Receive" := 0;
                        PurchLine."Qty. to Receive (Base)" := 0;
                    END;

                    IF ("Document Type" = "Document Type"::"Credit Memo") AND (PurchLine."Return Shipment No." <> '')
                    THEN BEGIN
                        PurchLine."Return Qty. Shipped" := PurchLine.Quantity;
                        PurchLine."Return Qty. Shipped (Base)" := PurchLine."Quantity (Base)";
                        PurchLine."Return Qty. to Ship" := 0;
                        PurchLine."Return Qty. to Ship (Base)" := 0;
                    END;

                    IF Invoice THEN BEGIN
                        IF ABS(PurchLine."Qty. to Invoice") > ABS(PurchLine.MaxQtyToInvoice) THEN
                            PurchLine.InitQtyToInvoice;
                    END ELSE BEGIN
                        PurchLine."Qty. to Invoice" := 0;
                        PurchLine."Qty. to Invoice (Base)" := 0;
                    END;

                    IF PurchLine."Qty. to Invoice" + PurchLine."Quantity Invoiced" <> PurchLine.Quantity THEN
                        EverythingInvoiced := FALSE;

                    IF PurchLine.Quantity <> 0 THEN BEGIN
                        PurchLine.TESTFIELD("No.");
                        PurchLine.TESTFIELD(Type);
                        PurchLine.TESTFIELD("Gen. Bus. Posting Group");
                        PurchLine.TESTFIELD("Gen. Prod. Posting Group");
                        DivideAmount(1, PurchLine."Qty. to Invoice");
                    END ELSE
                        PurchLine.TESTFIELD(Amount, 0);

                    RoundAmount(PurchLine."Qty. to Invoice");

                    IF "Document Type" IN ["Document Type"::"Return Order", "Document Type"::"Credit Memo"] THEN BEGIN
                        ReverseAmount(PurchLine);
                        ReverseAmount(PurchLineACY);
                    END;

                    RemQtyToBeInvoiced := PurchLine."Qty. to Invoice";
                    RemQtyToBeInvoicedBase := PurchLine."Qty. to Invoice (Base)";

                    // Job Credit Memo Item Qty Check
                    IF "Document Type" IN ["Document Type"::"Return Order", "Document Type"::"Credit Memo"] THEN
                        IF (PurchLine."Job No." <> '') AND (PurchLine.Type = PurchLine.Type::Item) THEN
                            JobPostLine.CheckItemQuantityPurchCredit(Rec, PurchLine);

                    // Item Tracking:
                    IF NOT PurchLine."Prepayment Line" THEN BEGIN
                        IF Invoice THEN
                            IF PurchLine."Qty. to Invoice" = 0 THEN
                                TrackingSpecificationExists := FALSE
                            ELSE
                                TrackingSpecificationExists :=
                                  ReservePurchLine.RetrieveInvoiceSpecification(PurchLine, TempInvoicingSpecification);
                        EndLoop := FALSE;

                        IF "Document Type" IN ["Document Type"::"Return Order", "Document Type"::"Credit Memo"] THEN BEGIN
                            IF ABS(RemQtyToBeInvoiced) > ABS(PurchLine."Return Qty. to Ship") THEN BEGIN
                                ReturnShptLine.RESET;
                                CASE "Document Type" OF
                                    "Document Type"::"Return Order":
                                        BEGIN
                                            ReturnShptLine.SETCURRENTKEY("Return Order No.", "Return Order Line No.");
                                            ReturnShptLine.SETRANGE("Return Order No.", PurchLine."Document No.");
                                            ReturnShptLine.SETRANGE("Return Order Line No.", PurchLine."Line No.");
                                        END;
                                    "Document Type"::"Credit Memo":
                                        BEGIN
                                            ReturnShptLine.SETRANGE("Document No.", PurchLine."Return Shipment No.");
                                            ReturnShptLine.SETRANGE("Line No.", PurchLine."Return Shipment Line No.");
                                        END;
                                END;

                                //LS -
                                IF (NOT ReturnShptLine.FIND('-')) AND (PurchLine.Type = PurchLine.Type::Item) THEN BEGIN
                                    xICTHeader.RESET();
                                    xICTHeader.SETCURRENTKEY("Dist. Location To", "ICT Source Doc. Type", "ICT Source Doc. No.", "ICT Source Line No.");
                                    xICTHeader.SETRANGE("Dist. Location To", LSRetailSetup."Distribution Location");
                                    xICTHeader.SETRANGE("ICT Source Doc. Type", PurchHeader."Document Type");
                                    xICTHeader.SETRANGE("ICT Source Doc. No.", PurchHeader."No.");
                                    xICTHeader.SETRANGE("ICT Source Line No.", PurchLine."Line No.");
                                    IF xICTHeader.FIND('-') THEN
                                        REPEAT
                                            xItemLedgerEntry.GET(xICTHeader."Destination ItemLedgerEntryNo");
                                            QtyToBeInvoicedBase := xItemLedgerEntry.Quantity;
                                            QtyToBeInvoiced := QtyToBeInvoicedBase / xItemLedgerEntry."Qty. per Unit of Measure";
                                            PostItemJnlLine(
                                              PurchLine,
                                              0, 0,
                                              QtyToBeInvoiced, QtyToBeInvoicedBase,
                                              xICTHeader."Destination ItemLedgerEntryNo", '', DummyTrackingSpecification);
                                            RemQtyToBeInvoiced := RemQtyToBeInvoiced - QtyToBeInvoiced;
                                            RemQtyToBeInvoicedBase := RemQtyToBeInvoicedBase - QtyToBeInvoicedBase;
                                        UNTIL xICTHeader.NEXT() = 0
                                    ELSE
                                        ERROR(
                                          Text029,
                                          PurchLine."Return Shipment Line No.", PurchLine."Return Shipment No.");
                                END ELSE BEGIN
                                    //LS +
                                    ReturnShptLine.SETFILTER("Return Qty. Shipped Not Invd.", '<>0');
                                    IF ReturnShptLine.FINDSET(TRUE, FALSE) THEN BEGIN
                                        ItemJnlRollRndg := TRUE;
                                        REPEAT
                                            IF TrackingSpecificationExists THEN BEGIN  // Item Tracking
                                                ItemEntryRelation.GET(TempInvoicingSpecification."Appl.-to Item Entry");
                                                ReturnShptLine.GET(ItemEntryRelation."Source ID", ItemEntryRelation."Source Ref. No.");
                                            END ELSE
                                                ItemEntryRelation."Item Entry No." := ReturnShptLine."Item Shpt. Entry No.";
                                            ReturnShptLine.TESTFIELD("Buy-from Vendor No.", PurchLine."Buy-from Vendor No.");
                                            ReturnShptLine.TESTFIELD(Type, PurchLine.Type);
                                            ReturnShptLine.TESTFIELD("No.", PurchLine."No.");
                                            ReturnShptLine.TESTFIELD("Gen. Bus. Posting Group", PurchLine."Gen. Bus. Posting Group");
                                            ReturnShptLine.TESTFIELD("Gen. Prod. Posting Group", PurchLine."Gen. Prod. Posting Group");
                                            ReturnShptLine.TESTFIELD("Job No.", PurchLine."Job No.");
                                            ReturnShptLine.TESTFIELD("Unit of Measure Code", PurchLine."Unit of Measure Code");
                                            ReturnShptLine.TESTFIELD("Variant Code", PurchLine."Variant Code");
                                            ReturnShptLine.TESTFIELD("Prod. Order No.", PurchLine."Prod. Order No.");
                                            IF PurchLine."Qty. to Invoice" * ReturnShptLine.Quantity > 0 THEN
                                                PurchLine.FIELDERROR("Qty. to Invoice", Text028);
                                            IF TrackingSpecificationExists THEN BEGIN  // Item Tracking
                                                QtyToBeInvoiced := TempInvoicingSpecification."Qty. to Invoice";
                                                QtyToBeInvoicedBase := TempInvoicingSpecification."Qty. to Invoice (Base)";
                                            END ELSE BEGIN
                                                QtyToBeInvoiced := RemQtyToBeInvoiced - PurchLine."Return Qty. to Ship";
                                                QtyToBeInvoicedBase := RemQtyToBeInvoicedBase - PurchLine."Return Qty. to Ship (Base)";
                                            END;
                                            IF ABS(QtyToBeInvoiced) >
                                               ABS(ReturnShptLine.Quantity - ReturnShptLine."Quantity Invoiced")
                                            THEN BEGIN
                                                QtyToBeInvoiced := ReturnShptLine."Quantity Invoiced" - ReturnShptLine.Quantity;
                                                QtyToBeInvoicedBase := ReturnShptLine."Qty. Invoiced (Base)" - ReturnShptLine."Quantity (Base)";
                                            END;

                                            IF TrackingSpecificationExists THEN
                                                ItemTrackingMgt.AdjustQuantityRounding(
                                                  RemQtyToBeInvoiced, QtyToBeInvoiced,
                                                  RemQtyToBeInvoicedBase, QtyToBeInvoicedBase);

                                            RemQtyToBeInvoiced := RemQtyToBeInvoiced - QtyToBeInvoiced;
                                            RemQtyToBeInvoicedBase := RemQtyToBeInvoicedBase - QtyToBeInvoicedBase;
                                            ReturnShptLine."Quantity Invoiced" :=
                                              ReturnShptLine."Quantity Invoiced" - QtyToBeInvoiced;
                                            ReturnShptLine."Qty. Invoiced (Base)" :=
                                              ReturnShptLine."Qty. Invoiced (Base)" - QtyToBeInvoicedBase;
                                            ReturnShptLine."Return Qty. Shipped Not Invd." :=
                                              ReturnShptLine.Quantity - ReturnShptLine."Quantity Invoiced";
                                            ReturnShptLine.MODIFY;
                                            IF PurchLine.Type = PurchLine.Type::Item THEN
                                                PostItemJnlLine(
                                                  PurchLine,
                                                  0, 0,
                                                  QtyToBeInvoiced, QtyToBeInvoicedBase,
                                                  /*ReturnShptLine."Item Shpt. Entry No."*/
                                                  ItemEntryRelation."Item Entry No.", '', TempInvoicingSpecification);
                                            IF TrackingSpecificationExists THEN
                                                EndLoop := (TempInvoicingSpecification.NEXT = 0)
                                            ELSE
                                                EndLoop :=
                                                  (ReturnShptLine.NEXT = 0) OR (ABS(RemQtyToBeInvoiced) <= ABS(PurchLine."Return Qty. to Ship"));
                                        UNTIL EndLoop;
                                    END ELSE
                                        ERROR(
                                          Text029,
                                          PurchLine."Return Shipment Line No.", PurchLine."Return Shipment No.");
                                END;
                            END; //LS

                            IF ABS(RemQtyToBeInvoiced) > ABS(PurchLine."Return Qty. to Ship") THEN BEGIN
                                IF "Document Type" = "Document Type"::"Credit Memo" THEN
                                    ERROR(
                                      Text039,
                                      ReturnShptLine."Document No.");
                                ERROR(Text040);
                            END;

                        END ELSE BEGIN

                            IF ABS(RemQtyToBeInvoiced) > ABS(PurchLine."Qty. to Receive") THEN BEGIN
                                PurchRcptLine.RESET;
                                CASE "Document Type" OF
                                    "Document Type"::Order:
                                        BEGIN
                                            PurchRcptLine.SETCURRENTKEY("Order No.", "Order Line No.");
                                            PurchRcptLine.SETRANGE("Order No.", PurchLine."Document No.");
                                            PurchRcptLine.SETRANGE("Order Line No.", PurchLine."Line No.");
                                        END;
                                    "Document Type"::Invoice:
                                        BEGIN
                                            PurchRcptLine.SETRANGE("Document No.", PurchLine."Receipt No.");
                                            PurchRcptLine.SETRANGE("Line No.", PurchLine."Receipt Line No.");
                                        END;
                                END;

                                //LS -
                                IF (NOT PurchRcptLine.FIND('-')) AND (PurchLine.Type = PurchLine.Type::Item) THEN BEGIN
                                    xICTHeader.RESET();
                                    xICTHeader.SETCURRENTKEY("Dist. Location To", "ICT Source Doc. Type", "ICT Source Doc. No.", "ICT Source Line No.");
                                    xICTHeader.SETRANGE("Dist. Location To", LSRetailSetup."Distribution Location");
                                    xICTHeader.SETRANGE("ICT Source Doc. Type", PurchHeader."Document Type");
                                    xICTHeader.SETRANGE("ICT Source Doc. No.", PurchHeader."No.");
                                    xICTHeader.SETRANGE("ICT Source Line No.", PurchLine."Line No.");
                                    IF xICTHeader.FIND('-') THEN
                                        REPEAT
                                            xItemLedgerEntry.GET(xICTHeader."Destination ItemLedgerEntryNo");
                                            QtyToBeInvoicedBase := xItemLedgerEntry.Quantity;
                                            QtyToBeInvoiced := QtyToBeInvoicedBase / xItemLedgerEntry."Qty. per Unit of Measure";
                                            PostItemJnlLine(
                                              PurchLine,
                                              0, 0,
                                              QtyToBeInvoiced, QtyToBeInvoicedBase,
                                              xICTHeader."Destination ItemLedgerEntryNo", '', DummyTrackingSpecification);
                                            RemQtyToBeInvoiced := RemQtyToBeInvoiced - QtyToBeInvoiced;
                                            RemQtyToBeInvoicedBase := RemQtyToBeInvoicedBase - QtyToBeInvoicedBase;
                                        UNTIL xICTHeader.NEXT() = 0
                                    ELSE
                                        ERROR(
                                          Text030,
                                          PurchLine."Receipt Line No.", PurchLine."Receipt No.");
                                END ELSE BEGIN
                                    //LS +
                                    PurchRcptLine.SETFILTER("Qty. Rcd. Not Invoiced", '<>0');
                                    IF PurchRcptLine.FINDSET(TRUE, FALSE) THEN BEGIN
                                        ItemJnlRollRndg := TRUE;
                                        REPEAT
                                            IF TrackingSpecificationExists THEN BEGIN
                                                ItemEntryRelation.GET(TempInvoicingSpecification."Appl.-to Item Entry");
                                                PurchRcptLine.GET(ItemEntryRelation."Source ID", ItemEntryRelation."Source Ref. No.");
                                            END ELSE
                                                ItemEntryRelation."Item Entry No." := PurchRcptLine."Item Rcpt. Entry No.";
                                            PurchRcptLine.TESTFIELD("Buy-from Vendor No.", PurchLine."Buy-from Vendor No.");
                                            PurchRcptLine.TESTFIELD(Type, PurchLine.Type);
                                            PurchRcptLine.TESTFIELD("No.", PurchLine."No.");
                                            PurchRcptLine.TESTFIELD("Gen. Bus. Posting Group", PurchLine."Gen. Bus. Posting Group");
                                            PurchRcptLine.TESTFIELD("Gen. Prod. Posting Group", PurchLine."Gen. Prod. Posting Group");
                                            PurchRcptLine.TESTFIELD("Job No.", PurchLine."Job No.");
                                            PurchRcptLine.TESTFIELD("Unit of Measure Code", PurchLine."Unit of Measure Code");
                                            PurchRcptLine.TESTFIELD("Variant Code", PurchLine."Variant Code");
                                            PurchRcptLine.TESTFIELD("Prod. Order No.", PurchLine."Prod. Order No.");
                                            IF PurchLine."Qty. to Invoice" * PurchRcptLine.Quantity < 0 THEN
                                                PurchLine.FIELDERROR("Qty. to Invoice", Text012);
                                            IF TrackingSpecificationExists THEN BEGIN
                                                QtyToBeInvoiced := TempInvoicingSpecification."Qty. to Invoice";
                                                QtyToBeInvoicedBase := TempInvoicingSpecification."Qty. to Invoice (Base)";
                                            END ELSE BEGIN
                                                QtyToBeInvoiced := RemQtyToBeInvoiced - PurchLine."Qty. to Receive";
                                                QtyToBeInvoicedBase := RemQtyToBeInvoicedBase - PurchLine."Qty. to Receive (Base)";
                                            END;
                                            IF ABS(QtyToBeInvoiced) >
                                               ABS(PurchRcptLine.Quantity - PurchRcptLine."Quantity Invoiced")
                                            THEN BEGIN
                                                QtyToBeInvoiced := PurchRcptLine.Quantity - PurchRcptLine."Quantity Invoiced";
                                                QtyToBeInvoicedBase := PurchRcptLine."Quantity (Base)" - PurchRcptLine."Qty. Invoiced (Base)";
                                            END;
                                            IF TrackingSpecificationExists THEN
                                                ItemTrackingMgt.AdjustQuantityRounding(
                                                  RemQtyToBeInvoiced, QtyToBeInvoiced,
                                                  RemQtyToBeInvoicedBase, QtyToBeInvoicedBase);

                                            RemQtyToBeInvoiced := RemQtyToBeInvoiced - QtyToBeInvoiced;
                                            RemQtyToBeInvoicedBase := RemQtyToBeInvoicedBase - QtyToBeInvoicedBase;
                                            PurchRcptLine."Quantity Invoiced" := PurchRcptLine."Quantity Invoiced" + QtyToBeInvoiced;
                                            PurchRcptLine."Qty. Invoiced (Base)" := PurchRcptLine."Qty. Invoiced (Base)" + QtyToBeInvoicedBase;
                                            PurchRcptLine."Qty. Rcd. Not Invoiced" :=
                                              PurchRcptLine.Quantity - PurchRcptLine."Quantity Invoiced";
                                            PurchRcptLine.MODIFY;
                                            IF PurchLine.Type = PurchLine.Type::Item THEN
                                                PostItemJnlLine(
                                                  PurchLine,
                                                  0, 0,
                                                  QtyToBeInvoiced, QtyToBeInvoicedBase,
                                                  /*PurchRcptLine."Item Rcpt. Entry No."*/
                                                  ItemEntryRelation."Item Entry No.", '', TempInvoicingSpecification);
                                            IF TrackingSpecificationExists THEN
                                                EndLoop := (TempInvoicingSpecification.NEXT = 0)
                                            ELSE
                                                EndLoop :=
                                                  (PurchRcptLine.NEXT = 0) OR (ABS(RemQtyToBeInvoiced) <= ABS(PurchLine."Qty. to Receive"));
                                        UNTIL EndLoop;
                                    END ELSE
                                        ERROR(
                                          Text030,
                                          PurchLine."Receipt Line No.", PurchLine."Receipt No.");
                                END;
                            END; //LS

                            IF ABS(RemQtyToBeInvoiced) > ABS(PurchLine."Qty. to Receive") THEN BEGIN
                                IF "Document Type" = "Document Type"::Invoice THEN
                                    ERROR(
                                      Text031,
                                      PurchRcptLine."Document No.");
                                ERROR(Text014);
                            END;
                        END;

                        IF TrackingSpecificationExists THEN
                            SaveInvoiceSpecification(TempInvoicingSpecification);
                    END;

                    CASE PurchLine.Type OF
                        PurchLine.Type::"G/L Account":
                            IF (PurchLine."No." <> '') AND NOT PurchLine."System-Created Entry" THEN BEGIN
                                GLAcc.GET(PurchLine."No.");
                                GLAcc.TESTFIELD("Direct Posting");
                                IF (PurchLine."Job No." <> '') AND (PurchLine."Qty. to Invoice" <> 0) THEN BEGIN
                                    TempDocDim.RESET;
                                    TempDocDim.SETRANGE("Table ID", DATABASE::"Purchase Line");
                                    TempDocDim.SETRANGE("Line No.", PurchLine."Line No.");
                                    TempJnlLineDim.DELETEALL;
                                    DimMgt.CopyDocDimToJnlLineDim(TempDocDim, TempJnlLineDim);
                                    JobPostLine.InsertPurchLine(
                                      PurchHeader, PurchInvHeader, PurchCrMemoHeader, JobPurchLine, SrcCode, TempJnlLineDim);
                                END;
                                IF (PurchLine."IC Partner Code" <> '') AND Invoice THEN
                                    InsertICGenJnlLine(TempPurchLine);
                            END;
                        PurchLine.Type::Item:
                            BEGIN
                                IF RemQtyToBeInvoiced <> 0 THEN
                                    ItemLedgShptEntryNo :=
                                      PostItemJnlLine(
                                        PurchLine,
                                        RemQtyToBeInvoiced, RemQtyToBeInvoicedBase,
                                        RemQtyToBeInvoiced, RemQtyToBeInvoicedBase,
                                        0, '', DummyTrackingSpecification);
                                IF "Document Type" IN ["Document Type"::"Return Order", "Document Type"::"Credit Memo"] THEN BEGIN
                                    IF ABS(PurchLine."Return Qty. to Ship") > ABS(RemQtyToBeInvoiced) THEN
                                        ItemLedgShptEntryNo :=
                                          PostItemJnlLine(
                                            PurchLine,
                                            PurchLine."Return Qty. to Ship" - RemQtyToBeInvoiced,
                                            PurchLine."Return Qty. to Ship (Base)" - RemQtyToBeInvoicedBase,
                                            0, 0, 0, '', DummyTrackingSpecification);
                                END ELSE BEGIN
                                    IF ABS(PurchLine."Qty. to Receive") > ABS(RemQtyToBeInvoiced) THEN
                                        ItemLedgShptEntryNo :=
                                          PostItemJnlLine(
                                            PurchLine,
                                            PurchLine."Qty. to Receive" - RemQtyToBeInvoiced,
                                            PurchLine."Qty. to Receive (Base)" - RemQtyToBeInvoicedBase,
                                            0, 0, 0, '', DummyTrackingSpecification);
                                    IF (PurchLine."Qty. to Receive" <> 0) AND
                                       (PurchLine."Sales Order Line No." <> 0)
                                    THEN BEGIN
                                        DropShptPostBuffer."Order No." := PurchLine."Sales Order No.";
                                        DropShptPostBuffer."Order Line No." := PurchLine."Sales Order Line No.";
                                        DropShptPostBuffer.Quantity := PurchLine."Qty. to Receive";
                                        DropShptPostBuffer."Quantity (Base)" := PurchLine."Qty. to Receive (Base)";
                                        DropShptPostBuffer."Item Shpt. Entry No." :=
                                          PostAssocItemJnlLine(DropShptPostBuffer.Quantity, DropShptPostBuffer."Quantity (Base)");
                                        DropShptPostBuffer.INSERT;
                                    END;
                                END;
                            END;
                        3:
                            ERROR(Text015);
                        PurchLine.Type::"Charge (Item)":
                            IF Invoice OR ItemChargeAssgntOnly THEN BEGIN
                                ItemJnlRollRndg := FALSE;
                                ClearItemChargeAssgntFilter;
                                TempItemChargeAssgntPurch.SETCURRENTKEY("Applies-to Doc. Type");
                                TempItemChargeAssgntPurch.SETFILTER("Applies-to Doc. Type", '<>%1', "Document Type");
                                TempItemChargeAssgntPurch.SETRANGE("Document Line No.", PurchLine."Line No.");
                                IF TempItemChargeAssgntPurch.FINDSET THEN
                                    REPEAT
                                        IF ItemChargeAssgntOnly AND (GenJnlLineDocNo = '') THEN
                                            GenJnlLineDocNo := TempItemChargeAssgntPurch."Applies-to Doc. No.";
                                        CASE TempItemChargeAssgntPurch."Applies-to Doc. Type" OF
                                            TempItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt:
                                                PostItemChargePerRcpt(PurchLine);
                                            TempItemChargeAssgntPurch."Applies-to Doc. Type"::"Transfer Receipt":
                                                PostItemChargePerTransfer(PurchLine);
                                            TempItemChargeAssgntPurch."Applies-to Doc. Type"::"Return Shipment":
                                                PostItemChargePerRetShpt(PurchLine);
                                            TempItemChargeAssgntPurch."Applies-to Doc. Type"::"Sales Shipment":
                                                PostItemChargePerSalesShpt(PurchLine);
                                            TempItemChargeAssgntPurch."Applies-to Doc. Type"::"Return Receipt":
                                                PostItemChargePerRetRcpt(PurchLine);
                                        END;
                                        TempItemChargeAssgntPurch.MARK(TRUE);
                                    UNTIL TempItemChargeAssgntPurch.NEXT = 0;
                            END;
                    END;

                    IF (PurchLine.Type >= PurchLine.Type::"G/L Account") AND (PurchLine."Qty. to Invoice" <> 0) THEN BEGIN
                        // Copy purchase to buffer
                        FillInvPostingBuffer(PurchLine, PurchLineACY);
                        TempDocDim.SETRANGE("Table ID");
                        TempDocDim.SETRANGE("Line No.");
                    END;

                    IF (PurchRcptHeader."No." <> '') AND (PurchLine."Receipt No." = '') AND
                       NOT RoundingLineInserted AND NOT TempPurchLine."Prepayment Line"
                    THEN BEGIN
                        // Insert receipt line
                        PurchRcptLine.INIT;
                        PurchRcptLine.TRANSFERFIELDS(TempPurchLine);
                        PurchRcptLine."Posting Date" := "Posting Date";
                        PurchRcptLine."Document No." := PurchRcptHeader."No.";
                        PurchRcptLine.Quantity := TempPurchLine."Qty. to Receive";
                        PurchRcptLine."Quantity (Base)" := TempPurchLine."Qty. to Receive (Base)";
                        IF ABS(TempPurchLine."Qty. to Invoice") > ABS(TempPurchLine."Qty. to Receive") THEN BEGIN
                            PurchRcptLine."Quantity Invoiced" := TempPurchLine."Qty. to Receive";
                            PurchRcptLine."Qty. Invoiced (Base)" := TempPurchLine."Qty. to Receive (Base)";
                        END ELSE BEGIN
                            PurchRcptLine."Quantity Invoiced" := TempPurchLine."Qty. to Invoice";
                            PurchRcptLine."Qty. Invoiced (Base)" := TempPurchLine."Qty. to Invoice (Base)";
                        END;
                        PurchRcptLine."Qty. Rcd. Not Invoiced" :=
                          PurchRcptLine.Quantity - PurchRcptLine."Quantity Invoiced";
                        IF "Document Type" = "Document Type"::Order THEN BEGIN
                            PurchRcptLine."Order No." := TempPurchLine."Document No.";
                            PurchRcptLine."Order Line No." := TempPurchLine."Line No.";
                        END;
                        IF (PurchLine.Type = PurchLine.Type::Item) AND (TempPurchLine."Qty. to Receive" <> 0) THEN BEGIN
                            IF WhseReceive THEN BEGIN
                                WhseRcptLine.SETCURRENTKEY(
                                  "No.", "Source Type", "Source Subtype", "Source No.", "Source Line No.");
                                WhseRcptLine.SETRANGE("No.", WhseRcptHeader."No.");
                                WhseRcptLine.SETRANGE("Source Type", DATABASE::"Purchase Line");
                                WhseRcptLine.SETRANGE("Source Subtype", PurchLine."Document Type");
                                WhseRcptLine.SETRANGE("Source No.", PurchLine."Document No.");
                                WhseRcptLine.SETRANGE("Source Line No.", PurchLine."Line No.");
                                WhseRcptLine.FINDFIRST;
                                WhseRcptLine.TESTFIELD("Qty. to Receive", PurchRcptLine.Quantity);
                                SaveTempWhseSplitSpec(PurchLine);
                                WhsePostRcpt.CreatePostedRcptLine(
                                  WhseRcptLine, PostedWhseRcptHeader, PostedWhseRcptLine, TempWhseSplitSpecification);
                            END;
                            IF WhseShip THEN BEGIN
                                WhseShptLine.SETCURRENTKEY(
                                  "No.", "Source Type", "Source Subtype", "Source No.", "Source Line No.");
                                WhseShptLine.SETRANGE("No.", WhseShptHeader."No.");
                                WhseShptLine.SETRANGE("Source Type", DATABASE::"Purchase Line");
                                WhseShptLine.SETRANGE("Source Subtype", PurchLine."Document Type");
                                WhseShptLine.SETRANGE("Source No.", PurchLine."Document No.");
                                WhseShptLine.SETRANGE("Source Line No.", PurchLine."Line No.");
                                WhseShptLine.FINDFIRST;
                                WhseShptLine.TESTFIELD("Qty. to Ship", -PurchRcptLine.Quantity);
                                SaveTempWhseSplitSpec(PurchLine);
                                WhsePostShpt.CreatePostedShptLine(
                                  WhseShptLine, PostedWhseShptHeader, PostedWhseShptLine, TempWhseSplitSpecification);
                            END;

                            PurchRcptLine."Item Rcpt. Entry No." :=
                              InsertRcptEntryRelation(PurchRcptLine); // ItemLedgShptEntryNo
                            PurchRcptLine."Item Charge Base Amount" :=
                              ROUND(CostBaseAmount / PurchLine.Quantity * PurchRcptLine.Quantity);
                        END;
                        PurchRcptLine.INSERT;

                        //LS -
                        IF PurchHeader."Only Two Dimensions" THEN BEGIN
                            TempDocDim.SETRANGE(TempDocDim."Table ID", DATABASE::"Purchase Line");
                            TempDocDim.SETRANGE(TempDocDim."Line No.", PurchRcptLine."Line No.");
                            DimMgt.MoveDocDimToPostedDocDim(TempDocDim, DATABASE::"Purch. Rcpt. Line", PurchRcptHeader."No.");
                        END ELSE BEGIN
                            DimMgt.MoveOneDocDimToPostedDocDim(
                              TempDocDim, DATABASE::"Purchase Line", "Document Type", "No.", PurchRcptLine."Line No.",
                              DATABASE::"Purch. Rcpt. Line", PurchRcptHeader."No.");
                        END;
                        //LS +

                    END;

                    IF (ReturnShptHeader."No." <> '') AND (PurchLine."Return Shipment No." = '') AND
                       NOT RoundingLineInserted
                    THEN BEGIN
                        // Insert return shipment line
                        ReturnShptLine.INIT;
                        ReturnShptLine.TRANSFERFIELDS(TempPurchLine);
                        ReturnShptLine."Posting Date" := "Posting Date";
                        ReturnShptLine."Document No." := ReturnShptHeader."No.";
                        ReturnShptLine.Quantity := TempPurchLine."Return Qty. to Ship";
                        ReturnShptLine."Quantity (Base)" := TempPurchLine."Return Qty. to Ship (Base)";
                        IF ABS(TempPurchLine."Qty. to Invoice") > ABS(TempPurchLine."Return Qty. to Ship") THEN BEGIN
                            ReturnShptLine."Quantity Invoiced" := TempPurchLine."Return Qty. to Ship";
                            ReturnShptLine."Qty. Invoiced (Base)" := TempPurchLine."Return Qty. to Ship (Base)";
                        END ELSE BEGIN
                            ReturnShptLine."Quantity Invoiced" := TempPurchLine."Qty. to Invoice";
                            ReturnShptLine."Qty. Invoiced (Base)" := TempPurchLine."Qty. to Invoice (Base)";
                        END;
                        ReturnShptLine."Return Qty. Shipped Not Invd." :=
                          ReturnShptLine.Quantity - ReturnShptLine."Quantity Invoiced";
                        IF "Document Type" = "Document Type"::"Return Order" THEN BEGIN
                            ReturnShptLine."Return Order No." := TempPurchLine."Document No.";
                            ReturnShptLine."Return Order Line No." := TempPurchLine."Line No.";
                        END;
                        IF (PurchLine.Type = PurchLine.Type::Item) AND (TempPurchLine."Return Qty. to Ship" <> 0) THEN BEGIN
                            IF WhseShip THEN BEGIN
                                WhseShptLine.SETCURRENTKEY(
                                  "No.", "Source Type", "Source Subtype", "Source No.", "Source Line No.");
                                WhseShptLine.SETRANGE("No.", WhseShptHeader."No.");
                                WhseShptLine.SETRANGE("Source Type", DATABASE::"Purchase Line");
                                WhseShptLine.SETRANGE("Source Subtype", PurchLine."Document Type");
                                WhseShptLine.SETRANGE("Source No.", PurchLine."Document No.");
                                WhseShptLine.SETRANGE("Source Line No.", PurchLine."Line No.");
                                WhseShptLine.FINDFIRST;
                                WhseShptLine.TESTFIELD("Qty. to Ship", ReturnShptLine.Quantity);
                                SaveTempWhseSplitSpec(PurchLine);
                                WhsePostShpt.CreatePostedShptLine(
                                  WhseShptLine, PostedWhseShptHeader, PostedWhseShptLine, TempWhseSplitSpecification);
                            END;
                            IF WhseReceive THEN BEGIN
                                WhseRcptLine.SETCURRENTKEY(
                                  "No.", "Source Type", "Source Subtype", "Source No.", "Source Line No.");
                                WhseRcptLine.SETRANGE("No.", WhseRcptHeader."No.");
                                WhseRcptLine.SETRANGE("Source Type", DATABASE::"Purchase Line");
                                WhseRcptLine.SETRANGE("Source Subtype", PurchLine."Document Type");
                                WhseRcptLine.SETRANGE("Source No.", PurchLine."Document No.");
                                WhseRcptLine.SETRANGE("Source Line No.", PurchLine."Line No.");
                                WhseRcptLine.FINDFIRST;
                                WhseRcptLine.TESTFIELD("Qty. to Receive", -ReturnShptLine.Quantity);
                                SaveTempWhseSplitSpec(PurchLine);
                                WhsePostRcpt.CreatePostedRcptLine(
                                  WhseRcptLine, PostedWhseRcptHeader, PostedWhseRcptLine, TempWhseSplitSpecification);
                            END;

                            ReturnShptLine."Item Shpt. Entry No." :=
                              InsertReturnEntryRelation(ReturnShptLine); // ItemLedgShptEntryNo;
                            ReturnShptLine."Item Charge Base Amount" :=
                              ROUND(CostBaseAmount / PurchLine.Quantity * ReturnShptLine.Quantity);
                        END;
                        ReturnShptLine.INSERT;
                        //LS -
                        IF PurchHeader."Only Two Dimensions" THEN BEGIN
                            TempDocDim.SETRANGE(TempDocDim."Table ID", DATABASE::"Purchase Line");
                            TempDocDim.SETRANGE(TempDocDim."Line No.", ReturnShptLine."Line No.");
                            DimMgt.MoveDocDimToPostedDocDim(TempDocDim, DATABASE::"Return Shipment Line", ReturnShptHeader."No.");
                        END ELSE BEGIN
                            DimMgt.MoveOneDocDimToPostedDocDim(
                              TempDocDim, DATABASE::"Purchase Line", "Document Type", "No.", ReturnShptLine."Line No.",
                              DATABASE::"Return Shipment Line", ReturnShptHeader."No.");
                        END;
                        //LS +

                    END;

                    IF Invoice THEN BEGIN
                        // Insert invoice line or credit memo line
                        IF "Document Type" IN ["Document Type"::Order, "Document Type"::Invoice] THEN BEGIN
                            PurchInvLine.INIT;
                            PurchInvLine.TRANSFERFIELDS(TempPurchLine);
                            PurchInvLine."Posting Date" := "Posting Date";
                            PurchInvLine."Document No." := PurchInvHeader."No.";
                            PurchInvLine.Quantity := TempPurchLine."Qty. to Invoice";
                            PurchInvLine."Quantity (Base)" := TempPurchLine."Qty. to Invoice (Base)";
                            PurchInvLine.INSERT;
                            //LS -
                            IF PurchHeader."Only Two Dimensions" THEN BEGIN
                                TempDocDim.SETRANGE(TempDocDim."Table ID", DATABASE::"Purchase Line");
                                TempDocDim.SETRANGE(TempDocDim."Line No.", PurchInvLine."Line No.");
                                DimMgt.MoveDocDimToPostedDocDim(TempDocDim, DATABASE::"Purch. Inv. Line", PurchInvHeader."No.");
                            END ELSE BEGIN
                                DimMgt.MoveOneDocDimToPostedDocDim(
                                  TempDocDim, DATABASE::"Purchase Line", "Document Type", "No.", PurchInvLine."Line No.",
                                  DATABASE::"Purch. Inv. Line", PurchInvHeader."No.");
                            END;
                            //LS +
                            ItemJnlPostLine.CollectValueEntryRelation(TempValueEntryRelation, PurchInvLine.RowID1);
                        END ELSE BEGIN // Credit Memo
                            PurchCrMemoLine.INIT;
                            PurchCrMemoLine.TRANSFERFIELDS(TempPurchLine);
                            PurchCrMemoLine."Posting Date" := "Posting Date";
                            PurchCrMemoLine."Document No." := PurchCrMemoHeader."No.";
                            PurchCrMemoLine.Quantity := TempPurchLine."Qty. to Invoice";
                            PurchCrMemoLine."Quantity (Base)" := TempPurchLine."Qty. to Invoice (Base)";
                            PurchCrMemoLine.INSERT;
                            //LS -
                            IF PurchHeader."Only Two Dimensions" THEN BEGIN
                                TempDocDim.SETRANGE(TempDocDim."Table ID", DATABASE::"Purchase Line");
                                TempDocDim.SETRANGE(TempDocDim."Line No.", PurchCrMemoLine."Line No.");
                                DimMgt.MoveDocDimToPostedDocDim(TempDocDim, DATABASE::"Purch. Cr. Memo Line", PurchCrMemoHeader."No.");
                            END ELSE BEGIN
                                DimMgt.MoveOneDocDimToPostedDocDim(
                                  TempDocDim, DATABASE::"Purchase Line", "Document Type", "No.", PurchCrMemoLine."Line No.",
                                  DATABASE::"Purch. Cr. Memo Line", PurchCrMemoHeader."No.");
                            END;
                            //LS +

                            ItemJnlPostLine.CollectValueEntryRelation(TempValueEntryRelation, PurchCrMemoLine.RowID1);
                        END;
                    END;

                    IF RoundingLineInserted THEN
                        LastLineRetrieved := TRUE
                    ELSE BEGIN
                        LastLineRetrieved := GetNextPurchline(PurchLine);
                        IF LastLineRetrieved AND PurchSetup."Invoice Rounding" THEN
                            InvoiceRounding(FALSE);
                    END;
                UNTIL LastLineRetrieved;

            IF "Document Type" IN ["Document Type"::"Return Order", "Document Type"::"Credit Memo"] THEN BEGIN
                ReverseAmount(TotalPurchLine);
                ReverseAmount(TotalPurchLineLCY);
            END;

            // Post combine shipment of sales order
            SalesSetup.GET;
            IF DropShptPostBuffer.FINDSET THEN
                REPEAT
                    SalesOrderHeader.GET(
                      SalesOrderHeader."Document Type"::Order,
                      DropShptPostBuffer."Order No.");
                    SalesShptHeader.INIT;
                    SalesShptHeader.TRANSFERFIELDS(SalesOrderHeader);
                    SalesShptHeader."No." := SalesOrderHeader."Shipping No.";
                    SalesShptHeader."Order No." := SalesOrderHeader."No.";
                    SalesShptHeader."Posting Date" := "Posting Date";
                    SalesShptHeader."Document Date" := "Document Date";
                    SalesShptHeader."No. Printed" := 0;
                    SalesShptHeader.INSERT(TRUE);
                    //LS -
                    IF PurchHeader."Only Two Dimensions" THEN BEGIN
                        TempDocDim2.DELETEALL();
                        TempDocDim2.INIT();
                        TempDocDim2."Table ID" := DATABASE::"Sales Header";
                        TempDocDim2."Document Type" := SalesOrderHeader."Document Type";
                        TempDocDim2."Document No." := SalesOrderHeader."No.";
                        TempDocDim2."Line No." := 0;
                        TempDocDim2."Dimension Code" := GLSetup."Global Dimension 1 Code";
                        TempDocDim2."Dimension Value Code" := SalesOrderHeader."Shortcut Dimension 1 Code";
                        IF TempDocDim2."Dimension Value Code" <> '' THEN
                            TempDocDim2.INSERT();
                        TempDocDim2."Dimension Code" := GLSetup."Global Dimension 2 Code";
                        TempDocDim2."Dimension Value Code" := SalesOrderHeader."Shortcut Dimension 2 Code";
                        IF TempDocDim2."Dimension Value Code" <> '' THEN
                            TempDocDim2.INSERT();
                        DimMgt.MoveDocDimToPostedDocDim(TempDocDim2, DATABASE::"Sales Shipment Header", SalesShptHeader."No.");
                    END ELSE BEGIN
                        DimMgt.MoveOneDocDimToPostedDocDim(
                          TempDocDim, DATABASE::"Sales Header", SalesOrderHeader."Document Type", SalesOrderHeader."No.",
                          0, DATABASE::"Sales Shipment Header", SalesShptHeader."No.");
                    END;
                    //LS +

                    ApprovalMgt.MoveApprvalEntryToPosted(TempApprovalEntry, DATABASE::"Sales Shipment Header", SalesShptHeader."No.");

                    IF SalesSetup."Copy Comments Order to Shpt." THEN BEGIN
                        CopySalesCommentLines(
                          SalesOrderHeader."Document Type", SalesCommentLine."Document Type"::Shipment,
                          SalesOrderHeader."No.", SalesShptHeader."No.");
                        SalesShptHeader.COPYLINKS(Rec);
                    END;
                    DropShptPostBuffer.SETRANGE("Order No.", DropShptPostBuffer."Order No.");
                    REPEAT
                        SalesOrderLine.GET(
                          SalesOrderLine."Document Type"::Order,
                          DropShptPostBuffer."Order No.", DropShptPostBuffer."Order Line No.");
                        SalesShptLine.INIT;
                        SalesShptLine.TRANSFERFIELDS(SalesOrderLine);
                        SalesShptLine."Posting Date" := SalesShptHeader."Posting Date";
                        SalesShptLine."Document No." := SalesShptHeader."No.";
                        SalesShptLine.Quantity := DropShptPostBuffer.Quantity;
                        SalesShptLine."Quantity (Base)" := DropShptPostBuffer."Quantity (Base)";
                        SalesShptLine."Quantity Invoiced" := 0;
                        SalesShptLine."Qty. Invoiced (Base)" := 0;
                        SalesShptLine."Order No." := SalesOrderLine."Document No.";
                        SalesShptLine."Order Line No." := SalesOrderLine."Line No.";
                        SalesShptLine."Qty. Shipped Not Invoiced" :=
                          SalesShptLine.Quantity - SalesShptLine."Quantity Invoiced";
                        IF SalesShptLine.Quantity <> 0 THEN BEGIN
                            SalesShptLine."Item Shpt. Entry No." := DropShptPostBuffer."Item Shpt. Entry No.";
                            SalesShptLine."Item Charge Base Amount" := SalesOrderLine."Line Amount";
                        END;
                        SalesShptLine.INSERT;
                        ServItemMgt.CreateServItemOnSalesLineShpt(SalesOrderHeader, SalesOrderLine, SalesShptLine);
                        SalesOrderLine."Qty. to Ship" := SalesShptLine.Quantity;
                        SalesOrderLine."Qty. to Ship (Base)" := SalesShptLine."Quantity (Base)";
                        SalesPost.UpdateBlanketOrderLine(SalesOrderLine, TRUE, FALSE, FALSE);
                        //LS -
                        IF PurchHeader."Only Two Dimensions" THEN BEGIN
                            TempDocDim2.DELETEALL();
                            TempDocDim2.INIT();
                            TempDocDim2."Table ID" := DATABASE::"Sales Header";
                            TempDocDim2."Document Type" := SalesOrderHeader."Document Type";
                            TempDocDim2."Document No." := SalesOrderHeader."No.";
                            TempDocDim2."Line No." := SalesShptLine."Line No.";
                            TempDocDim2."Dimension Code" := GLSetup."Global Dimension 1 Code";
                            TempDocDim2."Dimension Value Code" := SalesShptLine."Shortcut Dimension 1 Code";
                            IF TempDocDim2."Dimension Value Code" <> '' THEN
                                TempDocDim2.INSERT();
                            TempDocDim2."Dimension Code" := GLSetup."Global Dimension 2 Code";
                            TempDocDim2."Dimension Value Code" := SalesShptLine."Shortcut Dimension 2 Code";
                            IF TempDocDim2."Dimension Value Code" <> '' THEN
                                TempDocDim2.INSERT();
                            DimMgt.MoveDocDimToPostedDocDim(TempDocDim2, DATABASE::"Sales Shipment Line", SalesShptHeader."No.");
                        END ELSE BEGIN
                            DimMgt.MoveOneDocDimToPostedDocDim(
                              TempDocDim, DATABASE::"Sales Line", SalesOrderHeader."Document Type", SalesOrderHeader."No.",
                              SalesShptLine."Line No.", DATABASE::"Sales Shipment Line", SalesShptHeader."No.");
                        END;
                        //LS +

                        SalesOrderLine.SETRANGE("Document Type", SalesOrderLine."Document Type"::Order);
                        SalesOrderLine.SETRANGE("Document No.", DropShptPostBuffer."Order No.");
                        SalesOrderLine.SETRANGE("Attached to Line No.", DropShptPostBuffer."Order Line No.");
                        SalesOrderLine.SETRANGE(Type, SalesOrderLine.Type::" ");
                        IF SalesOrderLine.FINDSET THEN
                            REPEAT
                                SalesShptLine.INIT;
                                SalesShptLine.TRANSFERFIELDS(SalesOrderLine);
                                SalesShptLine."Document No." := SalesShptHeader."No.";
                                SalesShptLine."Order No." := SalesOrderLine."Document No.";
                                SalesShptLine."Order Line No." := SalesOrderLine."Line No.";
                                SalesShptLine.INSERT;
                            UNTIL SalesOrderLine.NEXT = 0;

                    UNTIL DropShptPostBuffer.NEXT = 0;
                    DropShptPostBuffer.SETRANGE("Order No.");
                UNTIL DropShptPostBuffer.NEXT = 0;

            IF Invoice THEN BEGIN
                // Post purchase and VAT to G/L entries from buffer
                LineCount := 0;
                IF InvPostingBuffer[1].FIND('+') THEN
                    REPEAT
                        LineCount := LineCount + 1;
                        IF GUIALLOWED THEN
                            Window.UPDATE(3, LineCount);

                        CASE InvPostingBuffer[1]."VAT Calculation Type" OF
                            InvPostingBuffer[1]."VAT Calculation Type"::"Reverse Charge VAT":
                                BEGIN
                                    VATPostingSetup.GET(
                                      InvPostingBuffer[1]."VAT Bus. Posting Group", InvPostingBuffer[1]."VAT Prod. Posting Group");
                                    InvPostingBuffer[1]."VAT Amount" :=
                                      ROUND(
                                        InvPostingBuffer[1].Amount * VATPostingSetup."VAT %" / 100);
                                    InvPostingBuffer[1]."VAT Amount (ACY)" :=
                                      ROUND(
                                        (InvPostingBuffer[1]."Amount (ACY)" * VATPostingSetup."VAT %" / 100), Currency."Amount Rounding Precision");
                                END;
                            InvPostingBuffer[1]."VAT Calculation Type"::"Sales Tax":
                                BEGIN
                                    IF InvPostingBuffer[1]."Use Tax" THEN BEGIN
                                        InvPostingBuffer[1]."VAT Amount" :=
                                          ROUND(
                                            SalesTaxCalculate.CalculateTax(
                                              InvPostingBuffer[1]."Tax Area Code", InvPostingBuffer[1]."Tax Group Code",
                                              InvPostingBuffer[1]."Tax Liable", PurchHeader."Posting Date",
                                              InvPostingBuffer[1].Amount,
                                              InvPostingBuffer[1].Quantity, 0));
                                        IF GLSetup."Additional Reporting Currency" <> '' THEN
                                            InvPostingBuffer[1]."VAT Amount (ACY)" :=
                                              CurrExchRate.ExchangeAmtLCYToFCY(
                                                PurchHeader."Posting Date", GLSetup."Additional Reporting Currency",
                                                InvPostingBuffer[1]."VAT Amount", 0);
                                    END;
                                END;
                        END;

                        GenJnlLine.INIT;
                        GenJnlLine."Posting Date" := "Posting Date";
                        GenJnlLine."Document Date" := "Document Date";
                        //<<SP-03-02-2020
                        IF InvPostingBuffer[1]."Line Description" = '' THEN
                            GenJnlLine.Description := "Posting Description"
                        ELSE
                            GenJnlLine.Description := InvPostingBuffer[1]."Line Description";
                        //>>SP-03-02-2020
                        //GenJnlLine.Description := "Posting Description";//SP-03-02-2020
                        GenJnlLine."Reason Code" := "Reason Code";
                        GenJnlLine."Document Type" := GenJnlLineDocType;
                        GenJnlLine."Document No." := GenJnlLineDocNo;
                        GenJnlLine."External Document No." := GenJnlLineExtDocNo;
                        GenJnlLine."Account No." := InvPostingBuffer[1]."G/L Account";
                        GenJnlLine."System-Created Entry" := InvPostingBuffer[1]."System-Created Entry";
                        GenJnlLine.Amount := InvPostingBuffer[1].Amount;
                        GenJnlLine."Source Currency Code" := "Currency Code";
                        GenJnlLine."Source Currency Amount" := InvPostingBuffer[1]."Amount (ACY)";
                        GenJnlLine.Correction := Correction;
                        GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::Purchase;
                        GenJnlLine."Gen. Bus. Posting Group" := InvPostingBuffer[1]."Gen. Bus. Posting Group";
                        GenJnlLine."Gen. Prod. Posting Group" := InvPostingBuffer[1]."Gen. Prod. Posting Group";
                        GenJnlLine."VAT Bus. Posting Group" := InvPostingBuffer[1]."VAT Bus. Posting Group";
                        GenJnlLine."VAT Prod. Posting Group" := InvPostingBuffer[1]."VAT Prod. Posting Group";
                        GenJnlLine."Tax Area Code" := InvPostingBuffer[1]."Tax Area Code";
                        GenJnlLine."Tax Liable" := InvPostingBuffer[1]."Tax Liable";
                        GenJnlLine."Tax Group Code" := InvPostingBuffer[1]."Tax Group Code";
                        GenJnlLine."Use Tax" := InvPostingBuffer[1]."Use Tax";
                        GenJnlLine.Quantity := InvPostingBuffer[1].Quantity;
                        GenJnlLine."VAT Calculation Type" := InvPostingBuffer[1]."VAT Calculation Type";
                        GenJnlLine."VAT Base Amount" := InvPostingBuffer[1]."VAT Base Amount";
                        GenJnlLine."VAT Base Discount %" := "VAT Base Discount %";
                        GenJnlLine."Source Curr. VAT Base Amount" := InvPostingBuffer[1]."VAT Base Amount (ACY)";
                        GenJnlLine."VAT Amount" := InvPostingBuffer[1]."VAT Amount";
                        GenJnlLine."Source Curr. VAT Amount" := InvPostingBuffer[1]."VAT Amount (ACY)";
                        GenJnlLine."VAT Difference" := InvPostingBuffer[1]."VAT Difference";
                        GenJnlLine."VAT Posting" := GenJnlLine."VAT Posting"::"Manual VAT Entry";
                        GenJnlLine."Job No." := InvPostingBuffer[1]."Job No.";
                        GenJnlLine."Shortcut Dimension 1 Code" := InvPostingBuffer[1]."Global Dimension 1 Code";
                        GenJnlLine."Shortcut Dimension 2 Code" := InvPostingBuffer[1]."Global Dimension 2 Code";
                        GenJnlLine."Source Code" := SrcCode;
                        GenJnlLine."Sell-to/Buy-from No." := "Buy-from Vendor No.";
                        GenJnlLine."Bill-to/Pay-to No." := "Pay-to Vendor No.";
                        GenJnlLine."Country/Region Code" := "VAT Country/Region Code";
                        GenJnlLine."VAT Registration No." := "VAT Registration No.";
                        GenJnlLine."Source Type" := GenJnlLine."Source Type"::Vendor;
                        GenJnlLine."Source No." := "Pay-to Vendor No.";
                        GenJnlLine."Posting No. Series" := "Posting No. Series";
                        GenJnlLine."IC Partner Code" := "Pay-to IC Partner Code";
                        //GC++
                        CLEAR(PurchHer);
                        IF PurchHer.GET(PurchHer."Document Type"::Order, GenJnlLineDocNo) THEN
                            GenJnlLine."Invoice Received Date" := PurchHer."Date Received"
                        ELSE
                            IF PurchHer.GET(PurchHer."Document Type"::Invoice, GenJnlLineDocNo) THEN
                                GenJnlLine."Invoice Received Date" := PurchHer."Date Received"
                            ELSE
                                IF PurchHer.GET(PurchHer."Document Type"::"Credit Memo", GenJnlLineDocNo) THEN
                                    GenJnlLine."Invoice Received Date" := PurchHer."Date Received";



                        //GC--
                        //APNT-IC1.0
                        IF "IC Transaction No." <> 0 THEN BEGIN
                            GenJnlLine."IC Transaction No." := "IC Transaction No.";
                            GenJnlLine."IC Partner Direction" := "IC Partner Direction";
                        END ELSE BEGIN
                            GenJnlLine."IC Transaction No." := ICTransactionNo;
                            GenJnlLine."IC Partner Direction" := ICDirection;
                        END;
                        //APNT-IC1.0
                        GenJnlLine."Ship-to/Order Address Code" := "Order Address Code";

                        //DP6.01.01 START
                        IF "Ref. Document No." <> '' THEN BEGIN
                            GenJnlLine."Ref. Document Type" := "Ref. Document Type";
                            GenJnlLine."Ref. Document No." := "Ref. Document No.";
                        END;
                        //DP6.01.01 STOP

                        IF InvPostingBuffer[1].Type = InvPostingBuffer[1].Type::"Fixed Asset" THEN BEGIN
                            GenJnlLine."Account Type" := GenJnlLine."Account Type"::"Fixed Asset";
                            IF InvPostingBuffer[1]."FA Posting Type" =
                              InvPostingBuffer[1]."FA Posting Type"::"Acquisition Cost"
                            THEN
                                GenJnlLine."FA Posting Type" := GenJnlLine."FA Posting Type"::"Acquisition Cost";
                            IF InvPostingBuffer[1]."FA Posting Type" =
                               InvPostingBuffer[1]."FA Posting Type"::Maintenance
                            THEN
                                GenJnlLine."FA Posting Type" := GenJnlLine."FA Posting Type"::Maintenance;
                            GenJnlLine."FA Posting Date" := InvPostingBuffer[1]."FA Posting Date";
                            GenJnlLine."Depreciation Book Code" := InvPostingBuffer[1]."Depreciation Book Code";
                            GenJnlLine."Salvage Value" := InvPostingBuffer[1]."Salvage Value";
                            GenJnlLine."Depr. until FA Posting Date" := InvPostingBuffer[1]."Depr. until FA Posting Date";
                            GenJnlLine."Depr. Acquisition Cost" := InvPostingBuffer[1]."Depr. Acquisition Cost";
                            GenJnlLine."Maintenance Code" := InvPostingBuffer[1]."Maintenance Code";
                            GenJnlLine."Insurance No." := InvPostingBuffer[1]."Insurance No.";
                            GenJnlLine."Budgeted FA No." := InvPostingBuffer[1]."Budgeted FA No.";
                            GenJnlLine."Duplicate in Depreciation Book" := InvPostingBuffer[1]."Duplicate in Depreciation Book";
                            GenJnlLine."Use Duplication List" := InvPostingBuffer[1]."Use Duplication List";
                        END;
                        //DP6.01.01 START
                        IF "Ref. Document No." <> '' THEN BEGIN
                            GenJnlLine."Ref. Document Type" := "Ref. Document Type";
                            GenJnlLine."Ref. Document No." := "Ref. Document No.";
                        END;
                        //DP6.01.01 STOP

                        RunGenJnlPostLine(GenJnlLine, InvPostingBuffer[1]."Dimension Entry No.");
                    UNTIL InvPostingBuffer[1].NEXT(-1) = 0;

                InvPostingBuffer[1].DELETEALL;

                // Check External Document number
                IF PurchSetup."Ext. Doc. No. Mandatory" OR
                  (GenJnlLineExtDocNo <> '')
                THEN BEGIN
                    VendLedgEntry.RESET;
                    VendLedgEntry.SETCURRENTKEY("External Document No.");
                    VendLedgEntry.SETRANGE("Document Type", GenJnlLineDocType);
                    VendLedgEntry.SETRANGE("External Document No.", GenJnlLineExtDocNo);
                    VendLedgEntry.SETRANGE("Vendor No.", "Pay-to Vendor No.");
                    IF VendLedgEntry.FINDFIRST THEN
                        ERROR(
                          Text016,
                          VendLedgEntry."Document Type", GenJnlLineExtDocNo);
                END;

                // Post vendor entries
                IF GUIALLOWED THEN
                    Window.UPDATE(4, 1);
                GenJnlLine.INIT;
                GenJnlLine."Posting Date" := "Posting Date";
                GenJnlLine."Document Date" := "Document Date";
                GenJnlLine.Description := "Posting Description";
                GenJnlLine."Shortcut Dimension 1 Code" := "Shortcut Dimension 1 Code";
                GenJnlLine."Shortcut Dimension 2 Code" := "Shortcut Dimension 2 Code";
                GenJnlLine."Reason Code" := "Reason Code";
                GenJnlLine."Account Type" := GenJnlLine."Account Type"::Vendor;
                GenJnlLine."Account No." := "Pay-to Vendor No.";
                GenJnlLine."Document Type" := GenJnlLineDocType;
                GenJnlLine."Document No." := GenJnlLineDocNo;
                GenJnlLine."External Document No." := GenJnlLineExtDocNo;
                GenJnlLine."Currency Code" := "Currency Code";
                GenJnlLine.Amount := -TotalPurchLine."Amount Including VAT";
                GenJnlLine."Source Currency Code" := "Currency Code";
                GenJnlLine."Source Currency Amount" := -TotalPurchLine."Amount Including VAT";
                GenJnlLine."Amount (LCY)" := -TotalPurchLineLCY."Amount Including VAT";
                IF PurchHeader."Currency Code" = '' THEN
                    GenJnlLine."Currency Factor" := 1
                ELSE
                    GenJnlLine."Currency Factor" := PurchHeader."Currency Factor";
                GenJnlLine."Sales/Purch. (LCY)" := -TotalPurchLineLCY.Amount;
                GenJnlLine.Correction := Correction;
                GenJnlLine."Inv. Discount (LCY)" := -TotalPurchLineLCY."Inv. Discount Amount";
                GenJnlLine."Sell-to/Buy-from No." := "Buy-from Vendor No.";
                GenJnlLine."Bill-to/Pay-to No." := "Pay-to Vendor No.";
                GenJnlLine."Salespers./Purch. Code" := "Purchaser Code";
                GenJnlLine."System-Created Entry" := TRUE;
                GenJnlLine."On Hold" := "On Hold";
                GenJnlLine."Applies-to Doc. Type" := "Applies-to Doc. Type";
                GenJnlLine."Applies-to Doc. No." := "Applies-to Doc. No.";
                GenJnlLine."Applies-to ID" := "Applies-to ID";
                GenJnlLine."Allow Application" := "Bal. Account No." = '';
                GenJnlLine."Due Date" := "Due Date";
                GenJnlLine."Payment Terms Code" := "Payment Terms Code";
                GenJnlLine."Pmt. Discount Date" := "Pmt. Discount Date";
                GenJnlLine."Payment Discount %" := "Payment Discount %";
                GenJnlLine."Source Type" := GenJnlLine."Source Type"::Vendor;
                GenJnlLine."Source No." := "Pay-to Vendor No.";
                GenJnlLine."Source Code" := SrcCode;
                GenJnlLine."Posting No. Series" := "Posting No. Series";
                GenJnlLine."IC Partner Code" := "Pay-to IC Partner Code";
                //GC++

                CLEAR(PurchHer);
                IF PurchHer.GET(PurchHer."Document Type"::Order, GenJnlLineDocNo) THEN
                    GenJnlLine."Invoice Received Date" := PurchHer."Date Received"
                ELSE
                    IF PurchHer.GET(PurchHer."Document Type"::Invoice, GenJnlLineDocNo) THEN
                        GenJnlLine."Invoice Received Date" := PurchHer."Date Received"
                    ELSE
                        IF PurchHer.GET(PurchHer."Document Type"::"Credit Memo", GenJnlLineDocNo) THEN
                            GenJnlLine."Invoice Received Date" := PurchHer."Date Received";

                //GC--

                //APNT-IC1.0
                IF "IC Transaction No." <> 0 THEN BEGIN
                    GenJnlLine."IC Transaction No." := "IC Transaction No.";
                    GenJnlLine."IC Partner Direction" := "IC Partner Direction";
                END ELSE BEGIN
                    GenJnlLine."IC Transaction No." := ICTransactionNo;
                    GenJnlLine."IC Partner Direction" := ICDirection;
                END;
                //APNT-IC1.0

                //DP6.01.01 START
                IF "Ref. Document No." <> '' THEN BEGIN
                    GenJnlLine."Ref. Document Type" := "Ref. Document Type";
                    GenJnlLine."Ref. Document No." := "Ref. Document No.";
                END;
                //DP6.01.01 STOP

                TempJnlLineDim.DELETEALL;
                TempDocDim.RESET;
                TempDocDim.SETRANGE("Table ID", DATABASE::"Purchase Header");
                DimMgt.CopyDocDimToJnlLineDim(TempDocDim, TempJnlLineDim);
                GenJnlPostLine.RunWithCheck(GenJnlLine, TempJnlLineDim);

                // Balancing account
                IF "Bal. Account No." <> '' THEN BEGIN
                    IF GUIALLOWED THEN
                        Window.UPDATE(5, 1);
                    VendLedgEntry.FINDLAST;
                    GenJnlLine.INIT;
                    GenJnlLine."Posting Date" := "Posting Date";
                    GenJnlLine."Document Date" := "Document Date";
                    GenJnlLine.Description := "Posting Description";
                    GenJnlLine."Shortcut Dimension 1 Code" := "Shortcut Dimension 1 Code";
                    GenJnlLine."Shortcut Dimension 2 Code" := "Shortcut Dimension 2 Code";
                    GenJnlLine."Reason Code" := "Reason Code";
                    GenJnlLine."Account Type" := GenJnlLine."Account Type"::Vendor;
                    GenJnlLine."Account No." := "Pay-to Vendor No.";
                    IF "Document Type" = "Document Type"::"Credit Memo" THEN
                        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Refund
                    ELSE
                        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
                    GenJnlLine."Document No." := GenJnlLineDocNo;
                    GenJnlLine."External Document No." := GenJnlLineExtDocNo;
                    IF "Bal. Account Type" = "Bal. Account Type"::"Bank Account" THEN
                        GenJnlLine."Bal. Account Type" := GenJnlLine."Bal. Account Type"::"Bank Account";
                    GenJnlLine."Bal. Account No." := "Bal. Account No.";
                    GenJnlLine."Currency Code" := "Currency Code";
                    GenJnlLine.Amount := TotalPurchLine."Amount Including VAT" +
                      VendLedgEntry."Remaining Pmt. Disc. Possible";
                    GenJnlLine.Correction := Correction;
                    GenJnlLine."Source Currency Code" := "Currency Code";
                    GenJnlLine."Source Currency Amount" := GenJnlLine.Amount;
                    VendLedgEntry.CALCFIELDS(Amount);
                    IF VendLedgEntry.Amount = 0 THEN
                        GenJnlLine."Amount (LCY)" := TotalPurchLineLCY."Amount Including VAT"
                    ELSE
                        GenJnlLine."Amount (LCY)" :=
                          TotalPurchLineLCY."Amount Including VAT" +
                          ROUND(
                            VendLedgEntry."Remaining Pmt. Disc. Possible" /
                            VendLedgEntry."Adjusted Currency Factor");
                    IF PurchHeader."Currency Code" = '' THEN
                        GenJnlLine."Currency Factor" := 1
                    ELSE
                        GenJnlLine."Currency Factor" := PurchHeader."Currency Factor";
                    GenJnlLine."Applies-to Doc. Type" := GenJnlLineDocType;
                    GenJnlLine."Applies-to Doc. No." := GenJnlLineDocNo;
                    GenJnlLine."Source Type" := GenJnlLine."Source Type"::Vendor;
                    GenJnlLine."Source No." := "Pay-to Vendor No.";
                    GenJnlLine."Source Code" := SrcCode;
                    GenJnlLine."Posting No. Series" := "Posting No. Series";
                    GenJnlLine."IC Partner Code" := "Pay-to IC Partner Code";
                    //APNT-IC1.0
                    IF PurchHeader."IC Transaction No." <> 0 THEN BEGIN
                        GenJnlLine."IC Transaction No." := PurchHeader."IC Transaction No.";
                        GenJnlLine."IC Partner Direction" := PurchHeader."IC Partner Direction";
                    END ELSE BEGIN
                        GenJnlLine."IC Transaction No." := ICTransactionNo;
                        GenJnlLine."IC Partner Direction" := ICDirection;
                    END;
                    //APNT-IC1.0
                    GenJnlLine."Allow Zero-Amount Posting" := TRUE;

                    //DP6.01.01 START
                    IF "Ref. Document No." <> '' THEN BEGIN
                        GenJnlLine."Ref. Document Type" := "Ref. Document Type";
                        GenJnlLine."Ref. Document No." := "Ref. Document No.";
                    END;
                    //DP6.01.01 STOP

                    GenJnlPostLine.RunWithCheck(GenJnlLine, TempJnlLineDim);
                END;
            END;

            IF ICGenJnlLineNo > 0 THEN
                PostICGenJnl;

            InvtSetup.GET;
            IF InvtSetup."Automatic Cost Adjustment" <>
               InvtSetup."Automatic Cost Adjustment"::Never
            THEN BEGIN
                InvtAdjmt.SetProperties(TRUE, InvtSetup."Automatic Cost Posting");
                InvtAdjmt.MakeMultiLevelAdjmt;
            END;

            // Modify/delete purchase header and purchase lines
            IF NOT RECORDLEVELLOCKING THEN BEGIN
                IF WhseReceive THEN
                    WhseRcptLine.LOCKTABLE(TRUE, TRUE);
                IF WhseShip THEN
                    WhseShptLine.LOCKTABLE(TRUE, TRUE);
                DocDim.LOCKTABLE(TRUE, TRUE);
                IF InvtPickPutaway THEN
                    WhseRqst.LOCKTABLE(TRUE, TRUE);
                PurchLine.LOCKTABLE(TRUE, TRUE);
                ItemChargeAssgntPurch.LOCKTABLE(TRUE, TRUE);
            END;

            IF Receive THEN BEGIN
                "Last Receiving No." := "Receiving No.";
                "Receiving No." := '';
            END;
            IF Invoice THEN BEGIN
                "Last Posting No." := "Posting No.";
                "Posting No." := '';
            END;
            IF Ship THEN BEGIN
                "Last Return Shipment No." := "Return Shipment No.";
                "Return Shipment No." := '';
            END;

            IF ("Document Type" IN ["Document Type"::Order, "Document Type"::"Return Order"]) AND
               (NOT EverythingInvoiced)
            THEN BEGIN
                MODIFY;
                InsertTrackingSpecification;

                IF PurchLine.FINDSET THEN
                    REPEAT
                        IF PurchLine.Quantity <> 0 THEN BEGIN
                            IF Receive THEN BEGIN
                                PurchLine."Quantity Received" := PurchLine."Quantity Received" + PurchLine."Qty. to Receive";
                                PurchLine."Qty. Received (Base)" := PurchLine."Qty. Received (Base)" + PurchLine."Qty. to Receive (Base)";
                            END;
                            IF Ship THEN BEGIN
                                PurchLine."Return Qty. Shipped" := PurchLine."Return Qty. Shipped" + PurchLine."Return Qty. to Ship";
                                PurchLine."Return Qty. Shipped (Base)" :=
                                  PurchLine."Return Qty. Shipped (Base)" + PurchLine."Return Qty. to Ship (Base)";
                            END;
                            IF Invoice THEN BEGIN
                                TempPrePmtAmtToDeduct := PurchLine."Prepmt Amt to Deduct";
                                IF "Document Type" = "Document Type"::Order THEN BEGIN
                                    IF ABS(PurchLine."Quantity Invoiced" + PurchLine."Qty. to Invoice") >
                                       ABS(PurchLine."Quantity Received")
                                    THEN BEGIN
                                        PurchLine.VALIDATE("Qty. to Invoice",
                                          PurchLine."Quantity Received" - PurchLine."Quantity Invoiced");
                                        PurchLine."Qty. to Invoice (Base)" :=
                                          PurchLine."Qty. Received (Base)" - PurchLine."Qty. Invoiced (Base)";
                                    END;
                                END ELSE
                                    IF ABS(PurchLine."Quantity Invoiced" + PurchLine."Qty. to Invoice") >
                                       ABS(PurchLine."Return Qty. Shipped")
                                    THEN BEGIN
                                        PurchLine.VALIDATE("Qty. to Invoice",
                                          PurchLine."Return Qty. Shipped" - PurchLine."Quantity Invoiced");
                                        PurchLine."Qty. to Invoice (Base)" :=
                                          PurchLine."Return Qty. Shipped (Base)" - PurchLine."Qty. Invoiced (Base)";
                                    END;

                                PurchLine."Prepmt Amt to Deduct" := TempPrePmtAmtToDeduct;

                                PurchLine."Quantity Invoiced" := PurchLine."Quantity Invoiced" + PurchLine."Qty. to Invoice";
                                PurchLine."Qty. Invoiced (Base)" := PurchLine."Qty. Invoiced (Base)" + PurchLine."Qty. to Invoice (Base)";
                                IF PurchLine."Qty. to Invoice" <> 0 THEN BEGIN
                                    PurchLine."Prepmt Amt Deducted" :=
                                      PurchLine."Prepmt Amt Deducted" + PurchLine."Prepmt Amt to Deduct";
                                    PurchLine."Prepmt VAT Diff. Deducted" :=
                                      PurchLine."Prepmt VAT Diff. Deducted" + PurchLine."Prepmt VAT Diff. to Deduct";
                                    IF "Currency Code" <> '' THEN BEGIN
                                        TempPrePayDeductLCYPurchLine := PurchLine;
                                        IF TempPrePayDeductLCYPurchLine.FIND THEN
                                            PurchLine."Prepmt. Amount Inv. (LCY)" := PurchLine."Prepmt. Amount Inv. (LCY)" -
                                              TempPrePayDeductLCYPurchLine."Prepmt. Amount Inv. (LCY)";
                                    END ELSE
                                        PurchLine."Prepmt. Amount Inv. (LCY)" :=
                                          ROUND(
                                            ROUND(
                                              ROUND(PurchLine."Direct Unit Cost" * (PurchLine.Quantity - PurchLine."Quantity Received"),
                                                Currency."Amount Rounding Precision") *
                                              (1 - PurchLine."Line Discount %" / 100), Currency."Amount Rounding Precision") *
                                            PurchLine."Prepayment %" / 100, Currency."Amount Rounding Precision");
                                    PurchLine."Prepmt Amt to Deduct" :=
                                      PurchLine."Prepmt. Amt. Inv." - PurchLine."Prepmt Amt Deducted";


                                    PurchLine."Prepmt VAT Diff. to Deduct" := 0;
                                END;
                            END;

                            UpdateBlanketOrderLine(PurchLine, Receive, Ship, Invoice);

                            PurchLine.InitOutstanding;

                            IF WhseHandlingRequired OR
                               (PurchSetup."Default Qty. to Ship/Rcv." = PurchSetup."Default Qty. to Ship/Rcv."::Blank)
                            THEN BEGIN
                                IF "Document Type" = "Document Type"::"Return Order" THEN BEGIN
                                    PurchLine."Return Qty. to Ship" := 0;
                                    PurchLine."Return Qty. to Ship (Base)" := 0;
                                END ELSE BEGIN
                                    PurchLine."Qty. to Receive" := 0;
                                    PurchLine."Qty. to Receive (Base)" := 0;
                                END;
                                PurchLine.InitQtyToInvoice;
                            END ELSE BEGIN
                                IF "Document Type" = "Document Type"::"Return Order" THEN
                                    PurchLine.InitQtyToShip
                                ELSE
                                    PurchLine.InitQtyToReceive2;
                            END;
                            PurchLine.SetDefaultQuantity;
                            PurchLine.MODIFY;
                        END;
                    UNTIL PurchLine.NEXT = 0;

                UpdateAssocOrder;
                IF WhseReceive THEN BEGIN
                    WhsePostRcpt.PostUpdateWhseDocuments(WhseRcptHeader);
                    TempWhseRcptHeader.DELETE;
                END;
                IF WhseShip THEN BEGIN
                    WhsePostShpt.PostUpdateWhseDocuments(WhseShptHeader);
                    TempWhseShptHeader.DELETE;
                END;
                WhsePurchRelease.Release(PurchHeader);
                UpdateItemChargeAssgnt;

                IF RoundingLineInserted THEN BEGIN
                    DocDim.RESET;
                    DocDim.SETRANGE("Table ID", DATABASE::"Purchase Line");
                    DocDim.SETRANGE("Document Type", "Document Type");
                    DocDim.SETRANGE("Document No.", "No.");
                    DocDim.SETRANGE("Line No.", RoundingLineNo);
                    DocDim.DELETEALL;
                END;

            END ELSE BEGIN

                CASE "Document Type" OF
                    "Document Type"::Invoice:
                        BEGIN
                            PurchLine.SETFILTER("Receipt No.", '<>%1', '');
                            IF PurchLine.FINDSET THEN
                                REPEAT
                                    IF PurchLine.Type <> PurchLine.Type::" " THEN BEGIN
                                        PurchRcptLine.GET(PurchLine."Receipt No.", PurchLine."Receipt Line No.");
                                        TempPurchLine.GET(
                                          TempPurchLine."Document Type"::Order,
                                          PurchRcptLine."Order No.", PurchRcptLine."Order Line No.");
                                        IF PurchLine.Type = PurchLine.Type::"Charge (Item)" THEN
                                            UpdatePurchOrderChargeAssgnt(PurchLine, TempPurchLine);
                                        TempPurchLine."Quantity Invoiced" :=
                                          TempPurchLine."Quantity Invoiced" + PurchLine."Qty. to Invoice";
                                        TempPurchLine."Qty. Invoiced (Base)" :=
                                          TempPurchLine."Qty. Invoiced (Base)" + PurchLine."Qty. to Invoice (Base)";
                                        IF ABS(TempPurchLine."Quantity Invoiced") > ABS(TempPurchLine."Quantity Received") THEN
                                            ERROR(
                                              Text017,
                                              TempPurchLine."Document No.");
                                        IF TempPurchLine."Sales Order Line No." <> 0 THEN BEGIN // Drop Shipment
                                            SalesOrderLine.GET(
                                              SalesOrderLine."Document Type"::Order,
                                              TempPurchLine."Sales Order No.", TempPurchLine."Sales Order Line No.");
                                            IF ABS(TempPurchLine.Quantity - TempPurchLine."Quantity Invoiced") <
                                               ABS(SalesOrderLine.Quantity - SalesOrderLine."Quantity Invoiced")
                                            THEN
                                                ERROR(
                                                  Text018 +
                                                  Text99000000,
                                                  TempPurchLine."Sales Order No.");
                                        END;
                                        TempPurchLine.InitQtyToInvoice;
                                        TempPurchLine."Prepmt Amt Deducted" := TempPurchLine."Prepmt Amt Deducted" + PurchLine."Prepmt Amt to Deduct";
                                        TempPurchLine."Prepmt VAT Diff. Deducted" :=
                                          TempPurchLine."Prepmt VAT Diff. Deducted" + PurchLine."Prepmt VAT Diff. to Deduct";
                                        IF "Currency Code" <> '' THEN BEGIN
                                            TempPrePayDeductLCYPurchLine := PurchLine;
                                            IF TempPrePayDeductLCYPurchLine.FIND THEN
                                                TempPurchLine."Prepmt. Amount Inv. (LCY)" := TempPurchLine."Prepmt. Amount Inv. (LCY)" -
                                                  TempPrePayDeductLCYPurchLine."Prepmt. Amount Inv. (LCY)";
                                        END ELSE
                                            TempPurchLine."Prepmt. Amount Inv. (LCY)" := TempPurchLine."Prepmt. Amount Inv. (LCY)" -
                                              PurchLine."Prepmt Amt to Deduct";
                                        IF (TempPurchLine."Quantity Invoiced" = TempPurchLine.Quantity) AND
                                          (TempPurchLine."Prepayment %" <> 0) THEN
                                            PrepayRealizeGainLoss(TempPurchLine);
                                        TempPurchLine."Prepmt Amt to Deduct" := TempPurchLine."Prepmt. Amt. Inv." - TempPurchLine."Prepmt Amt Deducted";
                                        TempPurchLine."Prepmt VAT Diff. to Deduct" := 0;
                                        TempPurchLine.InitOutstanding;
                                        TempPurchLine.MODIFY;
                                    END;
                                UNTIL PurchLine.NEXT = 0;
                            InsertTrackingSpecification;

                            PurchLine.SETRANGE("Receipt No.");
                        END;
                    "Document Type"::"Credit Memo":
                        BEGIN
                            PurchLine.SETFILTER("Return Shipment No.", '<>%1', '');
                            IF PurchLine.FINDSET THEN
                                REPEAT
                                    IF PurchLine.Type <> PurchLine.Type::" " THEN BEGIN
                                        ReturnShptLine.GET(PurchLine."Return Shipment No.", PurchLine."Return Shipment Line No.");
                                        TempPurchLine.GET(
                                          TempPurchLine."Document Type"::"Return Order",
                                          ReturnShptLine."Return Order No.", ReturnShptLine."Return Order Line No.");
                                        IF PurchLine.Type = PurchLine.Type::"Charge (Item)" THEN
                                            UpdatePurchOrderChargeAssgnt(PurchLine, TempPurchLine);
                                        TempPurchLine."Quantity Invoiced" :=
                                          TempPurchLine."Quantity Invoiced" + PurchLine."Qty. to Invoice";
                                        TempPurchLine."Qty. Invoiced (Base)" :=
                                          TempPurchLine."Qty. Invoiced (Base)" + PurchLine."Qty. to Invoice (Base)";
                                        IF ABS(TempPurchLine."Quantity Invoiced") > ABS(TempPurchLine."Return Qty. Shipped") THEN
                                            ERROR(
                                              Text041,
                                              TempPurchLine."Document No.");
                                        TempPurchLine.InitQtyToInvoice;
                                        TempPurchLine.InitOutstanding;
                                        TempPurchLine.MODIFY;
                                    END;
                                UNTIL PurchLine.NEXT = 0;
                            InsertTrackingSpecification;

                            PurchLine.SETRANGE("Return Shipment No.");
                        END;
                    ELSE
                        IF PurchLine.FINDSET THEN
                            REPEAT
                                IF (PurchLine."Prepayment %" <> 0) THEN BEGIN
                                    IF "Currency Code" <> '' THEN BEGIN
                                        TempPrePayDeductLCYPurchLine := PurchLine;
                                        IF TempPrePayDeductLCYPurchLine.FIND THEN
                                            PurchLine."Prepmt. Amount Inv. (LCY)" := PurchLine."Prepmt. Amount Inv. (LCY)" -
                                              TempPrePayDeductLCYPurchLine."Prepmt. Amount Inv. (LCY)";
                                    END ELSE
                                        PurchLine."Prepmt. Amount Inv. (LCY)" := PurchLine."Prepmt. Amount Inv. (LCY)" - PurchLine."Prepmt Amt to Deduct";
                                    PrepayRealizeGainLoss(PurchLine);
                                END;
                            UNTIL PurchLine.NEXT = 0;
                END;

                PurchLine.SETFILTER("Blanket Order Line No.", '<>0');
                IF PurchLine.FINDSET THEN
                    REPEAT
                        UpdateBlanketOrderLine(PurchLine, Receive, Ship, Invoice);
                    UNTIL PurchLine.NEXT = 0;
                PurchLine.SETRANGE("Blanket Order Line No.");

                IF WhseReceive THEN BEGIN
                    WhsePostRcpt.PostUpdateWhseDocuments(WhseRcptHeader);
                    TempWhseRcptHeader.DELETE;
                END;
                IF WhseShip THEN BEGIN
                    WhsePostShpt.PostUpdateWhseDocuments(WhseShptHeader);
                    TempWhseShptHeader.DELETE;
                END;

                DocDim.RESET;
                DocDim.SETRANGE("Table ID", DATABASE::"Purchase Header");
                DocDim.SETRANGE("Document Type", "Document Type");
                DocDim.SETRANGE("Document No.", "No.");
                DocDim.DELETEALL;
                DocDim.SETRANGE("Table ID", DATABASE::"Purchase Line");
                DocDim.DELETEALL;

                ApprovalMgt.DeleteApprovalEntry(DATABASE::"Purchase Header", "Document Type", "No.");

                IF HASLINKS THEN DELETELINKS;
                DELETE;

                //LS -
                IF ("Document Type" = "Document Type"::Order) AND (BOUtils.IsOpenToBuyPermitted()) THEN
                    OpenToBuyUtils.ReOpenOrder("No.");
                //LS +

                ReservePurchLine.DeleteInvoiceSpecFromHeader(PurchHeader);
                IF PurchLine.FINDFIRST THEN
                    REPEAT
                        IF PurchLine.HASLINKS THEN
                            PurchLine.DELETELINKS;
                    UNTIL PurchLine.NEXT = 0;
                PurchLine.DELETEALL;
                DeleteItemChargeAssgnt;

                PurchCommentLine.SETRANGE("Document Type", "Document Type");
                PurchCommentLine.SETRANGE("No.", "No.");
                IF NOT PurchCommentLine.ISEMPTY THEN
                    PurchCommentLine.DELETEALL;
                WhseRqst.SETCURRENTKEY("Source Type", "Source Subtype", "Source No.");
                WhseRqst.SETRANGE("Source Type", DATABASE::"Purchase Line");
                WhseRqst.SETRANGE("Source Subtype", "Document Type");
                WhseRqst.SETRANGE("Source No.", "No.");
                IF NOT WhseRqst.ISEMPTY THEN
                    WhseRqst.DELETEALL;

                //LS -
                IF "Document Type" = "Document Type"::Order THEN BEGIN
                    DocGroupLine.RESET;
                    DocGroupLine.SETRANGE("Reference Type", DocGroupLine."Reference Type"::Purchase);
                    DocGroupLine.SETRANGE("Reference No.", "No.");
                    IF NOT DocGroupLine.ISEMPTY THEN
                        DocGroupLine.DELETEALL;
                END;
                //LS +
            END;

            InsertValueEntryRelation;
            //APNT-CO1.0
            IF Invoice THEN
                PostCostSheet(PurchHeader);
            //APNT-CO1.0

            BOUtils.ReplicateUsingRegEntry();  //LS

            IF NOT InvtPickPutaway THEN
                COMMIT;
            CLEAR(WhsePostRcpt);
            CLEAR(WhsePostShpt);
            CLEAR(GenJnlPostLine);
            CLEAR(JobPostLine);
            CLEAR(ItemJnlPostLine);
            CLEAR(WhseJnlPostLine);
            CLEAR(InvtAdjmt);
            IF GUIALLOWED THEN
                Window.CLOSE;
        END;
        UpdateAnalysisView.UpdateAll(0, TRUE);
        UpdateItemAnalysisView.UpdateAll(0, TRUE);

        ICTProcesses.PurchaseDocGLMirror(PurchHeader);  //LS

        //LS -
        IF BOUtils.IsReplenishmentPermitted() THEN
            VendorPerformanceMgt.UpdatePurchaseDoc(PurchHeader);
        //LS +

        Rec := PurchHeader;

    end;

    var
        Text001: Label 'There is nothing to post.';
        Text002: Label 'A drop shipment from a purchase order cannot be received and invoiced at the same time.';
        Text003: Label 'You cannot invoice this purchase order before the associated sales orders have been invoiced. ';
        Text004: Label 'Please invoice sales order %1 before invoicing this purchase order.';
        Text005: Label 'Posting lines              #2######\';
        Text006: Label 'Posting purchases and VAT  #3######\';
        Text007: Label 'Posting to vendors         #4######\';
        Text008: Label 'Posting to bal. account    #5######';
        Text009: Label 'Posting lines         #2######';
        Text010: Label '%1 %2 -> Invoice %3';
        Text011: Label '%1 %2 -> Credit Memo %3';
        Text012: Label 'must have the same sign as the receipt';
        Text014: Label 'Receipt lines have been deleted.';
        Text015: Label 'You cannot purchase resources.';
        Text016: Label 'Purchase %1 %2 already exists for this vendor.';
        Text017: Label 'You cannot invoice order %1 for more than you have received.';
        Text018: Label 'You cannot post this purchase order before the associated sales orders have been invoiced. ';
        Text021: Label 'VAT Amount';
        Text022: Label '%1% VAT';
        Text023: Label 'in the associated blanket order must not be greater than %1';
        Text024: Label 'in the associated blanket order must be reduced.';
        Text025: Label 'Please enter "Yes" in %1 and/or %2 and/or %3.';
        Text026: Label 'Warehouse handling is required for %1 = %2, %3 = %4, %5 = %6.';
        Text028: Label 'must have the same sign as the return shipment';
        Text029: Label 'Line %1 of the return shipment %2, which you are attempting to invoice, has already been invoiced.';
        Text030: Label 'Line %1 of the receipt %2, which you are attempting to invoice, has already been invoiced.';
        Text031: Label 'The quantity you are attempting to invoice is greater than the quantity in receipt %1';
        Text032: Label 'The combination of dimensions used in %1 %2 is blocked. %3';
        Text033: Label 'The combination of dimensions used in %1 %2, line no. %3 is blocked. %4';
        Text034: Label 'The dimensions used in %1 %2 are invalid. %3';
        Text035: Label 'The dimensions used in %1 %2, line no. %3 are invalid. %4';
        Text036: Label 'You cannot assign more than %1 units in %2 = %3,%4 = %5,%6 = %7.';
        Text037: Label 'You must assign all item charges, if you invoice everything.';
        Text038: Label 'You cannot assign item charges to the %1 %2 = %3,%4 = %5, %6 = %7, because it has been invoiced.';
        CurrExchRate: Record "Currency Exchange Rate";
        PurchSetup: Record "Purchases & Payables Setup";
        GLSetup: Record "General Ledger Setup";
        InvtSetup: Record "Inventory Setup";
        GLEntry: Record "G/L Entry";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchLine2: Record "Purchase Line";
        JobPurchLine: Record "Purchase Line";
        TotalPurchLine: Record "Purchase Line";
        TotalPurchLineLCY: Record "Purchase Line";
        TempPurchLine: Record "Purchase Line";
        PurchLineACY: Record "Purchase Line";
        TempPrepmtPurchLine: Record "Purchase Line" temporary;
        CombinedPurchLineTemp: Record "Purchase Line" temporary;
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        ReturnShptHeader: Record "Return Shipment Header";
        ReturnShptLine: Record "Return Shipment Line";
        SalesOrderHeader: Record "Sales Header";
        SalesOrderLine: Record "Sales Line";
        SalesShptHeader: Record "Sales Shipment Header";
        SalesShptLine: Record "Sales Shipment Line";
        ItemChargeAssgntPurch: Record "5805";
        TempItemChargeAssgntPurch: Record "5805" temporary;
        GenJnlLine: Record "Gen. Journal Line";
        ItemJnlLine: Record "Item Journal Line";
        VendPostingGr: Record "Vendor Posting Group";
        SourceCodeSetup: Record "Source Code Setup";
        SourceCode: Record "Source Code";
        PurchCommentLine: Record "Purch. Comment Line";
        PurchCommentLine2: Record "Purch. Comment Line";
        InvPostingBuffer: array[2] of Record "Invt. Posting Buffer" temporary;
        DropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary;
        GenPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        Currency: Record Currency;
        Vend: Record Vendor;
        VendLedgEntry: Record "Vendor Ledger Entry";
        FA: Record "Fixed Asset";
        FASetup: Record "FA Setup";
        DeprBook: Record "Depreciation Book";
        GLAcc: Record "G/L Account";
        DocDim: Record "Document Dimension";
        TempDocDim: Record "Document Dimension" temporary;
        ApprovalEntry: Record "Approval Entry";
        TempApprovalEntry: Record "Approval Entry" temporary;
        PrepmtDocDim: Record "Document Dimension" temporary;
        WhseRqst: Record "5765";
        WhseRcptHeader: Record "7316";
        TempWhseRcptHeader: Record "7316" temporary;
        WhseRcptLine: Record "7317";
        WhseShptHeader: Record "7320";
        TempWhseShptHeader: Record "7320" temporary;
        WhseShptLine: Record "7321";
        PostedWhseRcptHeader: Record "7318";
        PostedWhseRcptLine: Record "7319";
        PostedWhseShptHeader: Record "7322";
        PostedWhseShptLine: Record "7323";
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        TempVATAmountLineRemainder: Record "VAT Amount Line" temporary;
        Location: Record Location;
        TempHandlingSpecification: Record "Tracking Specification" temporary;
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        TempTrackingSpecificationInv: Record "Tracking Specification" temporary;
        TempWhseSplitSpecification: Record "Tracking Specification" temporary;
        TempValueEntryRelation: Record "6508" temporary;
        ReservationEntry2: Record "Reservation Entry";
        ReservationEntry3: Record "Reservation Entry" temporary;
        ItemJnlLine2: Record "Item Journal Line";
        Job: Record Job;
        TempICGenJnlLine: Record "Gen. Journal Line" temporary;
        TempICJnlLineDim: Record "Gen. Journal Line Dimension" temporary;
        TempPrePayDeductLCYPurchLine: Record "Purchase Line" temporary;
        NoSeriesMgt: Codeunit "396";
        GenJnlCheckLine: Codeunit "11";
        GenJnlPostLine: Codeunit "12";
        ItemJnlPostLine: Codeunit "22";
        PurchCalcDisc: Codeunit "70";
        SalesTaxCalculate: Codeunit "398";
        ReservePurchLine: Codeunit "99000834";
        DimMgt: Codeunit "408";
        DimBufMgt: Codeunit "411";
        ApprovalMgt: Codeunit "439";
        WhsePurchRelease: Codeunit "5772";
        SalesPost: Codeunit "80";
        ItemTrackingMgt: Codeunit "6500";
        WMSMgmt: Codeunit "7302";
        WhseJnlPostLine: Codeunit "7301";
        WhsePostRcpt: Codeunit "5760";
        WhsePostShpt: Codeunit "5763";
        ICInOutBoxMgt: Codeunit "427";
        InvtAdjmt: Codeunit "5895";
        CostCalcMgt: Codeunit "5836";
        JobPostLine: Codeunit "1001";
        ReservePurchLine2: Codeunit "99000834";
        ServItemMgt: Codeunit "5920";
        Window: Dialog;
        PostingDate: Date;
        Usedate: Date;
        GenJnlLineDocNo: Code[20];
        GenJnlLineExtDocNo: Code[20];
        SrcCode: Code[10];
        ItemLedgShptEntryNo: Integer;
        LineCount: Integer;
        GenJnlLineDocType: Integer;
        FALineNo: Integer;
        RoundingLineNo: Integer;
        WhseReference: Integer;
        RemQtyToBeInvoiced: Decimal;
        RemQtyToBeInvoicedBase: Decimal;
        QtyToBeInvoiced: Decimal;
        QtyToBeInvoicedBase: Decimal;
        RemAmt: Decimal;
        RemDiscAmt: Decimal;
        EverythingInvoiced: Boolean;
        LastLineRetrieved: Boolean;
        RoundingLineInserted: Boolean;
        DropShipOrder: Boolean;
        PostingDateExists: Boolean;
        ReplacePostingDate: Boolean;
        ReplaceDocumentDate: Boolean;
        ModifyHeader: Boolean;
        TempInvoice: Boolean;
        TempRcpt: Boolean;
        TempReturn: Boolean;
        GLSetupRead: Boolean;
        Text039: Label 'The quantity you are attempting to invoice is greater than the quantity in return shipment %1';
        Text040: Label 'Return shipment lines have been deleted.';
        Text041: Label 'You cannot invoice return order %1 for more than you have shipped.';
        Text99000000: Label 'Post sales order %1 before posting this purchase order.';
        Text042: Label 'Related item ledger entries cannot be found.';
        Text043: Label 'Item Tracking is signed wrongly.';
        Text044: Label 'Item Tracking does not match.';
        Text045: Label 'is not within your range of allowed posting dates.';
        Text046: Label 'The %1 does not match the quantity defined in item tracking.';
        Text047: Label 'cannot be more than %1.';
        Text048: Label 'must be at least %1.';
        Text049: Label 'must be fully preinvoiced before you can ship or invoice %1.';
        ItemChargeAssgntOnly: Boolean;
        ItemJnlRollRndg: Boolean;
        WhseReceive: Boolean;
        WhseShip: Boolean;
        InvtPickPutaway: Boolean;
        ICGenJnlLineNo: Integer;
        Text050: Label 'The total %1 cannot be more than %2.';
        Text051: Label 'The total %1 must be at least %2.';
        Text052: Label 'An unposted invoice for order %1 exists. To avoid duplicate postings, delete order %1 or invoice %2.\Do you still want to post order %1?';
        Text053: Label 'An invoice for order %1 exists in the IC inbox. To avoid duplicate postings, cancel invoice %2 in the IC inbox.\Do you still want to post order %1?';
        Text054: Label 'Posted invoice %1 already exists for order %2. To avoid duplicate postings, do not post order %2.\Do you still want to post order %2?';
        Text055: Label 'Order %1 originates from the same IC transaction as invoice %2. To avoid duplicate postings, delete order %1 or invoice %2.\Do you still want to post invoice %2?';
        Text056: Label 'A document originating from the same IC transaction as document %1 exists in the IC inbox. To avoid duplicate postings, cancel document %2 in the IC inbox.\Do you still want to post document %1?';
        Text057: Label 'Posted invoice %1 originates from the same IC transaction as invoice %2. To avoid duplicate postings, do not post invoice %2.\Do you still want to post invoice %2?';
        Text058: Label 'This is an IC document. If you post this document and the invoice you receive from your IC partner, it will result in duplicate postings.\Are you sure you want to post this document?';
        TotalChargeAmt: Decimal;
        TotalChargeAmtLCY: Decimal;
        TotalChargeAmt2: Decimal;
        TotalChargeAmtLCY2: Decimal;
        Text059: Label 'You must assign item charge %1 if you want to invoice it.';
        Text060: Label 'You can not invoice item charge %1 because there is no item ledger entry to assign it to.';
        LSRetailSetup: Record "10000700";
        ICTProcesses: Codeunit "10001416";
        InStoreMgt: Codeunit "10001320";
        BOUtils: Codeunit "99001452";
        OpenToBuyUtils: Codeunit "10012400";
        ICDirection: Option " ",Outgoing,Incoming;
        ICTransactionNo: Integer;
        Text50001: Label 'Purchase %1 already exists for this vendor.';
        PurchHer: Record "Purchase Header";
        CheckLines: Boolean;
        CompanyInformation: Record "79";

    procedure SetPostingDate(NewReplacePostingDate: Boolean; NewReplaceDocumentDate: Boolean; NewPostingDate: Date)
    begin
        PostingDateExists := TRUE;
        ReplacePostingDate := NewReplacePostingDate;
        ReplaceDocumentDate := NewReplaceDocumentDate;
        PostingDate := NewPostingDate;
    end;

    local procedure PostItemJnlLine(PurchLine: Record "Purchase Line"; QtyToBeReceived: Decimal; QtyToBeReceivedBase: Decimal; QtyToBeInvoiced: Decimal; QtyToBeInvoicedBase: Decimal; ItemLedgShptEntryNo: Integer; ItemChargeNo: Code[20]; TrackingSpecification: Record "Tracking Specification"): Integer
    var
        TempJnlLineDim: Record "Gen. Journal Line Dimension" temporary;
        ItemChargePurchLine: Record "Purchase Line";
        OriginalItemJnlLine: Record "83";
        TempWhseJnlLine: Record "7311" temporary;
        TempWhseTrackingSpecification: Record "Tracking Specification" temporary;
        TempWhseJnlLine2: Record "7311" temporary;
        Factor: Decimal;
        PostWhseJnlLine: Boolean;
        CheckApplToItemEntry: Boolean;
        PostJobConsumptionBeforePurch: Boolean;
        NextReservationEntryNo: Integer;
    begin
        IF NOT ItemJnlRollRndg THEN BEGIN
            RemAmt := 0;
            RemDiscAmt := 0;
        END;
        WITH PurchLine DO BEGIN
            ItemJnlLine.INIT;
            ItemJnlLine."Posting Date" := PurchHeader."Posting Date";
            ItemJnlLine."Document Date" := PurchHeader."Document Date";
            ItemJnlLine."Source Posting Group" := PurchHeader."Vendor Posting Group";
            ItemJnlLine."Salespers./Purch. Code" := PurchHeader."Purchaser Code";
            ItemJnlLine."Country/Region Code" := PurchHeader."Buy-from Country/Region Code";
            ItemJnlLine."Reason Code" := PurchHeader."Reason Code";
            ItemJnlLine."Item No." := "No.";
            ItemJnlLine.Description := Description;
            ItemJnlLine."Shortcut Dimension 1 Code" := "Shortcut Dimension 1 Code";
            ItemJnlLine."Shortcut Dimension 2 Code" := "Shortcut Dimension 2 Code";
            ItemJnlLine."Location Code" := "Location Code";
            ItemJnlLine."Bin Code" := "Bin Code";
            ItemJnlLine."Variant Code" := "Variant Code";
            ItemJnlLine."Item Category Code" := "Item Category Code";
            ItemJnlLine."Product Group Code" := "Product Group Code";
            ItemJnlLine."Inventory Posting Group" := "Posting Group";
            ItemJnlLine."Gen. Bus. Posting Group" := "Gen. Bus. Posting Group";
            ItemJnlLine."Gen. Prod. Posting Group" := "Gen. Prod. Posting Group";
            ItemJnlLine."Serial No." := TrackingSpecification."Serial No.";
            ItemJnlLine."Lot No." := TrackingSpecification."Lot No.";
            //APNT-CO1.0
            ItemJnlLine."Indirect Cost %" := PurchLine."Indirect Cost %";
            //APNT-CO1.0
            //APNT-HRU1.0 -
            ItemJnlLine.ESDI := PurchLine.ESDI;
            //APNT-HRU1.0 +
            ItemJnlLine."Job No." := "Job No.";
            ItemJnlLine."Job Task No." := "Job Task No.";
            IF ItemJnlLine."Job No." <> '' THEN
                ItemJnlLine."Job Purchase" := TRUE;
            ItemJnlLine.Division := Division;  //LS
            ItemJnlLine."Applies-to Entry" := "Appl.-to Item Entry";
            ItemJnlLine."Transaction Type" := "Transaction Type";
            ItemJnlLine."Transport Method" := "Transport Method";
            ItemJnlLine."Entry/Exit Point" := "Entry Point";
            ItemJnlLine.Area := Area;
            ItemJnlLine."Transaction Specification" := "Transaction Specification";
            ItemJnlLine."Drop Shipment" := "Drop Shipment";
            ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::Purchase;
            ItemJnlLine."Prod. Order No." := "Prod. Order No.";
            ItemJnlLine."Prod. Order Line No." := "Prod. Order Line No.";
            ItemJnlLine."Unit of Measure Code" := "Unit of Measure Code";
            ItemJnlLine."Qty. per Unit of Measure" := "Qty. per Unit of Measure";
            ItemJnlLine."Cross-Reference No." := "Cross-Reference No.";
            IF QtyToBeReceived = 0 THEN BEGIN
                IF "Document Type" IN ["Document Type"::"Return Order", "Document Type"::"Credit Memo"] THEN
                    ItemJnlLine."Document Type" := ItemJnlLine."Document Type"::"Purchase Credit Memo"
                ELSE
                    ItemJnlLine."Document Type" := ItemJnlLine."Document Type"::"Purchase Invoice";
                ItemJnlLine."Document No." := GenJnlLineDocNo;
                ItemJnlLine."External Document No." := GenJnlLineExtDocNo;
                ItemJnlLine."Posting No. Series" := PurchHeader."Posting No. Series";
                IF QtyToBeInvoiced <> 0 THEN
                    ItemJnlLine."Invoice No." := GenJnlLineDocNo;
            END ELSE BEGIN
                IF "Document Type" IN ["Document Type"::"Return Order", "Document Type"::"Credit Memo"] THEN BEGIN
                    ItemJnlLine."Document Type" := ItemJnlLine."Document Type"::"Purchase Return Shipment";
                    ItemJnlLine."Document No." := ReturnShptHeader."No.";
                    ItemJnlLine."External Document No." := ReturnShptHeader."Vendor Authorization No.";
                    ItemJnlLine."Posting No. Series" := ReturnShptHeader."No. Series";
                END ELSE BEGIN
                    ItemJnlLine."Document Type" := ItemJnlLine."Document Type"::"Purchase Receipt";
                    ItemJnlLine."Document No." := PurchRcptHeader."No.";
                    ItemJnlLine."External Document No." := PurchRcptHeader."Vendor Shipment No.";
                    ItemJnlLine."Posting No. Series" := PurchRcptHeader."No. Series";
                END;
                IF QtyToBeInvoiced <> 0 THEN BEGIN
                    ItemJnlLine."Invoice No." := GenJnlLineDocNo;
                    ItemJnlLine."External Document No." := GenJnlLineExtDocNo;
                    IF ItemJnlLine."Document No." = '' THEN BEGIN
                        IF "Document Type" = "Document Type"::"Credit Memo" THEN
                            ItemJnlLine."Document Type" := ItemJnlLine."Document Type"::"Purchase Credit Memo"
                        ELSE
                            ItemJnlLine."Document Type" := ItemJnlLine."Document Type"::"Purchase Invoice";
                        ItemJnlLine."Document No." := GenJnlLineDocNo;
                    END;
                    ItemJnlLine."Posting No. Series" := PurchHeader."Posting No. Series";
                END;
            END;

            ItemJnlLine."Document Line No." := "Line No.";
            ItemJnlLine.Quantity := QtyToBeReceived;
            ItemJnlLine."Quantity (Base)" := QtyToBeReceivedBase;
            ItemJnlLine."Invoiced Quantity" := QtyToBeInvoiced;
            ItemJnlLine."Invoiced Qty. (Base)" := QtyToBeInvoicedBase;
            ItemJnlLine."Unit Cost" := "Unit Cost (LCY)";
            ItemJnlLine."Source Currency Code" := PurchHeader."Currency Code";
            ItemJnlLine."Unit Cost (ACY)" := "Unit Cost";
            ItemJnlLine."Value Entry Type" := ItemJnlLine."Value Entry Type"::"Direct Cost";
            IF ItemChargeNo <> '' THEN BEGIN
                ItemJnlLine."Item Charge No." := ItemChargeNo;
                "Qty. to Invoice" := QtyToBeInvoiced;
            END;

            IF QtyToBeInvoiced <> 0 THEN BEGIN
                IF (QtyToBeInvoicedBase <> 0) AND (Type = Type::Item) THEN
                    Factor := QtyToBeInvoicedBase / "Qty. to Invoice (Base)"
                ELSE
                    Factor := QtyToBeInvoiced / "Qty. to Invoice";
                ItemJnlLine.Amount := Amount * Factor + RemAmt;
                IF PurchHeader."Prices Including VAT" THEN
                    ItemJnlLine."Discount Amount" :=
                      ("Line Discount Amount" + "Inv. Discount Amount") / (1 + "VAT %" / 100) * Factor + RemDiscAmt
                ELSE
                    ItemJnlLine."Discount Amount" :=
                      ("Line Discount Amount" + "Inv. Discount Amount") * Factor + RemDiscAmt;
                RemAmt := ItemJnlLine.Amount - ROUND(ItemJnlLine.Amount);
                RemDiscAmt := ItemJnlLine."Discount Amount" - ROUND(ItemJnlLine."Discount Amount");
                ItemJnlLine.Amount := ROUND(ItemJnlLine.Amount);
                ItemJnlLine."Discount Amount" := ROUND(ItemJnlLine."Discount Amount");
            END ELSE BEGIN
                IF PurchHeader."Prices Including VAT" THEN
                    ItemJnlLine.Amount :=
                      (QtyToBeReceived * "Direct Unit Cost" * (1 - PurchLine."Line Discount %" / 100) / (1 + "VAT %" / 100)) + RemAmt
                ELSE
                    ItemJnlLine.Amount :=
                      (QtyToBeReceived * "Direct Unit Cost" * (1 - PurchLine."Line Discount %" / 100)) + RemAmt;
                RemAmt := ItemJnlLine.Amount - ROUND(ItemJnlLine.Amount);
                IF PurchHeader."Currency Code" <> '' THEN
                    ItemJnlLine.Amount :=
                      ROUND(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                          PurchHeader."Posting Date", PurchHeader."Currency Code",
                          ItemJnlLine.Amount, PurchHeader."Currency Factor"))
                ELSE
                    ItemJnlLine.Amount := ROUND(ItemJnlLine.Amount);
            END;

            ItemJnlLine."Source Type" := ItemJnlLine."Source Type"::Vendor;
            ItemJnlLine."Source No." := "Buy-from Vendor No.";
            ItemJnlLine."Invoice-to Source No." := "Pay-to Vendor No.";
            ItemJnlLine."Source Code" := SrcCode;
            ItemJnlLine."Purchasing Code" := "Purchasing Code";

            IF "Prod. Order No." <> '' THEN BEGIN
                ItemJnlLine.Subcontracting := TRUE;
                ItemJnlLine."Quantity (Base)" := CalcBaseQty("No.", "Unit of Measure Code", QtyToBeReceived);
                ItemJnlLine."Invoiced Qty. (Base)" := CalcBaseQty("No.", "Unit of Measure Code", QtyToBeInvoiced);
                ItemJnlLine."Unit Cost" := "Unit Cost" * Quantity / CalcBaseQty("No.", "Unit of Measure Code", Quantity);
                ItemJnlLine."Unit Cost (ACY)" := "Unit Cost";
                ItemJnlLine."Output Quantity (Base)" := ItemJnlLine."Quantity (Base)";
                ItemJnlLine."Output Quantity" := QtyToBeReceived;
                ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::Output;
                ItemJnlLine.Type := ItemJnlLine.Type::"Work Center";
                ItemJnlLine."No." := PurchLine."Work Center No.";
                ItemJnlLine."Routing No." := "Routing No.";
                ItemJnlLine."Routing Reference No." := "Routing Reference No.";
                ItemJnlLine."Operation No." := "Operation No.";
                ItemJnlLine."Work Center No." := "Work Center No.";
                ItemJnlLine."Unit Cost Calculation" := ItemJnlLine."Unit Cost Calculation"::Units;
                IF PurchLine.Finished THEN
                    ItemJnlLine.Finished := PurchLine.Finished;
            END;

            ItemJnlLine."Item Shpt. Entry No." := ItemLedgShptEntryNo;
            ItemJnlLine."Indirect Cost %" := "Indirect Cost %";
            ItemJnlLine."Overhead Rate" := "Overhead Rate";
            ItemJnlLine."Return Reason Code" := "Return Reason Code";

            //LS -
            ItemJnlLine."ICT Source Doc. Type" := PurchHeader."Document Type";
            ItemJnlLine."ICT Source Doc. No." := PurchHeader."No.";
            ItemJnlLine."ICT Source Line No." := PurchLine."Line No.";
            //LS +

            CheckApplToItemEntry :=
              PurchSetup."Exact Cost Reversing Mandatory" AND
              (Type = Type::Item) AND
              (ItemJnlLine.Quantity < 0);

            IF CheckApplToItemEntry THEN
                TESTFIELD("Appl.-to Item Entry");

            IF ("Location Code" <> '') AND
               (Type = Type::Item) AND
               (ItemJnlLine.Quantity <> 0) AND
               NOT ItemJnlLine.Subcontracting
            THEN BEGIN
                GetLocation("Location Code");
                IF (("Document Type" IN ["Document Type"::Invoice, "Document Type"::"Credit Memo"]) AND
                    (Location."Directed Put-away and Pick")) OR
                   (Location."Bin Mandatory" AND NOT (WhseReceive OR WhseShip OR InvtPickPutaway OR "Drop Shipment"))
                THEN BEGIN
                    CreateWhseJnlLine(ItemJnlLine, PurchLine, TempWhseJnlLine);
                    PostWhseJnlLine := TRUE;
                END;
            END;
            ReservationEntry3.DELETEALL;
            CLEAR(ItemJnlLine2);
            ItemJnlLine2 := ItemJnlLine;

            IF "Job No." <> '' THEN BEGIN
                ReservePurchLine2.FindReservEntry(PurchLine, ReservationEntry2);
                IF ReservationEntry2.FIND('-') THEN
                    REPEAT
                        ReservationEntry3 := ReservationEntry2;
                        ReservationEntry3.INSERT;
                    UNTIL ReservationEntry2.NEXT = 0;
            END;

            IF QtyToBeReceivedBase <> 0 THEN BEGIN
                IF "Document Type" IN ["Document Type"::"Return Order", "Document Type"::"Credit Memo"] THEN
                    ReservePurchLine.TransferPurchLineToItemJnlLine(
                      PurchLine, ItemJnlLine, -QtyToBeReceivedBase, CheckApplToItemEntry)
                ELSE
                    ReservePurchLine.TransferPurchLineToItemJnlLine(
                      PurchLine, ItemJnlLine, QtyToBeReceivedBase, CheckApplToItemEntry);

                IF CheckApplToItemEntry THEN
                    TESTFIELD("Appl.-to Item Entry");
            END;

            TempJnlLineDim.DELETEALL;
            TempDocDim.RESET;
            TempDocDim.SETRANGE("Table ID", DATABASE::"Purchase Line");
            TempDocDim.SETRANGE("Line No.", "Line No.");
            DimMgt.CopyDocDimToJnlLineDim(TempDocDim, TempJnlLineDim);
            OriginalItemJnlLine := ItemJnlLine;

            IF "Job No." <> '' THEN BEGIN
                PostJobConsumptionBeforePurch :=
                  (ItemJnlLine."Document Type" = ItemJnlLine."Document Type"::"Purchase Return Shipment") AND (ItemJnlLine.Quantity < 0);
                IF PostJobConsumptionBeforePurch THEN
                    PostItemJrnlLineJobConsumption(PurchLine,
                      NextReservationEntryNo,
                      QtyToBeInvoiced,
                      QtyToBeInvoicedBase,
                      QtyToBeReceived,
                      QtyToBeReceivedBase,
                      CheckApplToItemEntry,
                      TempJnlLineDim);
            END;

            ItemJnlPostLine.RunWithCheck(ItemJnlLine, TempJnlLineDim);

            IF ItemJnlPostLine.CollectTrackingSpecification(TempHandlingSpecification) THEN BEGIN
                IF ItemJnlLine.Subcontracting THEN
                    TempHandlingSpecification.DELETEALL;
                IF TempHandlingSpecification.FIND('-') THEN
                    REPEAT
                        TempTrackingSpecification := TempHandlingSpecification;
                        TempTrackingSpecification."Source Type" := DATABASE::"Purchase Line";
                        TempTrackingSpecification."Source Subtype" := "Document Type";
                        TempTrackingSpecification."Source ID" := "Document No.";
                        TempTrackingSpecification."Source Batch Name" := '';
                        TempTrackingSpecification."Source Prod. Order Line" := 0;
                        TempTrackingSpecification."Source Ref. No." := "Line No.";
                        IF TempTrackingSpecification.INSERT THEN;
                        IF QtyToBeInvoiced <> 0 THEN BEGIN
                            TempTrackingSpecificationInv := TempTrackingSpecification;
                            IF TempTrackingSpecificationInv.INSERT THEN;
                        END;
                        IF PostWhseJnlLine THEN BEGIN
                            TempWhseTrackingSpecification := TempTrackingSpecification;
                            IF TempWhseTrackingSpecification.INSERT THEN;
                        END;
                    UNTIL TempHandlingSpecification.NEXT = 0;
            END;

            IF "Job No." <> '' THEN
                IF NOT PostJobConsumptionBeforePurch THEN
                    PostItemJrnlLineJobConsumption(PurchLine,
                      NextReservationEntryNo,
                      QtyToBeInvoiced,
                      QtyToBeInvoicedBase,
                      QtyToBeReceived,
                      QtyToBeReceivedBase,
                      CheckApplToItemEntry,
                      TempJnlLineDim);

            IF PostWhseJnlLine THEN BEGIN
                ItemTrackingMgt.SplitWhseJnlLine(TempWhseJnlLine, TempWhseJnlLine2, TempWhseTrackingSpecification, FALSE);
                IF TempWhseJnlLine2.FIND('-') THEN
                    REPEAT
                        WhseJnlPostLine.RUN(TempWhseJnlLine2);
                    UNTIL TempWhseJnlLine2.NEXT = 0;
                TempWhseTrackingSpecification.DELETEALL;
            END;

            IF (Type = Type::Item) AND PurchHeader.Invoice THEN BEGIN
                ClearItemChargeAssgntFilter;
                TempItemChargeAssgntPurch.SETCURRENTKEY(
                  "Applies-to Doc. Type", "Applies-to Doc. No.", "Applies-to Doc. Line No.");
                TempItemChargeAssgntPurch.SETRANGE("Applies-to Doc. Type", "Document Type");
                TempItemChargeAssgntPurch.SETRANGE("Applies-to Doc. No.", "Document No.");
                TempItemChargeAssgntPurch.SETRANGE("Applies-to Doc. Line No.", "Line No.");
                IF TempItemChargeAssgntPurch.FIND('-') THEN
                    REPEAT
                        TESTFIELD("Allow Item Charge Assignment");
                        GetItemChargeLine(ItemChargePurchLine);
                        ItemChargePurchLine.CALCFIELDS("Qty. Assigned");
                        IF (ItemChargePurchLine."Qty. to Invoice" <> 0) OR
                           (ABS(ItemChargePurchLine."Qty. Assigned") < ABS(ItemChargePurchLine."Quantity Invoiced"))
                        THEN BEGIN
                            OriginalItemJnlLine."Item Shpt. Entry No." := ItemJnlLine."Item Shpt. Entry No.";
                            PostItemChargePerOrder(OriginalItemJnlLine, ItemChargePurchLine);
                            TempItemChargeAssgntPurch.MARK(TRUE);
                        END;
                    UNTIL TempItemChargeAssgntPurch.NEXT = 0;
            END;
        END;

        EXIT(ItemJnlLine."Item Shpt. Entry No.");
    end;

    local procedure PostItemChargePerOrder(ItemJnlLine2: Record "83"; ItemChargePurchLine: Record "Purchase Line")
    var
        NonDistrItemJnlLine: Record "83";
        TempJnlLineDim: Record "Gen. Journal Line Dimension" temporary;
        OriginalAmt: Decimal;
        OriginalAmtACY: Decimal;
        OriginalDiscountAmt: Decimal;
        OriginalQty: Decimal;
        QtyToInvoice: Decimal;
        Factor: Decimal;
        SignFactor: Integer;
    begin
        WITH TempItemChargeAssgntPurch DO BEGIN
            PurchLine.TESTFIELD("Job No.", '');
            PurchLine.TESTFIELD("Allow Item Charge Assignment", TRUE);
            ItemJnlLine2."Document No." := GenJnlLineDocNo;
            ItemJnlLine2."External Document No." := GenJnlLineExtDocNo;
            ItemJnlLine2."Item Charge No." := "Item Charge No.";
            ItemJnlLine2.Description := ItemChargePurchLine.Description;
            ItemJnlLine2."Document Line No." := ItemChargePurchLine."Line No.";
            ItemJnlLine2."Unit of Measure Code" := '';
            ItemJnlLine2."Qty. per Unit of Measure" := 1;
            IF "Document Type" IN ["Document Type"::"Return Order", "Document Type"::"Credit Memo"] THEN
                QtyToInvoice :=
                  CalcQtyToInvoice(PurchLine."Return Qty. to Ship (Base)", PurchLine."Qty. to Invoice (Base)")
            ELSE
                QtyToInvoice :=
                  CalcQtyToInvoice(PurchLine."Qty. to Receive (Base)", PurchLine."Qty. to Invoice (Base)");
            IF ItemJnlLine2."Invoiced Quantity" = 0 THEN BEGIN
                ItemJnlLine2."Invoiced Quantity" := ItemJnlLine2.Quantity;
                ItemJnlLine2."Invoiced Qty. (Base)" := ItemJnlLine2."Quantity (Base)";
            END;
            ItemJnlLine2.Amount := "Amount to Assign" * ItemJnlLine2."Invoiced Qty. (Base)" / QtyToInvoice;
            IF "Document Type" IN ["Document Type"::"Return Order", "Document Type"::"Credit Memo"] THEN
                ItemJnlLine2.Amount := -ItemJnlLine2.Amount;
            ItemJnlLine2."Unit Cost (ACY)" :=
              ROUND(
                ItemJnlLine2.Amount / ItemJnlLine2."Invoiced Qty. (Base)",
                Currency."Unit-Amount Rounding Precision");

            TotalChargeAmt2 := TotalChargeAmt2 + ItemJnlLine2.Amount;
            IF PurchHeader."Currency Code" <> '' THEN BEGIN
                ItemJnlLine2.Amount :=
                  CurrExchRate.ExchangeAmtFCYToLCY(
                    Usedate, PurchHeader."Currency Code", TotalChargeAmt2 + TotalPurchLine.Amount, PurchHeader."Currency Factor") -
                  TotalChargeAmtLCY2 - TotalPurchLineLCY.Amount;
            END ELSE
                ItemJnlLine2.Amount := TotalChargeAmt2 - TotalChargeAmtLCY2;

            ItemJnlLine2.Amount := ROUND(ItemJnlLine2.Amount);
            TotalChargeAmtLCY2 := TotalChargeAmtLCY2 + ItemJnlLine2.Amount;
            ItemJnlLine2."Unit Cost" := ROUND(
              ItemJnlLine2.Amount / ItemJnlLine2."Invoiced Qty. (Base)", GLSetup."Unit-Amount Rounding Precision");
            ItemJnlLine2."Applies-to Entry" := ItemJnlLine2."Item Shpt. Entry No.";
            ItemJnlLine2."Overhead Rate" := 0;

            IF PurchHeader."Currency Code" <> '' THEN
                ItemJnlLine2."Discount Amount" := ROUND(
                  CurrExchRate.ExchangeAmtFCYToLCY(
                    Usedate, PurchHeader."Currency Code", (ItemChargePurchLine."Inv. Discount Amount" +
                    ItemChargePurchLine."Line Discount Amount") *
                    ItemJnlLine2."Invoiced Qty. (Base)" /
                    ItemChargePurchLine."Quantity (Base)" * "Qty. to Assign" / QtyToInvoice,
                    PurchHeader."Currency Factor"), GLSetup."Amount Rounding Precision")
            ELSE
                ItemJnlLine2."Discount Amount" := ROUND(
                  (ItemChargePurchLine."Line Discount Amount" + ItemChargePurchLine."Inv. Discount Amount") *
                  ItemJnlLine2."Invoiced Qty. (Base)" /
                  ItemChargePurchLine."Quantity (Base)" * "Qty. to Assign" / QtyToInvoice,
                  GLSetup."Amount Rounding Precision");

            ItemJnlLine2."Shortcut Dimension 1 Code" := ItemChargePurchLine."Shortcut Dimension 1 Code";
            ItemJnlLine2."Shortcut Dimension 2 Code" := ItemChargePurchLine."Shortcut Dimension 2 Code";
            ItemJnlLine2."Gen. Prod. Posting Group" := ItemChargePurchLine."Gen. Prod. Posting Group";
            TempJnlLineDim.DELETEALL;
            TempDocDim.RESET;
            TempDocDim.SETRANGE("Table ID", DATABASE::"Purchase Line");
            TempDocDim.SETRANGE("Line No.", "Document Line No.");
            DimMgt.CopyDocDimToJnlLineDim(TempDocDim, TempJnlLineDim);
        END;

        WITH TempTrackingSpecificationInv DO BEGIN
            RESET;
            SETRANGE("Source Type", DATABASE::"Purchase Line");
            SETRANGE("Source ID", TempItemChargeAssgntPurch."Applies-to Doc. No.");
            SETRANGE("Source Ref. No.", TempItemChargeAssgntPurch."Applies-to Doc. Line No.");
            IF ISEMPTY THEN
                ItemJnlPostLine.RunWithCheck(ItemJnlLine2, TempJnlLineDim)
            ELSE BEGIN
                FINDSET;
                NonDistrItemJnlLine := ItemJnlLine2;
                OriginalAmt := NonDistrItemJnlLine.Amount;
                OriginalAmtACY := NonDistrItemJnlLine."Amount (ACY)";
                OriginalDiscountAmt := NonDistrItemJnlLine."Discount Amount";
                OriginalQty := NonDistrItemJnlLine."Quantity (Base)";
                IF ("Quantity (Base)" / OriginalQty) > 0 THEN
                    SignFactor := 1
                ELSE
                    SignFactor := -1;
                REPEAT
                    Factor := "Quantity (Base)" / OriginalQty * SignFactor;
                    IF ABS("Quantity (Base)") < ABS(NonDistrItemJnlLine."Quantity (Base)") THEN BEGIN
                        ItemJnlLine2."Quantity (Base)" := "Quantity (Base)";
                        ItemJnlLine2."Invoiced Qty. (Base)" := ItemJnlLine2."Quantity (Base)";
                        ItemJnlLine2."Amount (ACY)" :=
                          ROUND(OriginalAmtACY * Factor, GLSetup."Amount Rounding Precision");
                        ItemJnlLine2.Amount :=
                          ROUND(OriginalAmt * Factor, GLSetup."Amount Rounding Precision");
                        ItemJnlLine2."Unit Cost (ACY)" :=
                          ROUND(ItemJnlLine2.Amount / ItemJnlLine2."Invoiced Qty. (Base)",
                           Currency."Unit-Amount Rounding Precision") * SignFactor;
                        ItemJnlLine2."Unit Cost" :=
                          ROUND(ItemJnlLine2.Amount / ItemJnlLine2."Invoiced Qty. (Base)",
                           GLSetup."Unit-Amount Rounding Precision") * SignFactor;
                        ItemJnlLine2."Discount Amount" :=
                          ROUND(OriginalDiscountAmt * Factor, GLSetup."Amount Rounding Precision");
                        ItemJnlLine2."Item Shpt. Entry No." := "Appl.-to Item Entry";
                        ItemJnlLine2."Applies-to Entry" := "Appl.-to Item Entry";
                        ItemJnlLine2."Lot No." := "Lot No.";
                        ItemJnlLine2."Serial No." := "Serial No.";
                        ItemJnlPostLine.RunWithCheck(ItemJnlLine2, TempJnlLineDim);
                        ItemJnlLine2."Location Code" := NonDistrItemJnlLine."Location Code";
                        NonDistrItemJnlLine."Quantity (Base)" -= "Quantity (Base)";
                        NonDistrItemJnlLine.Amount -= (ItemJnlLine2.Amount * SignFactor);
                        NonDistrItemJnlLine."Amount (ACY)" -= (ItemJnlLine2."Amount (ACY)" * SignFactor);
                        NonDistrItemJnlLine."Discount Amount" -= (ItemJnlLine2."Discount Amount" * SignFactor);
                    END ELSE BEGIN
                        NonDistrItemJnlLine."Quantity (Base)" := "Quantity (Base)";
                        NonDistrItemJnlLine."Invoiced Qty. (Base)" := "Quantity (Base)";
                        NonDistrItemJnlLine."Unit Cost" :=
                          ROUND(NonDistrItemJnlLine.Amount / NonDistrItemJnlLine."Invoiced Qty. (Base)",
                           GLSetup."Unit-Amount Rounding Precision") * SignFactor;
                        NonDistrItemJnlLine."Unit Cost (ACY)" :=
                          ROUND(NonDistrItemJnlLine.Amount / NonDistrItemJnlLine."Invoiced Qty. (Base)",
                           Currency."Unit-Amount Rounding Precision") * SignFactor;
                        NonDistrItemJnlLine."Item Shpt. Entry No." := "Appl.-to Item Entry";
                        NonDistrItemJnlLine."Applies-to Entry" := "Appl.-to Item Entry";
                        NonDistrItemJnlLine."Lot No." := "Lot No.";
                        NonDistrItemJnlLine."Serial No." := "Serial No.";
                        ItemJnlPostLine.RunWithCheck(NonDistrItemJnlLine, TempJnlLineDim);
                        NonDistrItemJnlLine."Location Code" := ItemJnlLine2."Location Code";
                    END;
                UNTIL NEXT = 0;
            END;
        END;
    end;

    local procedure PostItemChargePerRcpt(PurchLine: Record "Purchase Line")
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        ItemTrackingMgt: Codeunit "6500";
        Factor: Decimal;
        NonDistrQuantity: Decimal;
        NonDistrQtyToAssign: Decimal;
        NonDistrAmountToAssign: Decimal;
        QtyToAssign: Decimal;
        AmountToAssign: Decimal;
        Sign: Decimal;
        DistributeCharge: Boolean;
    begin
        IF NOT PurchRcptLine.GET(
          TempItemChargeAssgntPurch."Applies-to Doc. No.", TempItemChargeAssgntPurch."Applies-to Doc. Line No.") THEN
            ERROR(Text014);
        PurchRcptLine.TESTFIELD("Job No.", '');
        IF PurchRcptLine."Quantity (Base)" > 0 THEN
            Sign := 1
        ELSE
            Sign := -1;

        IF PurchRcptLine."Item Rcpt. Entry No." <> 0 THEN
            DistributeCharge :=
              CostCalcMgt.SplitItemLedgerEntriesExist(
                            TempItemLedgEntry, PurchRcptLine."Quantity (Base)", PurchRcptLine."Item Rcpt. Entry No.")
        ELSE BEGIN
            DistributeCharge := TRUE;
            ItemTrackingMgt.CollectItemEntryRelation(TempItemLedgEntry,
              DATABASE::"Purch. Rcpt. Line", 0, PurchRcptLine."Document No.",
              '', 0, PurchRcptLine."Line No.", PurchRcptLine."Quantity (Base)");
        END;

        IF DistributeCharge THEN
            IF TempItemLedgEntry.FINDSET THEN BEGIN
                NonDistrQuantity := PurchRcptLine."Quantity (Base)";
                NonDistrQtyToAssign := TempItemChargeAssgntPurch."Qty. to Assign";
                NonDistrAmountToAssign := TempItemChargeAssgntPurch."Amount to Assign";
                REPEAT
                    Factor := TempItemLedgEntry.Quantity / NonDistrQuantity;
                    QtyToAssign := NonDistrQtyToAssign * Factor;
                    AmountToAssign := ROUND(NonDistrAmountToAssign * Factor, GLSetup."Amount Rounding Precision");
                    IF Factor < 1 THEN BEGIN
                        PostItemCharge(PurchLine,
                          TempItemLedgEntry."Entry No.", TempItemLedgEntry.Quantity,
                          AmountToAssign * Sign, QtyToAssign, PurchRcptLine."Indirect Cost %");
                        NonDistrQuantity := NonDistrQuantity - TempItemLedgEntry.Quantity;
                        NonDistrQtyToAssign := NonDistrQtyToAssign - QtyToAssign;
                        NonDistrAmountToAssign := NonDistrAmountToAssign - AmountToAssign;
                    END ELSE // the last time
                        PostItemCharge(PurchLine,
                          TempItemLedgEntry."Entry No.", TempItemLedgEntry.Quantity,
                          NonDistrAmountToAssign * Sign, NonDistrQtyToAssign, PurchRcptLine."Indirect Cost %");
                UNTIL TempItemLedgEntry.NEXT = 0;
            END ELSE
                ERROR(Text042)
        ELSE
            PostItemCharge(PurchLine,
              PurchRcptLine."Item Rcpt. Entry No.", PurchRcptLine."Quantity (Base)",
              TempItemChargeAssgntPurch."Amount to Assign" * Sign,
              TempItemChargeAssgntPurch."Qty. to Assign",
              PurchRcptLine."Indirect Cost %");
    end;

    local procedure PostItemChargePerRetShpt(PurchLine: Record "Purchase Line")
    var
        ReturnShptLine: Record "Return Shipment Line";
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        ItemTrackingMgt: Codeunit "6500";
        Factor: Decimal;
        NonDistrQuantity: Decimal;
        NonDistrQtyToAssign: Decimal;
        NonDistrAmountToAssign: Decimal;
        QtyToAssign: Decimal;
        AmountToAssign: Decimal;
        Sign: Decimal;
        DistributeCharge: Boolean;
    begin
        ReturnShptLine.GET(
          TempItemChargeAssgntPurch."Applies-to Doc. No.", TempItemChargeAssgntPurch."Applies-to Doc. Line No.");
        ReturnShptLine.TESTFIELD("Job No.", '');
        CASE PurchLine."Document Type" OF
            PurchLine."Document Type"::Order, PurchLine."Document Type"::Invoice:
                IF PurchLine."Line Amount" > 0 THEN
                    Sign := -1
                ELSE
                    Sign := 1;
            PurchLine."Document Type"::"Return Order", PurchLine."Document Type"::"Credit Memo":
                IF PurchLine."Line Amount" > 0 THEN
                    Sign := 1
                ELSE
                    Sign := -1;
        END;

        IF ReturnShptLine."Item Shpt. Entry No." <> 0 THEN
            DistributeCharge :=
              CostCalcMgt.SplitItemLedgerEntriesExist(
                            TempItemLedgEntry, -ReturnShptLine."Quantity (Base)", ReturnShptLine."Item Shpt. Entry No.")
        ELSE BEGIN
            DistributeCharge := TRUE;
            ItemTrackingMgt.CollectItemEntryRelation(TempItemLedgEntry,
              DATABASE::"Return Shipment Line", 0, ReturnShptLine."Document No.",
              '', 0, ReturnShptLine."Line No.", ReturnShptLine."Quantity (Base)");
        END;

        IF DistributeCharge THEN
            IF TempItemLedgEntry.FINDSET THEN BEGIN
                NonDistrQuantity := -ReturnShptLine."Quantity (Base)";
                NonDistrQtyToAssign := TempItemChargeAssgntPurch."Qty. to Assign";
                NonDistrAmountToAssign := ABS(TempItemChargeAssgntPurch."Amount to Assign");
                REPEAT
                    Factor := TempItemLedgEntry.Quantity / NonDistrQuantity;
                    QtyToAssign := NonDistrQtyToAssign * Factor;
                    AmountToAssign := ROUND(NonDistrAmountToAssign * Factor, GLSetup."Amount Rounding Precision");
                    IF Factor < 1 THEN BEGIN
                        PostItemCharge(PurchLine,
                          TempItemLedgEntry."Entry No.", TempItemLedgEntry.Quantity,
                          AmountToAssign * Sign, QtyToAssign, ReturnShptLine."Indirect Cost %");
                        NonDistrQuantity := NonDistrQuantity - TempItemLedgEntry.Quantity;
                        NonDistrQtyToAssign := NonDistrQtyToAssign - QtyToAssign;
                        NonDistrAmountToAssign := NonDistrAmountToAssign - AmountToAssign;
                    END ELSE // the last time
                        PostItemCharge(PurchLine,
                          TempItemLedgEntry."Entry No.", TempItemLedgEntry.Quantity,
                          NonDistrAmountToAssign * Sign, NonDistrQtyToAssign, ReturnShptLine."Indirect Cost %");
                UNTIL TempItemLedgEntry.NEXT = 0;
            END ELSE
                ERROR(Text042)
        ELSE
            PostItemCharge(PurchLine,
              ReturnShptLine."Item Shpt. Entry No.", -ReturnShptLine."Quantity (Base)",
              ABS(TempItemChargeAssgntPurch."Amount to Assign") * Sign,
              TempItemChargeAssgntPurch."Qty. to Assign",
              ReturnShptLine."Indirect Cost %");
    end;

    local procedure PostItemChargePerTransfer(PurchLine: Record "Purchase Line")
    var
        TransRcptLine: Record "5747";
        ItemApplnEntry: Record "339";
        DummyTrackingSpecification: Record "Tracking Specification";
        TotalAmountToPostFCY: Decimal;
        TotalAmountToPostLCY: Decimal;
        TotalDiscAmountToPost: Decimal;
        AmountToPostFCY: Decimal;
        AmountToPostLCY: Decimal;
        DiscAmountToPost: Decimal;
        RemAmountToPostFCY: Decimal;
        RemAmountToPostLCY: Decimal;
        RemDiscAmountToPost: Decimal;
        CalcAmountToPostFCY: Decimal;
        CalcAmountToPostLCY: Decimal;
        CalcDiscAmountToPost: Decimal;
    begin
        WITH TempItemChargeAssgntPurch DO BEGIN
            TransRcptLine.GET("Applies-to Doc. No.", "Applies-to Doc. Line No.");
            PurchLine."No." := "Item No.";
            PurchLine."Variant Code" := TransRcptLine."Variant Code";
            PurchLine."Location Code" := TransRcptLine."Transfer-to Code";
            PurchLine."Bin Code" := '';
            PurchLine."Line No." := "Document Line No.";

            IF TransRcptLine."Item Rcpt. Entry No." = 0 THEN
                PostItemChargePerITTransfer(PurchLine, TransRcptLine)
            ELSE BEGIN
                TotalAmountToPostFCY := "Amount to Assign";
                IF PurchHeader."Currency Code" <> '' THEN
                    TotalAmountToPostLCY :=
                      CurrExchRate.ExchangeAmtFCYToLCY(
                        Usedate, PurchHeader."Currency Code",
                        TotalAmountToPostFCY, PurchHeader."Currency Factor")
                ELSE
                    TotalAmountToPostLCY := TotalAmountToPostFCY;

                TotalDiscAmountToPost :=
                  ROUND(
                    PurchLine."Inv. Discount Amount" / PurchLine.Quantity * "Qty. to Assign",
                    GLSetup."Amount Rounding Precision");
                TotalDiscAmountToPost :=
                  TotalDiscAmountToPost +
                  ROUND(
                    PurchLine."Line Discount Amount" * ("Qty. to Assign" / PurchLine."Qty. to Invoice"),
                    GLSetup."Amount Rounding Precision");

                TotalAmountToPostLCY := ROUND(TotalAmountToPostLCY, GLSetup."Amount Rounding Precision");

                ItemApplnEntry.SETCURRENTKEY("Outbound Item Entry No.", "Item Ledger Entry No.", "Cost Application");
                ItemApplnEntry.SETRANGE("Outbound Item Entry No.", TransRcptLine."Item Rcpt. Entry No.");
                ItemApplnEntry.SETFILTER("Item Ledger Entry No.", '<>%1', TransRcptLine."Item Rcpt. Entry No.");
                ItemApplnEntry.SETRANGE("Cost Application", TRUE);
                IF ItemApplnEntry.FINDSET THEN BEGIN
                    REPEAT
                        PurchLine."Appl.-to Item Entry" := ItemApplnEntry."Item Ledger Entry No.";
                        CalcAmountToPostFCY :=
                          ((TotalAmountToPostFCY / TransRcptLine."Quantity (Base)") * ItemApplnEntry.Quantity) +
                          RemAmountToPostFCY;
                        AmountToPostFCY := ROUND(CalcAmountToPostFCY);
                        RemAmountToPostFCY := CalcAmountToPostFCY - AmountToPostFCY;
                        CalcAmountToPostLCY :=
                          ((TotalAmountToPostLCY / TransRcptLine."Quantity (Base)") * ItemApplnEntry.Quantity) +
                          RemAmountToPostLCY;
                        AmountToPostLCY := ROUND(CalcAmountToPostLCY);
                        RemAmountToPostLCY := CalcAmountToPostLCY - AmountToPostLCY;
                        CalcDiscAmountToPost :=
                          ((TotalDiscAmountToPost / TransRcptLine."Quantity (Base)") * ItemApplnEntry.Quantity) +
                          RemDiscAmountToPost;
                        DiscAmountToPost := ROUND(CalcDiscAmountToPost);
                        RemDiscAmountToPost := CalcDiscAmountToPost - DiscAmountToPost;
                        PurchLine.Amount := AmountToPostLCY;
                        PurchLine."Inv. Discount Amount" := DiscAmountToPost;
                        PurchLine."Line Discount Amount" := 0;
                        PurchLine."Unit Cost" :=
                          ROUND(AmountToPostFCY / ItemApplnEntry.Quantity, GLSetup."Unit-Amount Rounding Precision");
                        PurchLine."Unit Cost (LCY)" :=
                          ROUND(AmountToPostLCY / ItemApplnEntry.Quantity, GLSetup."Unit-Amount Rounding Precision");
                        IF "Document Type" IN ["Document Type"::"Return Order", "Document Type"::"Credit Memo"] THEN
                            PurchLine.Amount := -PurchLine.Amount;
                        PostItemJnlLine(
                          PurchLine,
                          0, 0,
                          ItemApplnEntry.Quantity, ItemApplnEntry.Quantity,
                          PurchLine."Appl.-to Item Entry", "Item Charge No.", DummyTrackingSpecification);
                    UNTIL ItemApplnEntry.NEXT = 0;
                END;
            END;
        END;
    end;

    local procedure PostItemChargePerITTransfer(PurchLine: Record "Purchase Line"; TransRcptLine: Record "5747")
    var
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        ItemTrackingMgt: Codeunit "6500";
        Factor: Decimal;
        NonDistrQuantity: Decimal;
        NonDistrQtyToAssign: Decimal;
        NonDistrAmountToAssign: Decimal;
        QtyToAssign: Decimal;
        AmountToAssign: Decimal;
    begin
        WITH TempItemChargeAssgntPurch DO BEGIN
            ItemTrackingMgt.CollectItemEntryRelation(TempItemLedgEntry,
              DATABASE::"Transfer Receipt Line", 0, TransRcptLine."Document No.",
              '', 0, TransRcptLine."Line No.", TransRcptLine."Quantity (Base)");
            IF TempItemLedgEntry.FINDSET THEN BEGIN
                NonDistrQuantity := TransRcptLine."Quantity (Base)";
                NonDistrQtyToAssign := TempItemChargeAssgntPurch."Qty. to Assign";
                NonDistrAmountToAssign := TempItemChargeAssgntPurch."Amount to Assign";
                REPEAT
                    Factor := TempItemLedgEntry.Quantity / NonDistrQuantity;
                    QtyToAssign := NonDistrQtyToAssign * Factor;
                    AmountToAssign := ROUND(NonDistrAmountToAssign * Factor, GLSetup."Amount Rounding Precision");
                    IF Factor < 1 THEN BEGIN
                        PostItemCharge(PurchLine,
                          TempItemLedgEntry."Entry No.", TempItemLedgEntry.Quantity,
                          AmountToAssign, QtyToAssign, 0);
                        NonDistrQuantity := NonDistrQuantity - TempItemLedgEntry.Quantity;
                        NonDistrQtyToAssign := NonDistrQtyToAssign - QtyToAssign;
                        NonDistrAmountToAssign := NonDistrAmountToAssign - AmountToAssign;
                    END ELSE // the last time
                        PostItemCharge(PurchLine,
                          TempItemLedgEntry."Entry No.", TempItemLedgEntry.Quantity,
                          NonDistrAmountToAssign, NonDistrQtyToAssign, 0);
                UNTIL TempItemLedgEntry.NEXT = 0;
            END ELSE
                ERROR(Text042);
        END;
    end;

    local procedure PostItemChargePerSalesShpt(PurchLine: Record "Purchase Line")
    var
        SalesShptLine: Record "Sales Shipment Line";
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        ItemTrackingMgt: Codeunit "6500";
        Factor: Decimal;
        NonDistrQuantity: Decimal;
        NonDistrQtyToAssign: Decimal;
        NonDistrAmountToAssign: Decimal;
        QtyToAssign: Decimal;
        AmountToAssign: Decimal;
        Sign: Decimal;
        DistributeCharge: Boolean;
    begin
        IF NOT SalesShptLine.GET(
          TempItemChargeAssgntPurch."Applies-to Doc. No.", TempItemChargeAssgntPurch."Applies-to Doc. Line No.")
        THEN
            ERROR(Text042);
        SalesShptLine.TESTFIELD("Job No.", '');
        IF SalesShptLine."Quantity (Base)" < 0 THEN
            Sign := 1
        ELSE
            Sign := -1;

        IF SalesShptLine."Item Shpt. Entry No." <> 0 THEN
            DistributeCharge :=
              CostCalcMgt.SplitItemLedgerEntriesExist(
                            TempItemLedgEntry, -SalesShptLine."Quantity (Base)", SalesShptLine."Item Shpt. Entry No.")
        ELSE BEGIN
            DistributeCharge := TRUE;
            ItemTrackingMgt.CollectItemEntryRelation(TempItemLedgEntry,
              DATABASE::"Sales Shipment Line", 0, SalesShptLine."Document No.",
              '', 0, SalesShptLine."Line No.", SalesShptLine."Quantity (Base)");
        END;

        IF DistributeCharge THEN
            IF TempItemLedgEntry.FINDSET THEN BEGIN
                NonDistrQuantity := -SalesShptLine."Quantity (Base)";
                NonDistrQtyToAssign := TempItemChargeAssgntPurch."Qty. to Assign";
                NonDistrAmountToAssign := TempItemChargeAssgntPurch."Amount to Assign";
                REPEAT
                    Factor := TempItemLedgEntry.Quantity / NonDistrQuantity;
                    QtyToAssign := NonDistrQtyToAssign * Factor;
                    AmountToAssign := ROUND(NonDistrAmountToAssign * Factor, GLSetup."Amount Rounding Precision");
                    IF Factor < 1 THEN BEGIN
                        PostItemCharge(PurchLine,
                          TempItemLedgEntry."Entry No.", TempItemLedgEntry.Quantity,
                          AmountToAssign * Sign, QtyToAssign, 0);
                        NonDistrQuantity := NonDistrQuantity - TempItemLedgEntry.Quantity;
                        NonDistrQtyToAssign := NonDistrQtyToAssign - QtyToAssign;
                        NonDistrAmountToAssign := NonDistrAmountToAssign - AmountToAssign;
                    END ELSE // the last time
                        PostItemCharge(PurchLine,
                          TempItemLedgEntry."Entry No.", TempItemLedgEntry.Quantity,
                          NonDistrAmountToAssign * Sign, NonDistrQtyToAssign, 0);
                UNTIL TempItemLedgEntry.NEXT = 0;
            END ELSE
                ERROR(Text042)
        ELSE
            PostItemCharge(PurchLine,
              SalesShptLine."Item Shpt. Entry No.", -SalesShptLine."Quantity (Base)",
              TempItemChargeAssgntPurch."Amount to Assign" * Sign,
              TempItemChargeAssgntPurch."Qty. to Assign", 0)
    end;

    procedure PostItemChargePerRetRcpt(PurchLine: Record "Purchase Line")
    var
        ReturnRcptLine: Record "6661";
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        ItemTrackingMgt: Codeunit "6500";
        Factor: Decimal;
        NonDistrQuantity: Decimal;
        NonDistrQtyToAssign: Decimal;
        NonDistrAmountToAssign: Decimal;
        QtyToAssign: Decimal;
        AmountToAssign: Decimal;
        Sign: Decimal;
        DistributeCharge: Boolean;
    begin
        IF NOT ReturnRcptLine.GET(
          TempItemChargeAssgntPurch."Applies-to Doc. No.", TempItemChargeAssgntPurch."Applies-to Doc. Line No.")
        THEN
            ERROR(Text042);
        ReturnRcptLine.TESTFIELD("Job No.", '');
        IF ReturnRcptLine."Quantity (Base)" > 0 THEN
            Sign := 1
        ELSE
            Sign := -1;

        IF ReturnRcptLine."Item Rcpt. Entry No." <> 0 THEN
            DistributeCharge :=
              CostCalcMgt.SplitItemLedgerEntriesExist(
                            TempItemLedgEntry, ReturnRcptLine."Quantity (Base)", ReturnRcptLine."Item Rcpt. Entry No.")
        ELSE BEGIN
            DistributeCharge := TRUE;
            ItemTrackingMgt.CollectItemEntryRelation(TempItemLedgEntry,
              DATABASE::"Return Receipt Line", 0, ReturnRcptLine."Document No.",
              '', 0, ReturnRcptLine."Line No.", ReturnRcptLine."Quantity (Base)");
        END;

        IF DistributeCharge THEN
            IF TempItemLedgEntry.FINDSET THEN BEGIN
                NonDistrQuantity := ReturnRcptLine."Quantity (Base)";
                NonDistrQtyToAssign := TempItemChargeAssgntPurch."Qty. to Assign";
                NonDistrAmountToAssign := TempItemChargeAssgntPurch."Amount to Assign";
                REPEAT
                    Factor := TempItemLedgEntry.Quantity / NonDistrQuantity;
                    QtyToAssign := NonDistrQtyToAssign * Factor;
                    AmountToAssign := ROUND(NonDistrAmountToAssign * Factor, GLSetup."Amount Rounding Precision");
                    IF Factor < 1 THEN BEGIN
                        PostItemCharge(PurchLine,
                          TempItemLedgEntry."Entry No.", TempItemLedgEntry.Quantity,
                          AmountToAssign * Sign, QtyToAssign, 0);
                        NonDistrQuantity := NonDistrQuantity - TempItemLedgEntry.Quantity;
                        NonDistrQtyToAssign := NonDistrQtyToAssign - QtyToAssign;
                        NonDistrAmountToAssign := NonDistrAmountToAssign - AmountToAssign;
                    END ELSE // the last time
                        PostItemCharge(PurchLine,
                          TempItemLedgEntry."Entry No.", TempItemLedgEntry.Quantity,
                          NonDistrAmountToAssign * Sign, NonDistrQtyToAssign, 0);
                UNTIL TempItemLedgEntry.NEXT = 0;
            END ELSE
                ERROR(Text042)
        ELSE
            PostItemCharge(PurchLine,
              ReturnRcptLine."Item Rcpt. Entry No.", ReturnRcptLine."Quantity (Base)",
              TempItemChargeAssgntPurch."Amount to Assign" * Sign,
              TempItemChargeAssgntPurch."Qty. to Assign", 0)
    end;

    local procedure PostAssocItemJnlLine(QtyToBeShipped: Decimal; QtyToBeShippedBase: Decimal): Integer
    var
        TempDocDim2: Record "Document Dimension" temporary;
        TempJnlLineDim: Record "Gen. Journal Line Dimension" temporary;
        TempHandlingSpecification2: Record "Tracking Specification" temporary;
        ItemEntryRelation: Record "6507";
    begin
        SalesOrderHeader.GET(
          SalesOrderHeader."Document Type"::Order,
          PurchLine."Sales Order No.");
        SalesOrderLine.GET(
          SalesOrderLine."Document Type"::Order,
          PurchLine."Sales Order No.", PurchLine."Sales Order Line No.");

        ItemJnlLine.INIT;
        ItemJnlLine."Source Posting Group" := SalesOrderHeader."Customer Posting Group";
        ItemJnlLine."Salespers./Purch. Code" := SalesOrderHeader."Salesperson Code";
        ItemJnlLine."Country/Region Code" := SalesOrderHeader."VAT Country/Region Code";
        ItemJnlLine."Reason Code" := SalesOrderHeader."Reason Code";
        ItemJnlLine."Posting No. Series" := SalesOrderHeader."Posting No. Series";
        ItemJnlLine."Item No." := SalesOrderLine."No.";
        ItemJnlLine.Description := SalesOrderLine.Description;
        ItemJnlLine."Shortcut Dimension 1 Code" := SalesOrderLine."Shortcut Dimension 1 Code";
        ItemJnlLine."Shortcut Dimension 2 Code" := SalesOrderLine."Shortcut Dimension 2 Code";
        ItemJnlLine."Location Code" := SalesOrderLine."Location Code";
        ItemJnlLine."Inventory Posting Group" := SalesOrderLine."Posting Group";
        ItemJnlLine."Gen. Bus. Posting Group" := SalesOrderLine."Gen. Bus. Posting Group";
        ItemJnlLine."Gen. Prod. Posting Group" := SalesOrderLine."Gen. Prod. Posting Group";
        ItemJnlLine."Applies-to Entry" := SalesOrderLine."Appl.-to Item Entry";
        ItemJnlLine."Transaction Type" := SalesOrderLine."Transaction Type";
        ItemJnlLine."Transport Method" := SalesOrderLine."Transport Method";
        ItemJnlLine."Entry/Exit Point" := SalesOrderLine."Exit Point";
        ItemJnlLine.Area := SalesOrderLine.Area;
        ItemJnlLine."Transaction Specification" := SalesOrderLine."Transaction Specification";
        ItemJnlLine."Drop Shipment" := SalesOrderLine."Drop Shipment";
        ItemJnlLine."Posting Date" := PurchHeader."Posting Date";
        ItemJnlLine."Document Date" := PurchHeader."Document Date";
        ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::Sale;
        ItemJnlLine."Document No." := SalesOrderHeader."Shipping No.";
        ItemJnlLine."Document Type" := ItemJnlLine."Document Type"::"Sales Shipment";
        ItemJnlLine."Document Line No." := SalesOrderLine."Line No.";
        ItemJnlLine.Quantity := QtyToBeShipped;
        ItemJnlLine."Quantity (Base)" := QtyToBeShippedBase;
        ItemJnlLine."Invoiced Quantity" := 0;
        ItemJnlLine."Invoiced Qty. (Base)" := 0;
        ItemJnlLine."Unit Cost" := SalesOrderLine."Unit Cost (LCY)";
        ItemJnlLine."Source Currency Code" := PurchHeader."Currency Code";
        ItemJnlLine."Unit Cost (ACY)" := SalesOrderLine."Unit Cost";
        ItemJnlLine."Source Type" := ItemJnlLine."Source Type"::Customer;
        ItemJnlLine."Source No." := SalesOrderLine."Sell-to Customer No.";
        ItemJnlLine."Invoice-to Source No." := SalesOrderLine."Bill-to Customer No.";
        ItemJnlLine."Source Code" := SrcCode;
        ItemJnlLine."Variant Code" := SalesOrderLine."Variant Code";
        ItemJnlLine."Item Category Code" := SalesOrderLine."Item Category Code";
        ItemJnlLine."Product Group Code" := SalesOrderLine."Product Group Code";
        ItemJnlLine."Bin Code" := SalesOrderLine."Bin Code";
        ItemJnlLine."Unit of Measure Code" := SalesOrderLine."Unit of Measure Code";
        ItemJnlLine."Purchasing Code" := SalesOrderLine."Purchasing Code";
        ItemJnlLine."Qty. per Unit of Measure" := SalesOrderLine."Qty. per Unit of Measure";
        ItemJnlLine."Derived from Blanket Order" := SalesOrderLine."Blanket Order No." <> '';
        ItemJnlLine."Applies-to Entry" := ItemLedgShptEntryNo;
        ItemJnlLine.Division := SalesOrderLine.Division;  //LS

        IF SalesOrderLine."Job Contract Entry No." = 0 THEN BEGIN
            TransferReservToItemJnlLine(SalesOrderLine, ItemJnlLine, QtyToBeShippedBase, TRUE);

            //LS -
            IF PurchHeader."Only Two Dimensions" THEN BEGIN
                TempDocDim2.DELETEALL();
                TempDocDim2.INIT();
                TempDocDim2."Table ID" := DATABASE::"Sales Header";
                TempDocDim2."Document Type" := SalesOrderHeader."Document Type";
                TempDocDim2."Document No." := SalesOrderHeader."No.";
                TempDocDim2."Line No." := SalesShptLine."Line No.";
                TempDocDim2."Dimension Code" := GLSetup."Global Dimension 1 Code";
                TempDocDim2."Dimension Value Code" := SalesShptLine."Shortcut Dimension 1 Code";
                IF TempDocDim2."Dimension Value Code" <> '' THEN
                    TempDocDim2.INSERT();
                TempDocDim2."Dimension Code" := GLSetup."Global Dimension 2 Code";
                TempDocDim2."Dimension Value Code" := SalesShptLine."Shortcut Dimension 2 Code";
                IF TempDocDim2."Dimension Value Code" <> '' THEN
                    TempDocDim2.INSERT();
            END ELSE BEGIN
                //LS +
                DocDim.RESET;
                DocDim.SETRANGE("Table ID", DATABASE::"Sales Line");
                DocDim.SETRANGE("Document Type", SalesOrderLine."Document Type");
                DocDim.SETRANGE("Document No.", SalesOrderLine."Document No.");
                DocDim.SETRANGE("Line No.", SalesOrderLine."Line No.");
                IF DocDim.FINDSET THEN
                    REPEAT
                        TempDocDim2.INIT;
                        TempDocDim2 := DocDim;
                        TempDocDim2.INSERT;
                    UNTIL DocDim.NEXT = 0;
            END; //LS

            TempJnlLineDim.DELETEALL;
            DimMgt.CopyDocDimToJnlLineDim(TempDocDim2, TempJnlLineDim);
            ItemJnlPostLine.RunWithCheck(ItemJnlLine, TempJnlLineDim);
            // Handle Item Tracking
            IF ItemJnlPostLine.CollectTrackingSpecification(TempHandlingSpecification2) THEN BEGIN
                IF TempHandlingSpecification2.FINDSET THEN
                    REPEAT
                        TempTrackingSpecification := TempHandlingSpecification2;
                        TempTrackingSpecification."Source Type" := DATABASE::"Sales Line";
                        TempTrackingSpecification."Source Subtype" := SalesOrderLine."Document Type";
                        TempTrackingSpecification."Source ID" := SalesOrderLine."Document No.";
                        TempTrackingSpecification."Source Batch Name" := '';
                        TempTrackingSpecification."Source Prod. Order Line" := 0;
                        TempTrackingSpecification."Source Ref. No." := SalesOrderLine."Line No.";
                        IF TempTrackingSpecification.INSERT THEN;
                        ItemEntryRelation.INIT;
                        ItemEntryRelation."Item Entry No." := TempHandlingSpecification2."Entry No.";
                        ItemEntryRelation."Serial No." := TempHandlingSpecification2."Serial No.";
                        ItemEntryRelation."Lot No." := TempHandlingSpecification2."Lot No.";
                        ItemEntryRelation."Source Type" := DATABASE::"Sales Shipment Line";
                        ItemEntryRelation."Source ID" := SalesOrderHeader."Shipping No.";
                        ItemEntryRelation."Source Ref. No." := SalesOrderLine."Line No.";
                        ItemEntryRelation."Order No." := SalesOrderLine."Document No.";
                        ItemEntryRelation."Order Line No." := SalesOrderLine."Line No.";
                        ItemEntryRelation.INSERT;
                    UNTIL TempHandlingSpecification2.NEXT = 0;
                EXIT(0);
            END;
        END;

        EXIT(ItemJnlLine."Item Shpt. Entry No.");
    end;

    local procedure UpdateAssocOrder()
    var
        ReserveSalesLine: Codeunit "99000832";
    begin
        DropShptPostBuffer.RESET;
        IF DropShptPostBuffer.ISEMPTY THEN
            EXIT;
        IF DropShptPostBuffer.FINDSET THEN BEGIN
            IF NOT SalesOrderLine.RECORDLEVELLOCKING THEN
                SalesOrderLine.LOCKTABLE(TRUE, TRUE);
            REPEAT
                SalesOrderHeader.GET(
                  SalesOrderHeader."Document Type"::Order,
                  DropShptPostBuffer."Order No.");
                SalesOrderHeader."Last Shipping No." := SalesOrderHeader."Shipping No.";
                SalesOrderHeader."Shipping No." := '';
                SalesOrderHeader.MODIFY;
                ReserveSalesLine.UpdateItemTrackingAfterPosting(SalesOrderHeader);
                DropShptPostBuffer.SETRANGE("Order No.", DropShptPostBuffer."Order No.");
                REPEAT
                    SalesOrderLine.GET(
                      SalesOrderLine."Document Type"::Order,
                      DropShptPostBuffer."Order No.", DropShptPostBuffer."Order Line No.");
                    SalesOrderLine."Quantity Shipped" := SalesOrderLine."Quantity Shipped" + DropShptPostBuffer.Quantity;
                    SalesOrderLine."Qty. Shipped (Base)" := SalesOrderLine."Qty. Shipped (Base)" + DropShptPostBuffer."Quantity (Base)";
                    SalesOrderLine.InitOutstanding;
                    SalesOrderLine.InitQtyToShip;
                    SalesOrderLine.MODIFY;
                UNTIL DropShptPostBuffer.NEXT = 0;
                DropShptPostBuffer.SETRANGE("Order No.");
            UNTIL DropShptPostBuffer.NEXT = 0;
            DropShptPostBuffer.DELETEALL;
        END;
    end;

    local procedure FillInvPostingBuffer(PurchLine: Record "Purchase Line"; PurchLineACY: Record "Purchase Line")
    var
        TotalVAT: Decimal;
        TotalVATACY: Decimal;
        TotalAmount: Decimal;
        TotalAmountACY: Decimal;
    begin
        IF (PurchLine."Gen. Bus. Posting Group" <> GenPostingSetup."Gen. Bus. Posting Group") OR
           (PurchLine."Gen. Prod. Posting Group" <> GenPostingSetup."Gen. Prod. Posting Group")
        THEN
            GenPostingSetup.GET(PurchLine."Gen. Bus. Posting Group", PurchLine."Gen. Prod. Posting Group");

        InvPostingBuffer[1].PreparePurchase(PurchLine);

        TempDocDim.SETRANGE("Table ID", DATABASE::"Purchase Line");
        TempDocDim.SETRANGE("Line No.", PurchLine."Line No.");
        TotalVAT := PurchLine."Amount Including VAT" - PurchLine.Amount;
        TotalVATACY := PurchLineACY."Amount Including VAT" - PurchLineACY.Amount;
        TotalAmount := PurchLine.Amount;
        TotalAmountACY := PurchLineACY.Amount;

        IF PurchSetup."Discount Posting" IN
          [PurchSetup."Discount Posting"::"Invoice Discounts", PurchSetup."Discount Posting"::"All Discounts"] THEN BEGIN
            CASE PurchLine."VAT Calculation Type" OF
                PurchLine."VAT Calculation Type"::"Normal VAT", PurchLine."VAT Calculation Type"::"Full VAT":
                    InvPostingBuffer[1].CalcDiscount(
                      PurchHeader."Prices Including VAT",
                      -PurchLine."Inv. Discount Amount",
                      -PurchLineACY."Inv. Discount Amount");
                PurchLine."VAT Calculation Type"::"Reverse Charge VAT":
                    InvPostingBuffer[1].CalcDiscountNoVAT(
                      -PurchLine."Inv. Discount Amount",
                      -PurchLineACY."Inv. Discount Amount");
                PurchLine."VAT Calculation Type"::"Sales Tax":
                    IF NOT PurchLine."Use Tax" THEN // Use Tax is calculated later, based on totals
                        InvPostingBuffer[1].CalcDiscount(
                          PurchHeader."Prices Including VAT",
                          -PurchLine."Inv. Discount Amount",
                          -PurchLineACY."Inv. Discount Amount")
                    ELSE
                        InvPostingBuffer[1].CalcDiscountNoVAT(
                          -PurchLine."Inv. Discount Amount",
                          -PurchLineACY."Inv. Discount Amount");
            END;

            IF PurchLine."VAT Calculation Type" = PurchLine."VAT Calculation Type"::"Sales Tax" THEN
                InvPostingBuffer[1].SetSalesTax(PurchLine);

            IF (InvPostingBuffer[1].Amount <> 0) OR
               (InvPostingBuffer[1]."Amount (ACY)" <> 0)
            THEN BEGIN
                GenPostingSetup.TESTFIELD("Purch. Inv. Disc. Account");
                IF InvPostingBuffer[1].Type = InvPostingBuffer[1].Type::"Fixed Asset" THEN BEGIN
                    IF DeprBook."Subtract Disc. in Purch. Inv." THEN BEGIN
                        GenPostingSetup.TESTFIELD("Purch. FA Disc. Account");
                        InvPostingBuffer[1].SetAccount(
                          PurchLine."No.",
                          TotalVAT,
                          TotalVATACY,
                          TotalAmount,
                          TotalAmountACY);
                        UpdInvPostingBuffer;
                        InvPostingBuffer[1].ReverseAmounts;
                        InvPostingBuffer[1].SetAccount(
                          GenPostingSetup."Purch. FA Disc. Account",
                          TotalVAT,
                          TotalVATACY,
                          TotalAmount,
                          TotalAmountACY);
                        InvPostingBuffer[1].Type := InvPostingBuffer[1].Type::"G/L Account";
                        UpdInvPostingBuffer;
                        InvPostingBuffer[1].ReverseAmounts;
                    END;
                    InvPostingBuffer[1].SetAccount(
                      GenPostingSetup."Purch. Inv. Disc. Account",
                      TotalVAT,
                      TotalVATACY,
                      TotalAmount,
                      TotalAmountACY);
                    InvPostingBuffer[1].Type := InvPostingBuffer[1].Type::"G/L Account";
                    UpdInvPostingBuffer;
                    InvPostingBuffer[1].Type := InvPostingBuffer[1].Type::"Fixed Asset";
                END ELSE BEGIN
                    ;
                    InvPostingBuffer[1].SetAccount(
                      GenPostingSetup."Purch. Inv. Disc. Account",
                      TotalVAT,
                      TotalVATACY,
                      TotalAmount,
                      TotalAmountACY);
                    UpdInvPostingBuffer;
                END;
            END;
        END;

        IF PurchSetup."Discount Posting" IN
          [PurchSetup."Discount Posting"::"Line Discounts", PurchSetup."Discount Posting"::"All Discounts"] THEN BEGIN
            CASE PurchLine."VAT Calculation Type" OF
                PurchLine."VAT Calculation Type"::"Normal VAT", PurchLine."VAT Calculation Type"::"Full VAT":
                    InvPostingBuffer[1].CalcDiscount(
                      PurchHeader."Prices Including VAT",
                      -PurchLine."Line Discount Amount",
                      -PurchLineACY."Line Discount Amount");
                PurchLine."VAT Calculation Type"::"Reverse Charge VAT":
                    InvPostingBuffer[1].CalcDiscountNoVAT(
                      -PurchLine."Line Discount Amount",
                      -PurchLineACY."Line Discount Amount");
                PurchLine."VAT Calculation Type"::"Sales Tax":
                    IF NOT PurchLine."Use Tax" THEN // Use Tax is calculated later, based on totals
                        InvPostingBuffer[1].CalcDiscount(
                          PurchHeader."Prices Including VAT",
                          -PurchLine."Line Discount Amount",
                          -PurchLineACY."Line Discount Amount")
                    ELSE
                        InvPostingBuffer[1].CalcDiscountNoVAT(
                          -PurchLine."Line Discount Amount",
                          -PurchLineACY."Line Discount Amount");
            END;

            IF PurchLine."VAT Calculation Type" = PurchLine."VAT Calculation Type"::"Sales Tax" THEN
                InvPostingBuffer[1].SetSalesTax(PurchLine);

            IF (InvPostingBuffer[1].Amount <> 0) OR
               (InvPostingBuffer[1]."Amount (ACY)" <> 0)
            THEN BEGIN
                GenPostingSetup.TESTFIELD("Purch. Line Disc. Account");
                IF InvPostingBuffer[1].Type = InvPostingBuffer[1].Type::"Fixed Asset" THEN BEGIN
                    IF DeprBook."Subtract Disc. in Purch. Inv." THEN BEGIN
                        GenPostingSetup.TESTFIELD("Purch. FA Disc. Account");
                        InvPostingBuffer[1].SetAccount(
                          PurchLine."No.",
                          TotalVAT,
                          TotalVATACY,
                          TotalAmount,
                          TotalAmountACY);
                        UpdInvPostingBuffer;
                        InvPostingBuffer[1].ReverseAmounts;
                        InvPostingBuffer[1].SetAccount(
                          GenPostingSetup."Purch. FA Disc. Account",
                          TotalVAT,
                          TotalVATACY,
                          TotalAmount,
                          TotalAmountACY);
                        InvPostingBuffer[1].Type := InvPostingBuffer[1].Type::"G/L Account";
                        UpdInvPostingBuffer;
                        InvPostingBuffer[1].ReverseAmounts;
                    END;
                    InvPostingBuffer[1].SetAccount(
                      GenPostingSetup."Purch. Line Disc. Account",
                      TotalVAT,
                      TotalVATACY,
                      TotalAmount,
                      TotalAmountACY);
                    InvPostingBuffer[1].Type := InvPostingBuffer[1].Type::"G/L Account";
                    UpdInvPostingBuffer;
                    InvPostingBuffer[1].Type := InvPostingBuffer[1].Type::"Fixed Asset";
                END ELSE BEGIN
                    ;
                    InvPostingBuffer[1].SetAccount(
                      GenPostingSetup."Purch. Line Disc. Account",
                      TotalVAT,
                      TotalVATACY,
                      TotalAmount,
                      TotalAmountACY);
                    UpdInvPostingBuffer;
                END;
            END;
        END;

        IF PurchLine."VAT Calculation Type" = PurchLine."VAT Calculation Type"::"Reverse Charge VAT" THEN
            InvPostingBuffer[1].SetAmountsNoVAT(
              TotalAmount,
              TotalAmountACY,
              PurchLine."VAT Difference")
        ELSE
            IF (NOT PurchLine."Use Tax") OR (PurchLine."VAT Calculation Type" <> PurchLine."VAT Calculation Type"::"Sales Tax") THEN BEGIN
                InvPostingBuffer[1].SetAmounts(
                  TotalVAT,
                  TotalVATACY,
                  TotalAmount,
                  TotalAmountACY,
                  PurchLine."VAT Difference");
            END ELSE
                InvPostingBuffer[1].SetAmountsNoVAT(
                  TotalAmount,
                  TotalAmountACY,
                  PurchLine."VAT Difference");

        IF PurchLine."VAT Calculation Type" = PurchLine."VAT Calculation Type"::"Sales Tax" THEN
            InvPostingBuffer[1].SetSalesTax(PurchLine);

        IF (PurchLine.Type = PurchLine.Type::"G/L Account") OR (PurchLine.Type = PurchLine.Type::"Fixed Asset") THEN
            InvPostingBuffer[1].SetAccount(
              PurchLine."No.",
              TotalVAT,
              TotalVATACY,
              TotalAmount,
              TotalAmountACY)
        ELSE
            IF PurchLine."Document Type" IN [PurchLine."Document Type"::"Return Order", PurchLine."Document Type"::"Credit Memo"] THEN BEGIN
                GenPostingSetup.TESTFIELD("Purch. Credit Memo Account");
                InvPostingBuffer[1].SetAccount(
                  GenPostingSetup."Purch. Credit Memo Account",
                  TotalVAT,
                  TotalVATACY,
                  TotalAmount,
                  TotalAmountACY);
            END ELSE BEGIN
                GenPostingSetup.TESTFIELD("Purch. Account");
                InvPostingBuffer[1].SetAccount(
                  GenPostingSetup."Purch. Account",
                  TotalVAT,
                  TotalVATACY,
                  TotalAmount,
                  TotalAmountACY);
            END;
        UpdInvPostingBuffer;
    end;

    local procedure UpdInvPostingBuffer()
    var
        TempDimBuf: Record "360" temporary;
        EntryNo: Integer;
    begin
        IF TempDocDim.FINDSET THEN
            REPEAT
                TempDimBuf."Table ID" := TempDocDim."Table ID";
                TempDimBuf."Dimension Code" := TempDocDim."Dimension Code";
                TempDimBuf."Dimension Value Code" := TempDocDim."Dimension Value Code";
                TempDimBuf.INSERT;
            UNTIL TempDocDim.NEXT = 0;
        EntryNo := DimBufMgt.FindDimensions(TempDimBuf);
        IF EntryNo = 0 THEN
            EntryNo := DimBufMgt.InsertDimensions(TempDimBuf);
        InvPostingBuffer[1]."Dimension Entry No." := EntryNo;

        IF InvPostingBuffer[1].Type = InvPostingBuffer[1].Type::"Fixed Asset" THEN BEGIN
            FALineNo := FALineNo + 1;
            InvPostingBuffer[1]."Fixed Asset Line No." := FALineNo;
        END;
        InvPostingBuffer[2] := InvPostingBuffer[1];
        IF InvPostingBuffer[2].FIND THEN BEGIN
            InvPostingBuffer[2].Amount :=
              InvPostingBuffer[2].Amount + InvPostingBuffer[1].Amount;
            InvPostingBuffer[2]."VAT Amount" :=
              InvPostingBuffer[2]."VAT Amount" + InvPostingBuffer[1]."VAT Amount";
            InvPostingBuffer[2]."VAT Base Amount" :=
              InvPostingBuffer[2]."VAT Base Amount" + InvPostingBuffer[1]."VAT Base Amount";
            InvPostingBuffer[2]."VAT Difference" :=
              InvPostingBuffer[2]."VAT Difference" + InvPostingBuffer[1]."VAT Difference";
            InvPostingBuffer[2]."Amount (ACY)" :=
              InvPostingBuffer[2]."Amount (ACY)" + InvPostingBuffer[1]."Amount (ACY)";
            InvPostingBuffer[2]."VAT Amount (ACY)" :=
              InvPostingBuffer[2]."VAT Amount (ACY)" + InvPostingBuffer[1]."VAT Amount (ACY)";
            InvPostingBuffer[2]."VAT Base Amount (ACY)" :=
              InvPostingBuffer[2]."VAT Base Amount (ACY)" +
              InvPostingBuffer[1]."VAT Base Amount (ACY)";
            InvPostingBuffer[2].Quantity :=
              InvPostingBuffer[2].Quantity + InvPostingBuffer[1].Quantity;
            IF NOT InvPostingBuffer[1]."System-Created Entry" THEN
                InvPostingBuffer[2]."System-Created Entry" := FALSE;
            InvPostingBuffer[2].MODIFY;
        END ELSE
            InvPostingBuffer[1].INSERT;
    end;

    local procedure GetCurrency()
    begin
        WITH PurchHeader DO
            IF "Currency Code" = '' THEN
                Currency.InitRoundingPrecision
            ELSE BEGIN
                Currency.GET("Currency Code");
                Currency.TESTFIELD("Amount Rounding Precision");
            END;
    end;

    local procedure DivideAmount(QtyType: Option General,Invoicing,Shipping; PurchLineQty: Decimal)
    begin
        IF RoundingLineInserted AND (RoundingLineNo = PurchLine."Line No.") THEN
            EXIT;
        WITH PurchLine DO
            IF (PurchLineQty = 0) OR ("Direct Unit Cost" = 0) OR ("Line Discount %" = 100) THEN BEGIN
                "Line Amount" := 0;
                "Line Discount Amount" := 0;
                "Inv. Discount Amount" := 0;
                "VAT Base Amount" := 0;
                Amount := 0;
                "Amount Including VAT" := 0;
            END ELSE BEGIN
                TempVATAmountLine.GET(
                  "VAT Identifier", "VAT Calculation Type", "Tax Group Code", "Use Tax",
                  "Line Amount" >= 0);
                IF "VAT Calculation Type" = "VAT Calculation Type"::"Sales Tax" THEN
                    "VAT %" := TempVATAmountLine."VAT %";
                TempVATAmountLineRemainder := TempVATAmountLine;
                IF NOT TempVATAmountLineRemainder.FIND THEN BEGIN
                    TempVATAmountLineRemainder.INIT;
                    TempVATAmountLineRemainder.INSERT;
                END;
                "Line Amount" := ROUND(PurchLineQty * "Direct Unit Cost", Currency."Amount Rounding Precision");
                IF PurchLineQty <> Quantity THEN
                    "Line Discount Amount" :=
                      ROUND("Line Amount" * "Line Discount %" / 100, Currency."Amount Rounding Precision");
                "Line Amount" := "Line Amount" - "Line Discount Amount";

                IF "Allow Invoice Disc." AND (TempVATAmountLine."Inv. Disc. Base Amount" <> 0) THEN
                    IF QtyType = QtyType::Invoicing THEN
                        "Inv. Discount Amount" := "Inv. Disc. Amount to Invoice"
                    ELSE BEGIN
                        TempVATAmountLineRemainder."Invoice Discount Amount" :=
                          TempVATAmountLineRemainder."Invoice Discount Amount" +
                          TempVATAmountLine."Invoice Discount Amount" * "Line Amount" /
                          TempVATAmountLine."Inv. Disc. Base Amount";
                        "Inv. Discount Amount" :=
                          ROUND(
                            TempVATAmountLineRemainder."Invoice Discount Amount", Currency."Amount Rounding Precision");
                        TempVATAmountLineRemainder."Invoice Discount Amount" :=
                          TempVATAmountLineRemainder."Invoice Discount Amount" - "Inv. Discount Amount";
                    END;

                IF PurchHeader."Prices Including VAT" THEN BEGIN
                    IF (TempVATAmountLine."Line Amount" - TempVATAmountLine."Invoice Discount Amount" = 0) OR
                       ("Line Amount" = 0)
                    THEN BEGIN
                        TempVATAmountLineRemainder."VAT Amount" := 0;
                        TempVATAmountLineRemainder."Amount Including VAT" := 0;
                    END ELSE BEGIN
                        TempVATAmountLineRemainder."VAT Amount" :=
                          TempVATAmountLineRemainder."VAT Amount" +
                          TempVATAmountLine."VAT Amount" *
                          ("Line Amount" - "Inv. Discount Amount") /
                          (TempVATAmountLine."Line Amount" - TempVATAmountLine."Invoice Discount Amount");
                        TempVATAmountLineRemainder."Amount Including VAT" :=
                          TempVATAmountLineRemainder."Amount Including VAT" +
                          TempVATAmountLine."Amount Including VAT" *
                          ("Line Amount" - "Inv. Discount Amount") /
                          (TempVATAmountLine."Line Amount" - TempVATAmountLine."Invoice Discount Amount");
                    END;
                    "Amount Including VAT" :=
                      ROUND(TempVATAmountLineRemainder."Amount Including VAT", Currency."Amount Rounding Precision");
                    Amount :=
                      ROUND("Amount Including VAT", Currency."Amount Rounding Precision") -
                      ROUND(TempVATAmountLineRemainder."VAT Amount", Currency."Amount Rounding Precision");
                    "VAT Base Amount" :=
                      ROUND(
                        Amount * (1 - PurchHeader."VAT Base Discount %" / 100), Currency."Amount Rounding Precision");
                    TempVATAmountLineRemainder."Amount Including VAT" :=
                      TempVATAmountLineRemainder."Amount Including VAT" - "Amount Including VAT";
                    TempVATAmountLineRemainder."VAT Amount" :=
                      TempVATAmountLineRemainder."VAT Amount" - "Amount Including VAT" + Amount;
                END ELSE BEGIN
                    IF "VAT Calculation Type" = "VAT Calculation Type"::"Full VAT" THEN BEGIN
                        "Amount Including VAT" := "Line Amount" - "Inv. Discount Amount";
                        Amount := 0;
                        "VAT Base Amount" := 0;
                    END ELSE BEGIN
                        Amount := "Line Amount" - "Inv. Discount Amount";
                        "VAT Base Amount" :=
                          ROUND(
                            Amount * (1 - PurchHeader."VAT Base Discount %" / 100), Currency."Amount Rounding Precision");
                        IF TempVATAmountLine."VAT Base" = 0 THEN
                            TempVATAmountLineRemainder."VAT Amount" := 0
                        ELSE
                            TempVATAmountLineRemainder."VAT Amount" :=
                              TempVATAmountLineRemainder."VAT Amount" +
                              TempVATAmountLine."VAT Amount" *
                            ("Line Amount" - "Inv. Discount Amount") /
                            (TempVATAmountLine."Line Amount" - TempVATAmountLine."Invoice Discount Amount");
                        "Amount Including VAT" :=
                          Amount + ROUND(TempVATAmountLineRemainder."VAT Amount", Currency."Amount Rounding Precision");
                        TempVATAmountLineRemainder."VAT Amount" :=
                          TempVATAmountLineRemainder."VAT Amount" - "Amount Including VAT" + Amount;
                    END;
                END;

                TempVATAmountLineRemainder.MODIFY;
            END;
    end;

    local procedure RoundAmount(PurchLineQty: Decimal)
    var
        NoVAT: Boolean;
    begin
        WITH PurchLine DO BEGIN
            IncrAmount(TotalPurchLine);
            Increment(TotalPurchLine."Net Weight", ROUND(PurchLineQty * "Net Weight", 0.00001));
            Increment(TotalPurchLine."Gross Weight", ROUND(PurchLineQty * "Gross Weight", 0.00001));
            Increment(TotalPurchLine."Unit Volume", ROUND(PurchLineQty * "Unit Volume", 0.00001));
            Increment(TotalPurchLine.Quantity, PurchLineQty);
            IF "Units per Parcel" > 0 THEN
                Increment(
                  TotalPurchLine."Units per Parcel",
                  ROUND(PurchLineQty / "Units per Parcel", 1, '>'));

            TempPurchLine := PurchLine;
            PurchLineACY := PurchLine;
            IF PurchHeader."Currency Code" <> '' THEN BEGIN
                IF ("Document Type" IN ["Document Type"::"Blanket Order", "Document Type"::Quote]) AND
                   (PurchHeader."Posting Date" = 0D)
                THEN
                    Usedate := WORKDATE
                ELSE
                    Usedate := PurchHeader."Posting Date";

                NoVAT := Amount = "Amount Including VAT";
                "Amount Including VAT" :=
                  ROUND(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      Usedate, PurchHeader."Currency Code",
                      TotalPurchLine."Amount Including VAT", PurchHeader."Currency Factor")) -
                        TotalPurchLineLCY."Amount Including VAT";
                IF NoVAT THEN
                    Amount := "Amount Including VAT"
                ELSE
                    Amount :=
                      ROUND(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                          Usedate, PurchHeader."Currency Code",
                          TotalPurchLine.Amount, PurchHeader."Currency Factor")) -
                            TotalPurchLineLCY.Amount;
                "Line Amount" :=
                  ROUND(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      Usedate, PurchHeader."Currency Code",
                      TotalPurchLine."Line Amount", PurchHeader."Currency Factor")) -
                        TotalPurchLineLCY."Line Amount";
                "Line Discount Amount" :=
                  ROUND(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      Usedate, PurchHeader."Currency Code",
                      TotalPurchLine."Line Discount Amount", PurchHeader."Currency Factor")) -
                        TotalPurchLineLCY."Line Discount Amount";
                "Inv. Discount Amount" :=
                  ROUND(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      Usedate, PurchHeader."Currency Code",
                      TotalPurchLine."Inv. Discount Amount", PurchHeader."Currency Factor")) -
                        TotalPurchLineLCY."Inv. Discount Amount";
                "VAT Difference" :=
                  ROUND(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      Usedate, PurchHeader."Currency Code",
                      TotalPurchLine."VAT Difference", PurchHeader."Currency Factor")) -
                        TotalPurchLineLCY."VAT Difference";
            END;

            IncrAmount(TotalPurchLineLCY);
            Increment(TotalPurchLineLCY."Unit Cost (LCY)", ROUND(PurchLineQty * "Unit Cost (LCY)"));
        END;
    end;

    local procedure ReverseAmount(var PurchLine: Record "Purchase Line")
    begin
        WITH PurchLine DO BEGIN
            "Qty. to Receive" := -"Qty. to Receive";
            "Qty. to Receive (Base)" := -"Qty. to Receive (Base)";
            "Return Qty. to Ship" := -"Return Qty. to Ship";
            "Return Qty. to Ship (Base)" := -"Return Qty. to Ship (Base)";
            "Qty. to Invoice" := -"Qty. to Invoice";
            "Qty. to Invoice (Base)" := -"Qty. to Invoice (Base)";
            "Line Amount" := -"Line Amount";
            Amount := -Amount;
            "VAT Base Amount" := -"VAT Base Amount";
            "VAT Difference" := -"VAT Difference";
            "Amount Including VAT" := -"Amount Including VAT";
            "Line Discount Amount" := -"Line Discount Amount";
            "Inv. Discount Amount" := -"Inv. Discount Amount";
            "Salvage Value" := -"Salvage Value";
        END;
    end;

    local procedure InvoiceRounding(UseTempData: Boolean)
    var
        DocDim2: Record "Document Dimension";
        InvoiceRoundingAmount: Decimal;
        NextLineNo: Integer;
        TempDocDim2: Record "Document Dimension" temporary;
        xICTHeader: Record "10000777";
        xItemLedgerEntry: Record "Item Ledger Entry";
        VendorPerformanceMgt: Codeunit "10012211";
    begin
        Currency.TESTFIELD("Invoice Rounding Precision");
        InvoiceRoundingAmount :=
          -ROUND(
            TotalPurchLine."Amount Including VAT" -
            ROUND(
              TotalPurchLine."Amount Including VAT",
              Currency."Invoice Rounding Precision",
              Currency.InvoiceRoundingDirection),
            Currency."Amount Rounding Precision");
        IF InvoiceRoundingAmount <> 0 THEN BEGIN
            VendPostingGr.GET(PurchHeader."Vendor Posting Group");
            VendPostingGr.TESTFIELD("Invoice Rounding Account");
            WITH PurchLine DO BEGIN
                INIT;
                NextLineNo := "Line No." + 10000;
                "System-Created Entry" := TRUE;
                IF UseTempData THEN BEGIN
                    "Line No." := 0;
                    Type := Type::"G/L Account";
                END ELSE BEGIN
                    "Line No." := NextLineNo;
                    VALIDATE(Type, Type::"G/L Account");
                END;
                VALIDATE("No.", VendPostingGr."Invoice Rounding Account");
                VALIDATE(Quantity, 1);
                IF "Document Type" IN ["Document Type"::"Return Order", "Document Type"::"Credit Memo"] THEN
                    VALIDATE(PurchLine."Return Qty. to Ship", Quantity)
                ELSE
                    VALIDATE(PurchLine."Qty. to Receive", Quantity);
                IF PurchHeader."Prices Including VAT" THEN
                    VALIDATE("Direct Unit Cost", InvoiceRoundingAmount)
                ELSE
                    VALIDATE(
                      "Direct Unit Cost",
                      ROUND(
                        InvoiceRoundingAmount /
                        (1 + (1 - PurchHeader."VAT Base Discount %" / 100) * "VAT %" / 100),
                        Currency."Amount Rounding Precision"));
                VALIDATE("Amount Including VAT", InvoiceRoundingAmount);
                "Line No." := NextLineNo;
                IF NOT UseTempData THEN BEGIN
                    //LS -
                    IF PurchHeader."Only Two Dimensions" THEN BEGIN
                        TempDocDim2.RESET();
                        TempDocDim2.DELETEALL();
                        TempDocDim.SETRANGE(TempDocDim."Table ID", DATABASE::"Purchase Header");
                        TempDocDim.SETRANGE(TempDocDim."Line No.", 0);
                        IF TempDocDim.FIND('-') THEN
                            REPEAT
                                TempDocDim2 := TempDocDim;
                                TempDocDim2.INSERT();
                            UNTIL TempDocDim.NEXT() = 0;
                        IF TempDocDim2.FIND('-') THEN
                            REPEAT
                                TempDocDim := TempDocDim2;
                                TempDocDim."Table ID" := DATABASE::"Purchase Line";
                                TempDocDim."Line No." := "Line No.";
                                TempDocDim.INSERT();
                            UNTIL TempDocDim2.NEXT() = 0;
                    END ELSE BEGIN
                        //LS +
                        DocDim2.SETRANGE("Table ID", DATABASE::"Purchase Line");
                        DocDim2.SETRANGE("Document Type", PurchHeader."Document Type");
                        DocDim2.SETRANGE("Document No.", PurchHeader."No.");
                        DocDim2.SETRANGE("Line No.", "Line No.");
                        IF DocDim2.FINDSET THEN
                            REPEAT
                                TempDocDim := DocDim2;
                                TempDocDim.INSERT;
                            UNTIL DocDim2.NEXT = 0;
                    END; //LS
                END;
                LastLineRetrieved := FALSE;
                RoundingLineInserted := TRUE;
                RoundingLineNo := "Line No.";
            END;
        END;
    end;

    local procedure IncrAmount(var TotalPurchLine: Record "Purchase Line")
    begin
        WITH PurchLine DO BEGIN
            IF PurchHeader."Prices Including VAT" OR
               ("VAT Calculation Type" <> "VAT Calculation Type"::"Full VAT")
            THEN
                Increment(TotalPurchLine."Line Amount", "Line Amount");
            Increment(TotalPurchLine.Amount, Amount);
            Increment(TotalPurchLine."VAT Base Amount", "VAT Base Amount");
            Increment(TotalPurchLine."VAT Difference", "VAT Difference");
            Increment(TotalPurchLine."Amount Including VAT", "Amount Including VAT");
            Increment(TotalPurchLine."Line Discount Amount", "Line Discount Amount");
            Increment(TotalPurchLine."Inv. Discount Amount", "Inv. Discount Amount");
            Increment(TotalPurchLine."Inv. Disc. Amount to Invoice", "Inv. Disc. Amount to Invoice");
            Increment(TotalPurchLine."Prepmt. Line Amount", "Prepmt. Line Amount");
            Increment(TotalPurchLine."Prepmt. Amt. Inv.", "Prepmt. Amt. Inv.");
            Increment(TotalPurchLine."Prepmt Amt to Deduct", "Prepmt Amt to Deduct");
            Increment(TotalPurchLine."Prepmt Amt Deducted", "Prepmt Amt Deducted");
            Increment(TotalPurchLine."Prepayment VAT Difference", "Prepayment VAT Difference");
            Increment(TotalPurchLine."Prepmt VAT Diff. to Deduct", "Prepmt VAT Diff. to Deduct");
            Increment(TotalPurchLine."Prepmt VAT Diff. Deducted", "Prepmt VAT Diff. Deducted");
        END;
    end;

    local procedure Increment(var Number: Decimal; Number2: Decimal)
    begin
        Number := Number + Number2;
    end;

    local procedure TestPrepmtAmount()
    var
        RemainingAmount: Decimal;
        RemainingQty: Decimal;
    begin
        WITH PurchLine DO BEGIN
            IF "Prepmt. Line Amount" = 0 THEN
                EXIT;
            IF NOT PurchHeader.Receive AND ("Qty. to Invoice" = Quantity - "Quantity Invoiced") THEN BEGIN
                IF "Qty. Rcd. Not Invoiced" + "Quantity Received" = Quantity THEN
                    RemainingAmount := 0
                ELSE BEGIN
                    RemainingQty := "Qty. to Receive";
                    RemainingAmount :=
                      ROUND(RemainingQty * "Direct Unit Cost" * (1 - "Line Discount %" / 100), Currency."Amount Rounding Precision");
                END;
            END ELSE BEGIN
                IF "Qty. to Invoice" + "Quantity Invoiced" = Quantity THEN
                    RemainingAmount := 0
                ELSE BEGIN
                    RemainingQty := Quantity - "Qty. to Invoice" - "Quantity Invoiced";
                    RemainingAmount :=
                      ROUND(RemainingQty * "Direct Unit Cost" * (1 - "Line Discount %" / 100), Currency."Amount Rounding Precision");
                END;
            END;
            IF RemainingAmount < "Prepmt. Line Amount" - "Prepmt Amt to Deduct" - "Prepmt Amt Deducted" THEN
                FIELDERROR("Prepmt. Line Amount", STRSUBSTNO(Text049, "Qty. to Invoice"));
        END;
    end;

    procedure GetPurchLines(var NewPurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; QtyType: Option General,Invoicing,Shipping)
    var
        OldPurchLine: Record "Purchase Line";
        MergedPurchLines: Record "Purchase Line" temporary;
    begin
        PurchHeader := NewPurchHeader;
        IF QtyType = QtyType::Invoicing THEN BEGIN
            CreatePrepmtLines(PurchHeader, TempPrepmtPurchLine, PrepmtDocDim, FALSE);
            MergePurchLines(PurchHeader, OldPurchLine, TempPrepmtPurchLine, MergedPurchLines);
            SumPurchLines2(PurchLine, MergedPurchLines, QtyType, TRUE);
        END ELSE
            SumPurchLines2(PurchLine, OldPurchLine, QtyType, TRUE);
    end;

    procedure SumPurchLines(var NewPurchHeader: Record "Purchase Header"; QtyType: Option General,Invoicing,Shipping; var NewTotalPurchLine: Record "Purchase Line"; var NewTotalPurchLineLCY: Record "Purchase Line"; var VATAmount: Decimal; var VATAmountText: Text[30])
    var
        OldPurchLine: Record "Purchase Line";
    begin
        SumPurchLinesTemp(
          NewPurchHeader, OldPurchLine, QtyType, NewTotalPurchLine, NewTotalPurchLineLCY,
          VATAmount, VATAmountText);
    end;

    procedure SumPurchLinesTemp(var NewPurchHeader: Record "Purchase Header"; var OldPurchLine: Record "Purchase Line"; QtyType: Option General,Invoicing,Shipping; var NewTotalPurchLine: Record "Purchase Line"; var NewTotalPurchLineLCY: Record "Purchase Line"; var VATAmount: Decimal; var VATAmountText: Text[30])
    var
        PurchLine: Record "Purchase Line";
    begin
        WITH PurchHeader DO BEGIN
            PurchHeader := NewPurchHeader;
            SumPurchLines2(PurchLine, OldPurchLine, QtyType, FALSE);
            VATAmount := TotalPurchLine."Amount Including VAT" - TotalPurchLine.Amount;
            IF TotalPurchLine."VAT %" = 0 THEN
                VATAmountText := Text021
            ELSE
                VATAmountText := STRSUBSTNO(Text022, TotalPurchLine."VAT %");
            NewTotalPurchLine := TotalPurchLine;
            NewTotalPurchLineLCY := TotalPurchLineLCY;
        END;
    end;

    local procedure SumPurchLines2(var NewPurchLine: Record "Purchase Line"; var OldPurchLine: Record "Purchase Line"; QtyType: Option General,Invoicing,Shipping; InsertPurchLine: Boolean)
    var
        PurchLineQty: Decimal;
    begin
        TempVATAmountLineRemainder.DELETEALL;
        OldPurchLine.CalcVATAmountLines(QtyType, PurchHeader, OldPurchLine, TempVATAmountLine);
        WITH PurchHeader DO BEGIN
            GetGLSetup;
            PurchSetup.GET;
            GetCurrency;
            OldPurchLine.SETRANGE("Document Type", "Document Type");
            OldPurchLine.SETRANGE("Document No.", "No.");
            RoundingLineInserted := FALSE;
            IF OldPurchLine.FINDSET THEN
                REPEAT
                    IF NOT RoundingLineInserted THEN
                        PurchLine := OldPurchLine;
                    CASE QtyType OF
                        QtyType::General:
                            PurchLineQty := PurchLine.Quantity;
                        QtyType::Invoicing:
                            PurchLineQty := PurchLine."Qty. to Invoice";
                        QtyType::Shipping:
                            BEGIN
                                IF "Document Type" IN ["Document Type"::"Return Order", "Document Type"::"Credit Memo"] THEN
                                    PurchLineQty := PurchLine."Return Qty. to Ship"
                                ELSE
                                    PurchLineQty := PurchLine."Qty. to Receive"
                            END;
                    END;
                    DivideAmount(QtyType, PurchLineQty);
                    PurchLine.Quantity := PurchLineQty;
                    IF PurchLineQty <> 0 THEN BEGIN
                        IF (PurchLine.Amount <> 0) AND NOT RoundingLineInserted THEN
                            IF TotalPurchLine.Amount = 0 THEN
                                TotalPurchLine."VAT %" := PurchLine."VAT %"
                            ELSE
                                IF TotalPurchLine."VAT %" <> PurchLine."VAT %" THEN
                                    TotalPurchLine."VAT %" := 0;
                        RoundAmount(PurchLineQty);
                        PurchLine := TempPurchLine;
                    END;
                    IF InsertPurchLine THEN BEGIN
                        NewPurchLine := PurchLine;
                        NewPurchLine.INSERT;
                    END;
                    IF RoundingLineInserted THEN
                        LastLineRetrieved := TRUE
                    ELSE BEGIN
                        LastLineRetrieved := OldPurchLine.NEXT = 0;
                        IF LastLineRetrieved AND PurchSetup."Invoice Rounding" THEN
                            InvoiceRounding(TRUE);
                    END;
                UNTIL LastLineRetrieved;
        END;
    end;

    procedure TestDeleteHeader(PurchHeader: Record "Purchase Header"; var PurchRcptHeader: Record "Purch. Rcpt. Header"; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHeader: Record "124"; var ReturnShptHeader: Record "6650"; var PurchInvHeaderPrepmt: Record "Purch. Inv. Header"; var PurchCrMemoHeaderPrepmt: Record "124")
    begin
        WITH PurchHeader DO BEGIN
            CLEAR(PurchRcptHeader);
            CLEAR(PurchInvHeader);
            CLEAR(PurchCrMemoHeader);
            CLEAR(ReturnShptHeader);
            PurchSetup.GET;

            SourceCodeSetup.GET;
            SourceCodeSetup.TESTFIELD("Deleted Document");
            SourceCode.GET(SourceCodeSetup."Deleted Document");

            IF ("Receiving No. Series" <> '') AND ("Receiving No." <> '') THEN BEGIN
                PurchRcptHeader.TRANSFERFIELDS(PurchHeader);
                PurchRcptHeader."No." := "Receiving No.";
                PurchRcptHeader."Posting Date" := TODAY;
                PurchRcptHeader."User ID" := USERID;
                PurchRcptHeader."Source Code" := SourceCode.Code;
            END;

            IF ("Return Shipment No. Series" <> '') AND ("Return Shipment No." <> '') THEN BEGIN
                ReturnShptHeader.TRANSFERFIELDS(PurchHeader);
                ReturnShptHeader."No." := "Return Shipment No.";
                ReturnShptHeader."Posting Date" := TODAY;
                ReturnShptHeader."User ID" := USERID;
                ReturnShptHeader."Source Code" := SourceCode.Code;
            END;

            IF ("Posting No. Series" <> '') AND
               (("Document Type" IN ["Document Type"::Order, "Document Type"::Invoice]) AND
                ("Posting No." <> '') OR
                ("Document Type" = "Document Type"::Invoice) AND
                ("No. Series" = "Posting No. Series"))
            THEN BEGIN
                PurchInvHeader.TRANSFERFIELDS(PurchHeader);
                IF "Posting No." <> '' THEN
                    PurchInvHeader."No." := "Posting No.";
                IF "Document Type" = "Document Type"::Invoice THEN BEGIN
                    PurchInvHeader."Pre-Assigned No. Series" := "No. Series";
                    PurchInvHeader."Pre-Assigned No." := "No.";
                END ELSE BEGIN
                    PurchInvHeader."Pre-Assigned No. Series" := '';
                    PurchInvHeader."Pre-Assigned No." := '';
                    PurchInvHeader."Order No. Series" := "No. Series";
                    PurchInvHeader."Order No." := "No.";
                END;
                PurchInvHeader."Posting Date" := TODAY;
                PurchInvHeader."User ID" := USERID;
                PurchInvHeader."Source Code" := SourceCode.Code;
            END;

            IF ("Posting No. Series" <> '') AND
               (("Document Type" IN ["Document Type"::"Return Order", "Document Type"::"Credit Memo"]) AND
                ("Posting No." <> '') OR
                ("Document Type" = "Document Type"::"Credit Memo") AND
                ("No. Series" = "Posting No. Series"))
            THEN BEGIN
                PurchCrMemoHeader.TRANSFERFIELDS(PurchHeader);
                IF "Posting No." <> '' THEN
                    PurchCrMemoHeader."No." := "Posting No.";
                PurchCrMemoHeader."Pre-Assigned No. Series" := "No. Series";
                PurchCrMemoHeader."Pre-Assigned No." := "No.";
                PurchCrMemoHeader."Posting Date" := TODAY;
                PurchCrMemoHeader."User ID" := USERID;
                PurchCrMemoHeader."Source Code" := SourceCode.Code;
            END;

            IF ("Prepayment No. Series" <> '') AND ("Prepayment No." <> '') THEN BEGIN
                TESTFIELD("Document Type", "Document Type"::Order);
                PurchInvHeaderPrepmt.TRANSFERFIELDS(PurchHeader);
                PurchInvHeaderPrepmt."No." := "Prepayment No.";
                PurchInvHeaderPrepmt."Order No. Series" := "No. Series";
                PurchInvHeaderPrepmt."Prepayment Order No." := "No.";
                PurchInvHeaderPrepmt."Posting Date" := TODAY;
                PurchInvHeaderPrepmt."Pre-Assigned No. Series" := '';
                PurchInvHeaderPrepmt."Pre-Assigned No." := '';
                PurchInvHeaderPrepmt."User ID" := USERID;
                PurchInvHeaderPrepmt."Source Code" := SourceCode.Code;
                PurchInvHeaderPrepmt."Prepayment Invoice" := TRUE;
            END;

            IF ("Prepmt. Cr. Memo No. Series" <> '') AND ("Prepmt. Cr. Memo No." <> '') THEN BEGIN
                TESTFIELD("Document Type", "Document Type"::Order);
                PurchCrMemoHeaderPrepmt.TRANSFERFIELDS(PurchHeader);
                PurchCrMemoHeaderPrepmt."No." := "Prepmt. Cr. Memo No.";
                PurchCrMemoHeaderPrepmt."Prepayment Order No." := "No.";
                PurchCrMemoHeaderPrepmt."Posting Date" := TODAY;
                PurchCrMemoHeaderPrepmt."Pre-Assigned No. Series" := '';
                PurchCrMemoHeaderPrepmt."Pre-Assigned No." := '';
                PurchCrMemoHeaderPrepmt."User ID" := USERID;
                PurchCrMemoHeaderPrepmt."Source Code" := SourceCode.Code;
                PurchCrMemoHeaderPrepmt."Prepayment Credit Memo" := TRUE;
            END;
        END;
    end;

    procedure DeleteHeader(PurchHeader: Record "Purchase Header"; var PurchRcptHeader: Record "Purch. Rcpt. Header"; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHeader: Record "124"; var ReturnShptHeader: Record "6650"; var PurchInvHeaderPrepmt: Record "Purch. Inv. Header"; var PurchCrMemoHeaderPrepmt: Record "124")
    begin
        WITH PurchHeader DO BEGIN
            TestDeleteHeader(
              PurchHeader, PurchRcptHeader, PurchInvHeader, PurchCrMemoHeader,
              ReturnShptHeader, PurchInvHeaderPrepmt, PurchCrMemoHeaderPrepmt);
            IF PurchRcptHeader."No." <> '' THEN BEGIN
                PurchRcptHeader.INSERT;
                PurchRcptLine.INIT;
                PurchRcptLine."Document No." := PurchRcptHeader."No.";
                PurchRcptLine."Line No." := 10000;
                PurchRcptLine.Description := SourceCode.Description;
                PurchRcptLine.INSERT;
            END;

            IF ReturnShptHeader."No." <> '' THEN BEGIN
                ReturnShptHeader.INSERT;
                ReturnShptLine.INIT;
                ReturnShptLine."Document No." := ReturnShptHeader."No.";
                ReturnShptLine."Line No." := 10000;
                ReturnShptLine.Description := SourceCode.Description;
                ReturnShptLine.INSERT;
            END;

            IF PurchInvHeader."No." <> '' THEN BEGIN
                PurchInvHeader.INSERT;
                PurchInvLine.INIT;
                PurchInvLine."Document No." := PurchInvHeader."No.";
                PurchInvLine."Line No." := 10000;
                PurchInvLine.Description := SourceCode.Description;
                PurchInvLine.INSERT;
            END;

            IF PurchCrMemoHeader."No." <> '' THEN BEGIN
                PurchCrMemoHeader.INSERT(TRUE);
                PurchCrMemoLine.INIT;
                PurchCrMemoLine."Document No." := PurchCrMemoHeader."No.";
                PurchCrMemoLine."Line No." := 10000;
                PurchCrMemoLine.Description := SourceCode.Description;
                PurchCrMemoLine.INSERT;
            END;

            IF PurchInvHeaderPrepmt."No." <> '' THEN BEGIN
                PurchInvHeaderPrepmt.INSERT;
                PurchInvLine."Document No." := PurchInvHeaderPrepmt."No.";
                PurchInvLine."Line No." := 10000;
                PurchInvLine.Description := SourceCode.Description;
                PurchInvLine.INSERT;
            END;

            IF PurchCrMemoHeaderPrepmt."No." <> '' THEN BEGIN
                PurchCrMemoHeaderPrepmt.INSERT;
                PurchCrMemoLine.INIT;
                PurchCrMemoLine."Document No." := PurchCrMemoHeaderPrepmt."No.";
                PurchCrMemoLine."Line No." := 10000;
                PurchCrMemoLine.Description := SourceCode.Description;
                PurchCrMemoLine.INSERT;
            END;
        END;
    end;

    procedure UpdateBlanketOrderLine(PurchLine: Record "Purchase Line"; Receive: Boolean; Ship: Boolean; Invoice: Boolean)
    var
        BlanketOrderPurchLine: Record "Purchase Line";
        ModifyLine: Boolean;
        Sign: Decimal;
    begin
        IF (PurchLine."Blanket Order No." <> '') AND (PurchLine."Blanket Order Line No." <> 0) AND
           ((Receive AND (PurchLine."Qty. to Receive" <> 0)) OR
            (Ship AND (PurchLine."Return Qty. to Ship" <> 0)) OR
            (Invoice AND (PurchLine."Qty. to Invoice" <> 0)))
        THEN
            IF BlanketOrderPurchLine.GET(
                 BlanketOrderPurchLine."Document Type"::"Blanket Order", PurchLine."Blanket Order No.",
                 PurchLine."Blanket Order Line No.")
            THEN BEGIN
                BlanketOrderPurchLine.TESTFIELD(Type, PurchLine.Type);
                BlanketOrderPurchLine.TESTFIELD("No.", PurchLine."No.");
                BlanketOrderPurchLine.TESTFIELD("Buy-from Vendor No.", PurchLine."Buy-from Vendor No.");

                ModifyLine := FALSE;
                CASE PurchLine."Document Type" OF
                    PurchLine."Document Type"::Order,
                  PurchLine."Document Type"::Invoice:
                        Sign := 1;
                    PurchLine."Document Type"::"Return Order",
                  PurchLine."Document Type"::"Credit Memo":
                        Sign := -1;
                END;
                IF Receive AND (PurchLine."Receipt No." = '') THEN BEGIN
                    IF BlanketOrderPurchLine."Qty. per Unit of Measure" =
                       PurchLine."Qty. per Unit of Measure"
                    THEN
                        BlanketOrderPurchLine."Quantity Received" :=
                          BlanketOrderPurchLine."Quantity Received" + Sign * PurchLine."Qty. to Receive"
                    ELSE
                        BlanketOrderPurchLine."Quantity Received" :=
                          BlanketOrderPurchLine."Quantity Received" +
                          Sign *
                          ROUND(
                            (PurchLine."Qty. per Unit of Measure" /
                             BlanketOrderPurchLine."Qty. per Unit of Measure") *
                            PurchLine."Qty. to Receive", 0.00001);
                    BlanketOrderPurchLine."Qty. Received (Base)" :=
                      BlanketOrderPurchLine."Qty. Received (Base)" + Sign * PurchLine."Qty. to Receive (Base)";
                    ModifyLine := TRUE;
                END;
                IF Ship AND (PurchLine."Return Shipment No." = '') THEN BEGIN
                    IF BlanketOrderPurchLine."Qty. per Unit of Measure" =
                       PurchLine."Qty. per Unit of Measure"
                    THEN
                        BlanketOrderPurchLine."Quantity Received" :=
                          BlanketOrderPurchLine."Quantity Received" + Sign * PurchLine."Return Qty. to Ship"
                    ELSE
                        BlanketOrderPurchLine."Quantity Received" :=
                          BlanketOrderPurchLine."Quantity Received" +
                          Sign *
                          ROUND(
                            (PurchLine."Qty. per Unit of Measure" /
                             BlanketOrderPurchLine."Qty. per Unit of Measure") *
                            PurchLine."Return Qty. to Ship", 0.00001);
                    BlanketOrderPurchLine."Qty. Received (Base)" :=
                      BlanketOrderPurchLine."Qty. Received (Base)" + Sign * PurchLine."Return Qty. to Ship (Base)";
                    ModifyLine := TRUE;
                END;

                IF Invoice THEN BEGIN
                    IF BlanketOrderPurchLine."Qty. per Unit of Measure" =
                       PurchLine."Qty. per Unit of Measure"
                    THEN
                        BlanketOrderPurchLine."Quantity Invoiced" :=
                          BlanketOrderPurchLine."Quantity Invoiced" + Sign * PurchLine."Qty. to Invoice"
                    ELSE
                        BlanketOrderPurchLine."Quantity Invoiced" :=
                          BlanketOrderPurchLine."Quantity Invoiced" +
                          Sign *
                          ROUND(
                            (PurchLine."Qty. per Unit of Measure" /
                             BlanketOrderPurchLine."Qty. per Unit of Measure") *
                            PurchLine."Qty. to Invoice", 0.00001);
                    BlanketOrderPurchLine."Qty. Invoiced (Base)" :=
                      BlanketOrderPurchLine."Qty. Invoiced (Base)" + Sign * PurchLine."Qty. to Invoice (Base)";
                    ModifyLine := TRUE;
                END;

                IF ModifyLine THEN BEGIN
                    BlanketOrderPurchLine.InitOutstanding;

                    IF (BlanketOrderPurchLine.Quantity *
                       BlanketOrderPurchLine."Quantity Received" < 0) OR
                       (ABS(BlanketOrderPurchLine.Quantity) <
                       ABS(BlanketOrderPurchLine."Quantity Received"))
                    THEN
                        BlanketOrderPurchLine.FIELDERROR(
                          "Quantity Received",
                          STRSUBSTNO(
                            Text023,
                            BlanketOrderPurchLine.FIELDCAPTION(Quantity)));

                    IF (BlanketOrderPurchLine."Quantity (Base)" *
                       BlanketOrderPurchLine."Qty. Received (Base)" < 0) OR
                       (ABS(BlanketOrderPurchLine."Quantity (Base)") <
                       ABS(BlanketOrderPurchLine."Qty. Received (Base)"))
                    THEN
                        BlanketOrderPurchLine.FIELDERROR(
                          "Qty. Received (Base)",
                          STRSUBSTNO(
                            Text023,
                            BlanketOrderPurchLine.FIELDCAPTION("Quantity Received")));

                    BlanketOrderPurchLine.CALCFIELDS("Reserved Qty. (Base)");
                    IF ABS(BlanketOrderPurchLine."Outstanding Qty. (Base)") <
                       ABS(BlanketOrderPurchLine."Reserved Qty. (Base)")
                    THEN
                        BlanketOrderPurchLine.FIELDERROR(
                          "Reserved Qty. (Base)", Text024);

                    BlanketOrderPurchLine."Qty. to Invoice" :=
                      BlanketOrderPurchLine.Quantity - BlanketOrderPurchLine."Quantity Invoiced";
                    BlanketOrderPurchLine."Qty. to Receive" :=
                      BlanketOrderPurchLine.Quantity - BlanketOrderPurchLine."Quantity Received";
                    BlanketOrderPurchLine."Qty. to Invoice (Base)" :=
                      BlanketOrderPurchLine."Quantity (Base)" - BlanketOrderPurchLine."Qty. Invoiced (Base)";
                    BlanketOrderPurchLine."Qty. to Receive (Base)" :=
                      BlanketOrderPurchLine."Quantity (Base)" - BlanketOrderPurchLine."Qty. Received (Base)";

                    BlanketOrderPurchLine.MODIFY;
                END;
            END;
    end;

    local procedure CopyCommentLines(FromDocumentType: Integer; ToDocumentType: Integer; FromNumber: Code[20]; ToNumber: Code[20])
    begin
        PurchCommentLine.SETRANGE("Document Type", FromDocumentType);
        PurchCommentLine.SETRANGE("No.", FromNumber);
        IF PurchCommentLine.FINDSET THEN
            REPEAT
                PurchCommentLine2 := PurchCommentLine;
                PurchCommentLine2."Document Type" := ToDocumentType;
                PurchCommentLine2."No." := ToNumber;
                PurchCommentLine2.INSERT;
            UNTIL PurchCommentLine.NEXT = 0;
    end;

    local procedure RunGenJnlPostLine(var GenJnlLine: Record "81"; DimEntryNo: Integer)
    var
        TempDimBuf: Record "360" temporary;
        TempJnlLineDim: Record "Gen. Journal Line Dimension" temporary;
    begin
        TempDimBuf.DELETEALL;
        TempJnlLineDim.DELETEALL;
        DimBufMgt.GetDimensions(DimEntryNo, TempDimBuf);
        DimMgt.CopyDimBufToJnlLineDim(
          TempDimBuf, TempJnlLineDim, GenJnlLine."Journal Template Name",
          GenJnlLine."Journal Batch Name", GenJnlLine."Line No.");
        GenJnlPostLine.RunWithCheck(GenJnlLine, TempJnlLineDim);
    end;

    local procedure CopyAndCheckDocDimToTempDocDim()
    var
        PurchLine2: Record "Purchase Line";
        DimExist: Boolean;
    begin
        TempDocDim.RESET;
        TempDocDim.DELETEALL;

        //LS -
        IF PurchHeader."Only Two Dimensions" THEN BEGIN
            TempDocDim.INIT();
            TempDocDim."Table ID" := DATABASE::"Purchase Header";
            TempDocDim."Document Type" := PurchHeader."Document Type";
            TempDocDim."Document No." := PurchHeader."No.";
            TempDocDim."Line No." := 0;
            TempDocDim."Dimension Code" := GLSetup."Global Dimension 1 Code";
            TempDocDim."Dimension Value Code" := PurchHeader."Shortcut Dimension 1 Code";
            IF TempDocDim."Dimension Value Code" <> '' THEN
                TempDocDim.INSERT();
            TempDocDim."Dimension Code" := GLSetup."Global Dimension 2 Code";
            TempDocDim."Dimension Value Code" := PurchHeader."Shortcut Dimension 2 Code";
            IF TempDocDim."Dimension Value Code" <> '' THEN
                TempDocDim.INSERT();
            TempDocDim.SETRANGE("Line No.", 0);
            CheckDimComb(0);
            PurchLine2.SETRANGE("Document Type", PurchHeader."Document Type");
            PurchLine2.SETRANGE("Document No.", PurchHeader."No.");
            PurchLine2.SETFILTER(Type, '<>%1', PurchLine2.Type::" ");
            IF PurchLine2.FIND('-') THEN
                REPEAT
                    TempDocDim.INIT();
                    TempDocDim."Table ID" := DATABASE::"Purchase Line";
                    TempDocDim."Document Type" := PurchHeader."Document Type";
                    TempDocDim."Document No." := PurchHeader."No.";
                    TempDocDim."Line No." := PurchLine2."Line No.";
                    TempDocDim."Dimension Code" := GLSetup."Global Dimension 1 Code";
                    TempDocDim."Dimension Value Code" := PurchLine2."Shortcut Dimension 1 Code";
                    IF TempDocDim."Dimension Value Code" <> '' THEN
                        TempDocDim.INSERT();
                    TempDocDim."Dimension Code" := GLSetup."Global Dimension 2 Code";
                    TempDocDim."Dimension Value Code" := PurchLine2."Shortcut Dimension 2 Code";
                    IF TempDocDim."Dimension Value Code" <> '' THEN
                        TempDocDim.INSERT();
                UNTIL PurchLine2.NEXT = 0;
        END ELSE BEGIN
            //LS +
            DocDim.SETRANGE("Table ID", DATABASE::"Purchase Header");
            DocDim.SETRANGE("Document Type", PurchHeader."Document Type");
            DocDim.SETRANGE("Document No.", PurchHeader."No.");
            IF DocDim.FINDSET THEN BEGIN
                REPEAT
                    TempDocDim.INIT;
                    TempDocDim := DocDim;
                    TempDocDim.INSERT;
                UNTIL DocDim.NEXT = 0;
                DimExist := TRUE;
            END;
            IF PrepmtDocDim.FIND('-') THEN BEGIN
                REPEAT
                    TempDocDim := PrepmtDocDim;
                    TempDocDim.INSERT;
                UNTIL PrepmtDocDim.NEXT = 0;
                DimExist := TRUE;
            END;
            IF DimExist THEN BEGIN
                TempDocDim.SETRANGE("Line No.", 0);
                CheckDimComb(0);
            END;
            DocDim.SETRANGE("Table ID", DATABASE::"Purchase Line");
            DocDim.SETRANGE("Document Type", PurchHeader."Document Type");
            DocDim.SETRANGE("Document No.", PurchHeader."No.");
            IF DocDim.FINDSET THEN BEGIN
                REPEAT
                    TempDocDim.INIT;
                    TempDocDim := DocDim;
                    TempDocDim.INSERT;
                UNTIL DocDim.NEXT = 0;
                TempDocDim.SETRANGE("Line No.", 0);
                CheckDimComb(0);
            END;
        END; //LS

        PurchLine2."Line No." := 0;
        CheckDimValuePosting(PurchLine2);

        PurchLine2.SETRANGE("Document Type", PurchHeader."Document Type");
        PurchLine2.SETRANGE("Document No.", PurchHeader."No.");
        PurchLine2.SETFILTER(Type, '<>%1', PurchLine2.Type::" ");
        IF PurchLine2.FINDSET THEN
            REPEAT
                IF (PurchHeader.Receive AND (PurchLine2."Qty. to Receive" <> 0)) OR
                   (PurchHeader.Invoice AND (PurchLine2."Qty. to Invoice" <> 0)) OR
                   (PurchHeader.Ship AND (PurchLine2."Return Qty. to Ship" <> 0))
                THEN BEGIN
                    TempDocDim.SETRANGE("Line No.", PurchLine2."Line No.");
                    CheckDimComb(PurchLine2."Line No.");
                    CheckDimValuePosting(PurchLine2);
                END
            UNTIL PurchLine2.NEXT = 0;
        TempDocDim.RESET;
    end;

    local procedure CheckDimComb(LineNo: Integer)
    begin
        IF NOT DimMgt.CheckDocDimComb(TempDocDim) THEN
            IF LineNo = 0 THEN
                ERROR(
                  Text032,
                  PurchHeader."Document Type", PurchHeader."No.", DimMgt.GetDimCombErr)
            ELSE
                ERROR(
                  Text033,
                  PurchHeader."Document Type", PurchHeader."No.", LineNo, DimMgt.GetDimCombErr);
    end;

    local procedure CheckDimValuePosting(var PurchLine2: Record "Purchase Line")
    var
        TableIDArr: array[10] of Integer;
        NumberArr: array[10] of Code[20];
    begin
        IF PurchLine2."Line No." = 0 THEN BEGIN
            TableIDArr[1] := DATABASE::Vendor;
            NumberArr[1] := PurchHeader."Pay-to Vendor No.";
            TableIDArr[2] := DATABASE::"Salesperson/Purchaser";
            NumberArr[2] := PurchHeader."Purchaser Code";
            TableIDArr[3] := DATABASE::Campaign;
            NumberArr[3] := PurchHeader."Campaign No.";
            TableIDArr[4] := DATABASE::"Responsibility Center";
            NumberArr[4] := PurchHeader."Responsibility Center";
            IF NOT DimMgt.CheckDocDimValuePosting(TempDocDim, TableIDArr, NumberArr) THEN
                ERROR(
                  Text034,
                  PurchHeader."Document Type", PurchHeader."No.", DimMgt.GetDimValuePostingErr);
        END ELSE BEGIN
            TableIDArr[1] := DimMgt.TypeToTableID3(PurchLine2.Type);
            NumberArr[1] := PurchLine2."No.";
            TableIDArr[2] := DATABASE::Job;
            NumberArr[2] := PurchLine2."Job No.";
            TableIDArr[3] := DATABASE::"Work Center";
            NumberArr[3] := PurchLine2."Work Center No.";
            IF NOT DimMgt.CheckDocDimValuePosting(TempDocDim, TableIDArr, NumberArr) THEN
                ERROR(
                  Text035,
                  PurchHeader."Document Type", PurchHeader."No.", PurchLine2."Line No.", DimMgt.GetDimValuePostingErr);
        END;
    end;

    procedure CopyAprvlToTempApprvl()
    begin
        TempApprovalEntry.RESET;
        TempApprovalEntry.DELETEALL;
        ApprovalEntry.SETRANGE("Table ID", DATABASE::"Purchase Header");
        ApprovalEntry.SETRANGE("Document Type", PurchHeader."Document Type");
        ApprovalEntry.SETRANGE("Document No.", PurchHeader."No.");
        IF ApprovalEntry.FIND('-') THEN BEGIN
            REPEAT
                TempApprovalEntry.INIT;
                TempApprovalEntry := ApprovalEntry;
                TempApprovalEntry.INSERT;
            UNTIL ApprovalEntry.NEXT = 0;
        END;
    end;

    local procedure DeleteItemChargeAssgnt()
    var
        ItemChargeAssgntPurch: Record "5805";
    begin
        ItemChargeAssgntPurch.SETRANGE("Document Type", PurchLine."Document Type");
        ItemChargeAssgntPurch.SETRANGE("Document No.", PurchLine."Document No.");
        IF NOT ItemChargeAssgntPurch.ISEMPTY THEN
            ItemChargeAssgntPurch.DELETEALL;
    end;

    local procedure UpdateItemChargeAssgnt()
    var
        ItemChargeAssgntPurch: Record "5805";
    begin
        WITH TempItemChargeAssgntPurch DO BEGIN
            ClearItemChargeAssgntFilter;
            MARKEDONLY(TRUE);
            IF FINDSET THEN
                REPEAT
                    ItemChargeAssgntPurch.GET("Document Type", "Document No.", "Document Line No.", "Line No.");
                    ItemChargeAssgntPurch."Qty. Assigned" :=
                      ItemChargeAssgntPurch."Qty. Assigned" + TempItemChargeAssgntPurch."Qty. to Assign";
                    ItemChargeAssgntPurch."Qty. to Assign" := 0;
                    ItemChargeAssgntPurch."Amount to Assign" := 0;
                    ItemChargeAssgntPurch.MODIFY;
                UNTIL NEXT = 0;
        END;
    end;

    local procedure UpdatePurchOrderChargeAssgnt(PurchOrderInvLine: Record "Purchase Line"; PurchOrderLine: Record "Purchase Line")
    var
        PurchOrderLine2: Record "Purchase Line";
        PurchOrderInvLine2: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        WITH PurchOrderInvLine DO BEGIN
            ClearItemChargeAssgntFilter;
            TempItemChargeAssgntPurch.SETRANGE("Document Type", "Document Type");
            TempItemChargeAssgntPurch.SETRANGE("Document No.", "Document No.");
            TempItemChargeAssgntPurch.SETRANGE("Document Line No.", "Line No.");
            TempItemChargeAssgntPurch.MARKEDONLY(TRUE);
            IF TempItemChargeAssgntPurch.FINDSET THEN
                REPEAT
                    IF TempItemChargeAssgntPurch."Applies-to Doc. Type" = "Document Type" THEN BEGIN
                        PurchOrderInvLine2.GET(
                          TempItemChargeAssgntPurch."Applies-to Doc. Type",
                          TempItemChargeAssgntPurch."Applies-to Doc. No.",
                          TempItemChargeAssgntPurch."Applies-to Doc. Line No.");
                        IF ((PurchOrderLine."Document Type" = PurchOrderLine."Document Type"::Order) AND
                            (PurchOrderInvLine2."Receipt No." = "Receipt No.")) OR
                           ((PurchOrderLine."Document Type" = PurchOrderLine."Document Type"::"Return Order") AND
                            (PurchOrderInvLine2."Return Shipment No." = "Return Shipment No."))
                        THEN BEGIN
                            IF PurchLine."Document Type" IN ["Document Type"::Order, "Document Type"::Invoice] THEN BEGIN
                                IF NOT
                                   PurchRcptLine.GET(PurchOrderInvLine2."Receipt No.", PurchOrderInvLine2."Receipt Line No.")
                                THEN
                                    ERROR(Text014);
                                PurchOrderLine2.GET(
                                  PurchOrderLine2."Document Type"::Order,
                                  PurchRcptLine."Order No.", PurchRcptLine."Order Line No.");
                            END ELSE BEGIN
                                IF NOT
                                   ReturnShptLine.GET(PurchOrderInvLine2."Return Shipment No.", PurchOrderInvLine2."Return Shipment Line No.")
                                THEN
                                    ERROR(Text040);
                                PurchOrderLine2.GET(
                                  PurchOrderLine2."Document Type"::"Return Order",
                                  ReturnShptLine."Return Order No.", ReturnShptLine."Return Order Line No.");
                            END;
                            UpdatePurchChargeAssgntLines(
                              PurchOrderLine,
                              PurchOrderLine2."Document Type",
                              PurchOrderLine2."Document No.",
                              PurchOrderLine2."Line No.",
                              TempItemChargeAssgntPurch."Qty. to Assign");
                        END;
                    END ELSE
                        UpdatePurchChargeAssgntLines(
                          PurchOrderLine,
                          TempItemChargeAssgntPurch."Applies-to Doc. Type",
                          TempItemChargeAssgntPurch."Applies-to Doc. No.",
                          TempItemChargeAssgntPurch."Applies-to Doc. Line No.",
                          TempItemChargeAssgntPurch."Qty. to Assign");
                UNTIL TempItemChargeAssgntPurch.NEXT = 0;
        END;
    end;

    local procedure UpdatePurchChargeAssgntLines(PurchOrderLine: Record "Purchase Line"; ApplToDocType: Option; ApplToDocNo: Code[20]; ApplToDocLineNo: Integer; QtytoAssign: Decimal)
    var
        ItemChargeAssgntPurch: Record "5805";
        TempItemChargeAssgntPurch2: Record "5805";
        LastLineNo: Integer;
        TotalToAssign: Decimal;
    begin
        ItemChargeAssgntPurch.SETRANGE("Document Type", PurchOrderLine."Document Type");
        ItemChargeAssgntPurch.SETRANGE("Document No.", PurchOrderLine."Document No.");
        ItemChargeAssgntPurch.SETRANGE("Document Line No.", PurchOrderLine."Line No.");
        ItemChargeAssgntPurch.SETRANGE("Applies-to Doc. Type", ApplToDocType);
        ItemChargeAssgntPurch.SETRANGE("Applies-to Doc. No.", ApplToDocNo);
        ItemChargeAssgntPurch.SETRANGE("Applies-to Doc. Line No.", ApplToDocLineNo);
        IF ItemChargeAssgntPurch.FINDFIRST THEN BEGIN
            ItemChargeAssgntPurch."Qty. Assigned" :=
              ItemChargeAssgntPurch."Qty. Assigned" + QtytoAssign;
            ItemChargeAssgntPurch."Qty. to Assign" := 0;
            ItemChargeAssgntPurch."Amount to Assign" := 0;
            ItemChargeAssgntPurch.MODIFY;
        END ELSE BEGIN
            ItemChargeAssgntPurch.SETRANGE("Applies-to Doc. Type");
            ItemChargeAssgntPurch.SETRANGE("Applies-to Doc. No.");
            ItemChargeAssgntPurch.SETRANGE("Applies-to Doc. Line No.");
            ItemChargeAssgntPurch.CALCSUMS("Qty. to Assign");

            TempItemChargeAssgntPurch2.SETRANGE("Document Type", TempItemChargeAssgntPurch."Document Type");
            TempItemChargeAssgntPurch2.SETRANGE("Document No.", TempItemChargeAssgntPurch."Document No.");
            TempItemChargeAssgntPurch2.SETRANGE("Document Line No.", TempItemChargeAssgntPurch."Document Line No.");
            TempItemChargeAssgntPurch2.CALCSUMS("Qty. to Assign");

            TotalToAssign := ItemChargeAssgntPurch."Qty. to Assign" +
              TempItemChargeAssgntPurch2."Qty. to Assign";

            IF ItemChargeAssgntPurch.FINDLAST THEN
                LastLineNo := ItemChargeAssgntPurch."Line No.";

            IF PurchOrderLine.Quantity < TotalToAssign THEN
                REPEAT
                    TotalToAssign := TotalToAssign - ItemChargeAssgntPurch."Qty. to Assign";
                    ItemChargeAssgntPurch."Qty. to Assign" := 0;
                    ItemChargeAssgntPurch."Amount to Assign" := 0;
                    ItemChargeAssgntPurch.MODIFY;
                UNTIL (ItemChargeAssgntPurch.NEXT(-1) = 0) OR
                      (TotalToAssign = PurchOrderLine.Quantity);

            InsertAssocOrderCharge(
              PurchOrderLine,
              ApplToDocType,
              ApplToDocNo,
              ApplToDocLineNo,
              LastLineNo,
              TempItemChargeAssgntPurch."Applies-to Doc. Line Amount");
        END;
    end;

    local procedure InsertAssocOrderCharge(PurchOrderLine: Record "Purchase Line"; ApplToDocType: Option; ApplToDocNo: Code[20]; ApplToDocLineNo: Integer; LastLineNo: Integer; ApplToDocLineAmt: Decimal)
    var
        NewItemChargeAssgntPurch: Record "5805";
    begin
        WITH NewItemChargeAssgntPurch DO BEGIN
            INIT;
            "Document Type" := PurchOrderLine."Document Type";
            "Document No." := PurchOrderLine."Document No.";
            "Document Line No." := PurchOrderLine."Line No.";
            "Line No." := LastLineNo + 10000;
            "Item Charge No." := TempItemChargeAssgntPurch."Item Charge No.";
            "Item No." := TempItemChargeAssgntPurch."Item No.";
            "Qty. Assigned" := TempItemChargeAssgntPurch."Qty. to Assign";
            "Qty. to Assign" := 0;
            "Amount to Assign" := 0;
            Description := TempItemChargeAssgntPurch.Description;
            "Unit Cost" := TempItemChargeAssgntPurch."Unit Cost";
            "Applies-to Doc. Type" := ApplToDocType;
            "Applies-to Doc. No." := ApplToDocNo;
            "Applies-to Doc. Line No." := ApplToDocLineNo;
            "Applies-to Doc. Line Amount" := ApplToDocLineAmt;
            INSERT;
        END;
    end;

    local procedure CopyAndCheckItemCharge(PurchHeader: Record "Purchase Header")
    var
        PurchLine2: Record "Purchase Line";
        PurchLine3: Record "Purchase Line";
        InvoiceEverything: Boolean;
        AssignError: Boolean;
        QtyNeeded: Decimal;
    begin
        TempItemChargeAssgntPurch.RESET;
        TempItemChargeAssgntPurch.DELETEALL;

        // Check for max qty posting
        PurchLine2.RESET;
        PurchLine2.SETRANGE("Document Type", PurchHeader."Document Type");
        PurchLine2.SETRANGE("Document No.", PurchHeader."No.");
        PurchLine2.SETRANGE(Type, PurchLine2.Type::"Charge (Item)");
        PurchLine2.SETFILTER("Qty. to Invoice", '<>0');
        IF PurchLine2.ISEMPTY THEN
            EXIT;

        PurchLine2.FINDSET;
        REPEAT
            ItemChargeAssgntPurch.RESET;
            ItemChargeAssgntPurch.SETRANGE("Document Type", PurchLine2."Document Type");
            ItemChargeAssgntPurch.SETRANGE("Document No.", PurchLine2."Document No.");
            ItemChargeAssgntPurch.SETRANGE("Document Line No.", PurchLine2."Line No.");
            ItemChargeAssgntPurch.SETFILTER("Qty. to Assign", '<>0');
            IF ItemChargeAssgntPurch.FINDSET THEN
                REPEAT
                    TempItemChargeAssgntPurch.INIT;
                    TempItemChargeAssgntPurch := ItemChargeAssgntPurch;
                    TempItemChargeAssgntPurch.INSERT;
                UNTIL ItemChargeAssgntPurch.NEXT = 0;

            PurchLine2.TESTFIELD("Job No.", '');
            IF PurchHeader.Invoice AND
               (PurchLine2."Qty. to Receive" + PurchLine2."Return Qty. to Ship" <> 0) AND
               ((PurchHeader.Ship OR PurchHeader.Receive) OR
                (ABS(PurchLine2."Qty. to Invoice") >
                 ABS(PurchLine2."Qty. Rcd. Not Invoiced" + PurchLine2."Qty. to Receive") +
                 ABS(PurchLine2."Ret. Qty. Shpd Not Invd.(Base)" + PurchLine2."Return Qty. to Ship")))
            THEN
                PurchLine2.TESTFIELD("Line Amount");

            IF NOT PurchHeader.Receive THEN
                PurchLine2."Qty. to Receive" := 0;
            IF NOT PurchHeader.Ship THEN
                PurchLine2."Return Qty. to Ship" := 0;
            IF ABS(PurchLine2."Qty. to Invoice") >
               ABS(PurchLine2."Quantity Received" + PurchLine2."Qty. to Receive" +
                 PurchLine2."Return Qty. Shipped" + PurchLine2."Return Qty. to Ship" -
                 PurchLine2."Quantity Invoiced")
            THEN
                PurchLine2."Qty. to Invoice" :=
                  PurchLine2."Quantity Received" + PurchLine2."Qty. to Receive" +
                  PurchLine2."Return Qty. Shipped (Base)" + PurchLine2."Return Qty. to Ship (Base)" -
                  PurchLine2."Quantity Invoiced";

            PurchLine2.CALCFIELDS("Qty. to Assign", "Qty. Assigned");
            IF ABS(PurchLine2."Qty. to Assign" + PurchLine2."Qty. Assigned") >
               ABS(PurchLine2."Qty. to Invoice" + PurchLine2."Quantity Invoiced")
            THEN
                ERROR(Text036,
                  PurchLine2."Qty. to Invoice" + PurchLine2."Quantity Invoiced" -
                  PurchLine2."Qty. Assigned", PurchLine2.FIELDCAPTION("Document Type"),
                  PurchLine2."Document Type", PurchLine2.FIELDCAPTION("Document No."),
                  PurchLine2."Document No.", PurchLine2.FIELDCAPTION("Line No."),
                  PurchLine2."Line No.");
            IF PurchLine2.Quantity =
               PurchLine2."Qty. to Invoice" + PurchLine2."Quantity Invoiced"
            THEN BEGIN
                IF PurchLine2."Qty. to Assign" <> 0 THEN BEGIN
                    IF PurchLine2.Quantity = PurchLine2."Quantity Invoiced" THEN BEGIN
                        TempItemChargeAssgntPurch.SETRANGE("Document Line No.", PurchLine2."Line No.");
                        TempItemChargeAssgntPurch.SETRANGE("Applies-to Doc. Type", PurchLine2."Document Type");
                        IF TempItemChargeAssgntPurch.FINDSET THEN
                            REPEAT
                                PurchLine3.GET(
                                  TempItemChargeAssgntPurch."Applies-to Doc. Type",
                                  TempItemChargeAssgntPurch."Applies-to Doc. No.",
                                  TempItemChargeAssgntPurch."Applies-to Doc. Line No.");
                                IF PurchLine3.Quantity = PurchLine3."Quantity Invoiced" THEN
                                    ERROR(Text038, PurchLine3.TABLECAPTION,
                                      PurchLine3.FIELDCAPTION("Document Type"), PurchLine3."Document Type",
                                      PurchLine3.FIELDCAPTION("Document No."), PurchLine3."Document No.",
                                      PurchLine3.FIELDCAPTION("Line No."), PurchLine3."Line No.");
                            UNTIL TempItemChargeAssgntPurch.NEXT = 0;
                    END;
                END;
                IF PurchLine2.Quantity <>
                   PurchLine2."Qty. to Assign" + PurchLine2."Qty. Assigned"
                THEN
                    AssignError := TRUE;
            END;

            IF (PurchLine2."Qty. to Assign" + PurchLine2."Qty. Assigned") < (PurchLine2."Qty. to Invoice" + PurchLine2."Quantity Invoiced")
            THEN
                ERROR(Text059, PurchLine2."No.");

            // check if all ILEs exist
            QtyNeeded := PurchLine2."Qty. to Assign";
            TempItemChargeAssgntPurch.SETRANGE("Document Line No.", PurchLine2."Line No.");
            IF TempItemChargeAssgntPurch.FINDSET THEN
                REPEAT
                    IF (TempItemChargeAssgntPurch."Applies-to Doc. Type" <> PurchLine2."Document Type") AND
                       (TempItemChargeAssgntPurch."Applies-to Doc. No." <> PurchLine2."Document No.")
                    THEN
                        QtyNeeded := QtyNeeded - TempItemChargeAssgntPurch."Qty. to Assign"
                    ELSE BEGIN
                        PurchLine3.GET(
                          TempItemChargeAssgntPurch."Applies-to Doc. Type",
                          TempItemChargeAssgntPurch."Applies-to Doc. No.",
                          TempItemChargeAssgntPurch."Applies-to Doc. Line No.");
                        IF ItemLedgerEntryExist(PurchLine3) THEN
                            QtyNeeded := QtyNeeded - TempItemChargeAssgntPurch."Qty. to Assign";
                    END;
                UNTIL TempItemChargeAssgntPurch.NEXT = 0;

            IF QtyNeeded > 0 THEN
                ERROR(Text060, PurchLine2."No.");
        UNTIL PurchLine2.NEXT = 0;

        // Check purchlines
        IF AssignError THEN
            IF PurchHeader."Document Type" IN
               [PurchHeader."Document Type"::Invoice, PurchHeader."Document Type"::"Credit Memo"]
            THEN
                InvoiceEverything := TRUE
            ELSE BEGIN
                PurchLine2.RESET;
                PurchLine2.SETRANGE("Document Type", PurchHeader."Document Type");
                PurchLine2.SETRANGE("Document No.", PurchHeader."No.");
                PurchLine2.SETFILTER(Type, '%1|%2', PurchLine2.Type::Item, PurchLine2.Type::"Charge (Item)");
                IF PurchLine2.FINDSET THEN
                    REPEAT
                        IF PurchHeader.Ship OR PurchHeader.Receive THEN
                            InvoiceEverything :=
                              PurchLine2.Quantity = PurchLine2."Qty. to Invoice" + PurchLine2."Quantity Invoiced"
                        ELSE
                            InvoiceEverything :=
                              (PurchLine2.Quantity = PurchLine2."Qty. to Invoice" + PurchLine2."Quantity Invoiced") AND
                              (PurchLine2."Qty. to Invoice" =
                               PurchLine2."Qty. Rcd. Not Invoiced" + PurchLine2."Return Qty. Shipped Not Invd.");
                    UNTIL (PurchLine2.NEXT = 0) OR (NOT InvoiceEverything);
            END;

        IF InvoiceEverything AND AssignError THEN
            ERROR(Text037);
    end;

    local procedure ClearItemChargeAssgntFilter()
    begin
        TempItemChargeAssgntPurch.SETRANGE("Document Line No.");
        TempItemChargeAssgntPurch.SETRANGE("Applies-to Doc. Type");
        TempItemChargeAssgntPurch.SETRANGE("Applies-to Doc. No.");
        TempItemChargeAssgntPurch.SETRANGE("Applies-to Doc. Line No.");
        TempItemChargeAssgntPurch.MARKEDONLY(FALSE);
    end;

    local procedure GetItemChargeLine(var ItemChargePurchLine: Record "Purchase Line")
    begin
        WITH TempItemChargeAssgntPurch DO BEGIN
            IF (ItemChargePurchLine."Document Type" <> "Document Type") OR
               (ItemChargePurchLine."Document No." <> "Document No.") OR
               (ItemChargePurchLine."Line No." <> "Document Line No.")
            THEN BEGIN
                ItemChargePurchLine.GET("Document Type", "Document No.", "Document Line No.");
                IF NOT PurchHeader.Receive THEN
                    PurchLine2."Qty. to Receive" := 0;
                IF NOT PurchHeader.Ship THEN
                    PurchLine2."Return Qty. to Ship" := 0;
                IF ABS(PurchLine2."Qty. to Invoice") >
                   ABS(PurchLine2."Quantity Received" + PurchLine2."Qty. to Receive" +
                       PurchLine2."Return Qty. Shipped" + PurchLine2."Return Qty. to Ship" -
                       PurchLine2."Quantity Invoiced")
                THEN
                    PurchLine2."Qty. to Invoice" :=
                     PurchLine2."Quantity Received" + PurchLine2."Qty. to Receive" +
                     PurchLine2."Return Qty. Shipped (Base)" + PurchLine2."Return Qty. to Ship (Base)" -
                     PurchLine2."Quantity Invoiced";
            END;
        END;
    end;

    local procedure OnlyAssgntPosting(): Boolean
    var
        PurchLine: Record "Purchase Line";
        QtyLeftToAssign: Boolean;
    begin
        WITH PurchHeader DO BEGIN
            ItemChargeAssgntOnly := FALSE;
            QtyLeftToAssign := FALSE;
            PurchLine.SETRANGE("Document Type", "Document Type");
            PurchLine.SETRANGE("Document No.", "No.");
            PurchLine.SETRANGE(Type, PurchLine.Type::"Charge (Item)");
            IF PurchLine.FINDSET THEN BEGIN
                REPEAT
                    PurchLine.CALCFIELDS("Qty. Assigned");
                    IF (PurchLine."Quantity Invoiced" > PurchLine."Qty. Assigned") THEN
                        QtyLeftToAssign := TRUE;
                UNTIL PurchLine.NEXT = 0;
            END;

            IF QtyLeftToAssign THEN
                CopyAndCheckItemCharge(PurchHeader);
            ClearItemChargeAssgntFilter;
            TempItemChargeAssgntPurch.SETCURRENTKEY("Applies-to Doc. Type");
            TempItemChargeAssgntPurch.SETFILTER("Applies-to Doc. Type", '<>%1', "Document Type");
            PurchLine.SETRANGE(Type);
            PurchLine.SETRANGE("Quantity Invoiced");
            PurchLine.SETFILTER("Qty. to Assign", '<>0');
            IF PurchLine.FINDSET THEN
                REPEAT
                    TempItemChargeAssgntPurch.SETRANGE("Document Line No.", PurchLine."Line No.");
                    IF TempItemChargeAssgntPurch.FINDFIRST THEN
                        ItemChargeAssgntOnly := TRUE;
                UNTIL (PurchLine.NEXT = 0) OR ItemChargeAssgntOnly
            ELSE
                ItemChargeAssgntOnly := FALSE;
        END;
        EXIT(ItemChargeAssgntOnly);
    end;

    local procedure CalcQtyToInvoice(QtyToHandle: Decimal; QtyToInvoice: Decimal): Decimal
    begin
        IF ABS(QtyToHandle) > ABS(QtyToInvoice) THEN
            EXIT(QtyToHandle)
        ELSE
            EXIT(QtyToInvoice);
    end;

    local procedure GetGLSetup()
    begin
        IF NOT GLSetupRead THEN
            GLSetup.GET;
        GLSetupRead := TRUE;
    end;

    local procedure CheckWarehouse(var PurchLine: Record "Purchase Line")
    var
        PurchLine2: Record "Purchase Line";
        WhseValidateSourceLine: Codeunit "5777";
        ShowError: Boolean;
    begin
        PurchLine2.COPY(PurchLine);
        PurchLine2.SETRANGE(Type, PurchLine2.Type::Item);
        PurchLine2.SETRANGE("Drop Shipment", FALSE);
        IF PurchLine2.FINDSET THEN
            REPEAT
                GetLocation(PurchLine2."Location Code");
                CASE PurchLine2."Document Type" OF
                    PurchLine2."Document Type"::Order:
                        IF ((Location."Require Receive" OR Location."Require Put-away") AND
                            (PurchLine2.Quantity >= 0)) OR
                           ((Location."Require Shipment" OR Location."Require Pick") AND
                            (PurchLine2.Quantity < 0))
                        THEN BEGIN
                            IF Location."Directed Put-away and Pick" THEN
                                ShowError := TRUE
                            ELSE
                                IF WhseValidateSourceLine.WhseLinesExist(
                                     DATABASE::"Purchase Line",
                                     PurchLine2."Document Type",
                                     PurchLine2."Document No.",
                                     PurchLine2."Line No.",
                                     0,
                                     PurchLine2.Quantity)
                                THEN
                                    ShowError := TRUE;
                        END;
                    PurchLine2."Document Type"::"Return Order":
                        IF ((Location."Require Receive" OR Location."Require Put-away") AND
                            (PurchLine2.Quantity < 0)) OR
                           ((Location."Require Shipment" OR Location."Require Pick") AND
                            (PurchLine2.Quantity >= 0))
                        THEN BEGIN
                            IF Location."Directed Put-away and Pick" THEN
                                ShowError := TRUE
                            ELSE
                                IF WhseValidateSourceLine.WhseLinesExist(
                                     DATABASE::"Purchase Line",
                                     PurchLine2."Document Type",
                                     PurchLine2."Document No.",
                                     PurchLine2."Line No.",
                                     0,
                                     PurchLine2.Quantity)
                                THEN
                                    ShowError := TRUE;
                        END;
                    PurchLine2."Document Type"::Invoice, PurchLine2."Document Type"::"Credit Memo":
                        IF Location."Directed Put-away and Pick" THEN
                            Location.TESTFIELD("Adjustment Bin Code");
                END;
                IF ShowError THEN
                    ERROR(
                      Text026,
                      PurchLine2.FIELDCAPTION("Document Type"),
                      PurchLine2."Document Type",
                      PurchLine2.FIELDCAPTION("Document No."),
                      PurchLine2."Document No.",
                      PurchLine2.FIELDCAPTION("Line No."),
                      PurchLine2."Line No.");
            UNTIL PurchLine2.NEXT = 0;
    end;

    local procedure CreateWhseJnlLine(ItemJnlLine: Record "83"; PurchLine: Record "Purchase Line"; var TempWhseJnlLine: Record "7311" temporary)
    var
        WhseMgt: Codeunit "5775";
    begin
        WITH PurchLine DO BEGIN
            WMSMgmt.CheckAdjmtBin(Location, ItemJnlLine.Quantity, TRUE);
            WMSMgmt.CreateWhseJnlLine(ItemJnlLine, 0, TempWhseJnlLine, FALSE, FALSE);
            TempWhseJnlLine."Source Type" := DATABASE::"Purchase Line";
            TempWhseJnlLine."Source Subtype" := "Document Type";
            WhseMgt.GetSourceDocument(
              TempWhseJnlLine."Source Document", TempWhseJnlLine."Source Type", TempWhseJnlLine."Source Subtype");
            TempWhseJnlLine."Source No." := "Document No.";
            TempWhseJnlLine."Source Line No." := "Line No.";
            TempWhseJnlLine."Source Code" := SrcCode;
            CASE "Document Type" OF
                "Document Type"::Order:
                    TempWhseJnlLine."Reference Document" :=
                      TempWhseJnlLine."Reference Document"::"Posted Rcpt.";
                "Document Type"::Invoice:
                    TempWhseJnlLine."Reference Document" :=
                      TempWhseJnlLine."Reference Document"::"Posted P. Inv.";
                "Document Type"::"Credit Memo":
                    TempWhseJnlLine."Reference Document" :=
                      TempWhseJnlLine."Reference Document"::"Posted P. Cr. Memo";
                "Document Type"::"Return Order":
                    TempWhseJnlLine."Reference Document" :=
                      TempWhseJnlLine."Reference Document"::"Posted Rtrn. Rcpt.";
            END;
            TempWhseJnlLine."Reference No." := ItemJnlLine."Document No.";
        END;
    end;

    local procedure WhseHandlingRequired(): Boolean
    var
        WhseSetup: Record "5769";
    begin
        IF (PurchLine.Type = PurchLine.Type::Item) AND
           (NOT PurchLine."Drop Shipment")
        THEN BEGIN
            IF PurchLine."Location Code" = '' THEN BEGIN
                WhseSetup.GET;
                IF PurchLine."Document Type" = PurchLine."Document Type"::"Return Order" THEN
                    EXIT(WhseSetup."Require Pick")
                ELSE
                    EXIT(WhseSetup."Require Receive");
            END ELSE BEGIN
                GetLocation(PurchLine."Location Code");
                IF PurchLine."Document Type" = PurchLine."Document Type"::"Return Order" THEN
                    EXIT(Location."Require Pick")
                ELSE
                    EXIT(Location."Require Receive");
            END;
        END;
        EXIT(FALSE);
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        IF LocationCode = '' THEN
            Location.GetLocationSetup(LocationCode, Location)
        ELSE
            IF Location.Code <> LocationCode THEN
                Location.GET(LocationCode);
    end;

    local procedure InsertRcptEntryRelation(var PurchRcptLine: Record "121"): Integer
    var
        ItemEntryRelation: Record "6507";
    begin
        TempTrackingSpecificationInv.RESET;
        IF TempTrackingSpecificationInv.FINDSET THEN BEGIN
            REPEAT
                TempHandlingSpecification := TempTrackingSpecificationInv;
                IF TempHandlingSpecification.INSERT THEN;
            UNTIL TempTrackingSpecificationInv.NEXT = 0;
            TempTrackingSpecificationInv.DELETEALL;
        END;

        TempHandlingSpecification.RESET;
        IF TempHandlingSpecification.FINDSET THEN BEGIN
            REPEAT
                ItemEntryRelation.INIT;
                ItemEntryRelation."Item Entry No." := TempHandlingSpecification."Entry No.";
                ItemEntryRelation."Serial No." := TempHandlingSpecification."Serial No.";
                ItemEntryRelation."Lot No." := TempHandlingSpecification."Lot No.";
                ItemEntryRelation.TransferFieldsPurchRcptLine(PurchRcptLine);
                ItemEntryRelation.INSERT;
            UNTIL TempHandlingSpecification.NEXT = 0;
            TempHandlingSpecification.DELETEALL;
            EXIT(0);
        END ELSE
            EXIT(ItemLedgShptEntryNo);
    end;

    local procedure InsertReturnEntryRelation(var ReturnShptLine: Record "6651"): Integer
    var
        ItemEntryRelation: Record "6507";
    begin
        TempTrackingSpecificationInv.RESET;
        IF TempTrackingSpecificationInv.FINDSET THEN BEGIN
            REPEAT
                TempHandlingSpecification := TempTrackingSpecificationInv;
                IF TempHandlingSpecification.INSERT THEN;
            UNTIL TempTrackingSpecificationInv.NEXT = 0;
            TempTrackingSpecificationInv.DELETEALL;
        END;

        TempHandlingSpecification.RESET;
        IF TempHandlingSpecification.FINDSET THEN BEGIN
            REPEAT
                ItemEntryRelation.INIT;
                ItemEntryRelation."Item Entry No." := TempHandlingSpecification."Entry No.";
                ItemEntryRelation."Serial No." := TempHandlingSpecification."Serial No.";
                ItemEntryRelation."Lot No." := TempHandlingSpecification."Lot No.";
                ItemEntryRelation.TransferFieldsReturnShptLine(ReturnShptLine);
                ItemEntryRelation.INSERT;
            UNTIL TempHandlingSpecification.NEXT = 0;
            TempHandlingSpecification.DELETEALL;
            EXIT(0);
        END ELSE
            EXIT(ItemLedgShptEntryNo);
    end;

    local procedure CheckTrackingSpecification(var PurchLine: Record "Purchase Line")
    var
        PurchLineToCheck: Record "Purchase Line";
        ReservationEntry: Record "337";
        Item: Record Item;
        ItemTrackingCode: Record "6502";
        CreateReservEntry: Codeunit "99000830";
        ItemTrackingManagement: Codeunit "6500";
        ErrorFieldCaption: Text[250];
        SignFactor: Integer;
        PurchLineQtyHandled: Decimal;
        PurchLineQtyToHandle: Decimal;
        TrackingQtyHandled: Decimal;
        TrackingQtyToHandle: Decimal;
        Inbound: Boolean;
        SNRequired: Boolean;
        LotRequired: Boolean;
        SNInfoRequired: Boolean;
        LotInfoReguired: Boolean;
        CheckPurchLine: Boolean;
    begin
        // if a PurchaseLine is posted with ItemTracking then the whole quantity of
        // the regarding PurchaseLine has to be post with Item-Tracking

        IF PurchHeader."Document Type" IN
          [PurchHeader."Document Type"::Order, PurchHeader."Document Type"::"Return Order"] = FALSE
        THEN
            EXIT;

        TrackingQtyToHandle := 0;
        TrackingQtyHandled := 0;

        PurchLineToCheck.COPY(PurchLine);
        PurchLineToCheck.SETRANGE(Type, PurchLineToCheck.Type::Item);
        IF PurchHeader.Receive THEN BEGIN
            PurchLineToCheck.SETFILTER("Quantity Received", '<>%1', 0);
            ErrorFieldCaption := PurchLineToCheck.FIELDCAPTION("Qty. to Receive");
        END ELSE BEGIN
            PurchLineToCheck.SETFILTER("Return Qty. Shipped", '<>%1', 0);
            ErrorFieldCaption := PurchLineToCheck.FIELDCAPTION("Return Qty. to Ship");
        END;

        IF PurchLineToCheck.FINDSET THEN BEGIN
            ReservationEntry."Source Type" := DATABASE::"Purchase Line";
            ReservationEntry."Source Subtype" := PurchHeader."Document Type";
            SignFactor := CreateReservEntry.SignFactor(ReservationEntry);
            REPEAT
                // Only Item where no SerialNo or LotNo is required
                Item.GET(PurchLineToCheck."No.");
                IF Item."Item Tracking Code" <> '' THEN BEGIN
                    Inbound := (PurchLineToCheck.Quantity * SignFactor) > 0;
                    ItemTrackingCode.Code := Item."Item Tracking Code";
                    ItemTrackingManagement.GetItemTrackingSettings(ItemTrackingCode,
                      ItemJnlLine."Entry Type"::Purchase,
                      Inbound,
                      SNRequired,
                      LotRequired,
                      SNInfoRequired,
                      LotInfoReguired);
                    CheckPurchLine := (SNRequired = FALSE) AND (LotRequired = FALSE);
                    IF CheckPurchLine THEN
                        CheckPurchLine := GetTrackingQuantities(PurchLineToCheck, 0, TrackingQtyToHandle, TrackingQtyHandled);
                END ELSE
                    CheckPurchLine := FALSE;

                TrackingQtyToHandle := 0;
                TrackingQtyHandled := 0;

                IF CheckPurchLine THEN BEGIN
                    GetTrackingQuantities(PurchLineToCheck, 1, TrackingQtyToHandle, TrackingQtyHandled);
                    TrackingQtyToHandle := TrackingQtyToHandle * SignFactor;
                    TrackingQtyHandled := TrackingQtyHandled * SignFactor;
                    IF PurchHeader.Receive THEN BEGIN
                        PurchLineQtyToHandle := PurchLineToCheck."Qty. to Receive (Base)";
                        PurchLineQtyHandled := PurchLineToCheck."Qty. Received (Base)";
                    END ELSE BEGIN
                        PurchLineQtyToHandle := PurchLineToCheck."Return Qty. to Ship (Base)";
                        PurchLineQtyHandled := PurchLineToCheck."Return Qty. Shipped (Base)";
                    END;
                    IF ((TrackingQtyHandled + TrackingQtyToHandle) <> (PurchLineQtyHandled + PurchLineQtyToHandle)) OR
                       (TrackingQtyToHandle <> PurchLineQtyToHandle)
                    THEN
                        ERROR(STRSUBSTNO(Text046, ErrorFieldCaption));
                END;
            UNTIL PurchLineToCheck.NEXT = 0;
        END;
    end;

    local procedure GetTrackingQuantities(PurchLine: Record "Purchase Line"; FunctionType: Option CheckTrackingExists,GetQty; var TrackingQtyToHandle: Decimal; var TrackingQtyHandled: Decimal): Boolean
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservEntry: Record "337";
    begin
        WITH TrackingSpecification DO BEGIN
            SETCURRENTKEY("Source ID", "Source Type", "Source Subtype", "Source Batch Name",
              "Source Prod. Order Line", "Source Ref. No.");
            SETRANGE("Source Type", DATABASE::"Purchase Line");
            SETRANGE("Source Subtype", PurchLine."Document Type");
            SETRANGE("Source ID", PurchLine."Document No.");
            SETRANGE("Source Batch Name", '');
            SETRANGE("Source Prod. Order Line", 0);
            SETRANGE("Source Ref. No.", PurchLine."Line No.");
        END;
        WITH ReservEntry DO BEGIN
            SETCURRENTKEY(
              "Source ID", "Source Ref. No.", "Source Type", "Source Subtype",
              "Source Batch Name", "Source Prod. Order Line");
            SETRANGE("Source ID", PurchLine."Document No.");
            SETRANGE("Source Ref. No.", PurchLine."Line No.");
            SETRANGE("Source Type", DATABASE::"Purchase Line");
            SETRANGE("Source Subtype", PurchLine."Document Type");
            SETRANGE("Source Batch Name", '');
            SETRANGE("Source Prod. Order Line", 0);
        END;

        CASE FunctionType OF
            FunctionType::CheckTrackingExists:
                BEGIN
                    TrackingSpecification.SETRANGE(Correction, FALSE);
                    IF NOT TrackingSpecification.ISEMPTY THEN
                        EXIT(TRUE);
                    ReservEntry.SETFILTER("Serial No.", '<>%1', '');
                    IF NOT ReservEntry.ISEMPTY THEN
                        EXIT(TRUE);
                    ReservEntry.SETRANGE("Serial No.");
                    ReservEntry.SETFILTER("Lot No.", '<>%1', '');
                    IF NOT ReservEntry.ISEMPTY THEN
                        EXIT(TRUE);
                END;
            FunctionType::GetQty:
                BEGIN
                    TrackingSpecification.CALCSUMS("Quantity Handled (Base)");
                    TrackingQtyHandled := TrackingSpecification."Quantity Handled (Base)";
                    IF ReservEntry.FINDSET THEN
                        REPEAT
                            IF (ReservEntry."Lot No." <> '') OR (ReservEntry."Serial No." <> '') THEN
                                TrackingQtyToHandle := TrackingQtyToHandle + ReservEntry."Qty. to Handle (Base)";
                        UNTIL ReservEntry.NEXT = 0;
                END;
        END;
    end;

    local procedure SaveInvoiceSpecification(var TempInvoicingSpecification: Record "Tracking Specification" temporary)
    begin
        TempInvoicingSpecification.RESET;
        IF TempInvoicingSpecification.FINDSET THEN BEGIN
            REPEAT
                TempInvoicingSpecification."Quantity Invoiced (Base)" += TempInvoicingSpecification."Qty. to Invoice (Base)";
                TempTrackingSpecification := TempInvoicingSpecification;
                TempTrackingSpecification."Buffer Status" := TempTrackingSpecification."Buffer Status"::MODIFY;
                IF NOT (TempTrackingSpecification.INSERT) THEN BEGIN
                    TempTrackingSpecification.GET(TempInvoicingSpecification."Entry No.");
                    TempTrackingSpecification."Qty. to Invoice (Base)" += TempInvoicingSpecification."Qty. to Invoice (Base)";
                    IF TempInvoicingSpecification."Qty. to Invoice (Base)" = TempInvoicingSpecification."Quantity Invoiced (Base)" THEN
                        TempTrackingSpecification."Quantity Invoiced (Base)" += TempInvoicingSpecification."Quantity Invoiced (Base)"
                    ELSE
                        TempTrackingSpecification."Quantity Invoiced (Base)" += TempInvoicingSpecification."Qty. to Invoice (Base)";
                    TempTrackingSpecification."Qty. to Invoice" += TempInvoicingSpecification."Qty. to Invoice";
                    TempTrackingSpecification.MODIFY;
                END;
            UNTIL TempInvoicingSpecification.NEXT = 0;
            TempInvoicingSpecification.DELETEALL;
        END;
    end;

    local procedure InsertTrackingSpecification()
    var
        TrackingSpecification: Record "Tracking Specification";
    begin
        TempTrackingSpecification.RESET;
        IF TempTrackingSpecification.FINDSET THEN BEGIN
            REPEAT
                TrackingSpecification := TempTrackingSpecification;
                TrackingSpecification."Buffer Status" := 0;
                TrackingSpecification.InitQtyToShip;
                TrackingSpecification.Correction := FALSE;
                TrackingSpecification."Quantity actual Handled (Base)" := 0;
                IF TempTrackingSpecification."Buffer Status" = TempTrackingSpecification."Buffer Status"::MODIFY THEN
                    TrackingSpecification.MODIFY
                ELSE
                    TrackingSpecification.INSERT;
            UNTIL TempTrackingSpecification.NEXT = 0;
            TempTrackingSpecification.DELETEALL;
        END;

        ReservePurchLine.UpdateItemTrackingAfterPosting(PurchHeader);
    end;

    local procedure CalcBaseQty(ItemNo: Code[20]; UOMCode: Code[10]; Qty: Decimal): Decimal
    var
        UOMMgt: Codeunit "5402";
        Item: Record Item;
    begin
        Item.GET(ItemNo);
        EXIT(ROUND(Qty * UOMMgt.GetQtyPerUnitOfMeasure(Item, UOMCode), 0.00001));
    end;

    local procedure InsertValueEntryRelation()
    var
        ValueEntryRelation: Record "6508";
    begin
        TempValueEntryRelation.RESET;
        IF TempValueEntryRelation.FINDSET THEN BEGIN
            REPEAT
                ValueEntryRelation := TempValueEntryRelation;
                ValueEntryRelation.INSERT;
            UNTIL TempValueEntryRelation.NEXT = 0;
            TempValueEntryRelation.DELETEALL;
        END;
    end;

    local procedure PostItemCharge(PurchLine: Record "Purchase Line"; ItemEntryNo: Integer; QuantityBase: Decimal; AmountToAssign: Decimal; QtyToAssign: Decimal; IndirectCostPct: Decimal)
    var
        DummyTrackingSpecification: Record "Tracking Specification";
    begin
        WITH TempItemChargeAssgntPurch DO BEGIN
            PurchLine."No." := "Item No.";
            PurchLine."Line No." := "Document Line No.";
            PurchLine."Appl.-to Item Entry" := ItemEntryNo;
            PurchLine."Indirect Cost %" := IndirectCostPct;

            PurchLine.Amount := AmountToAssign;

            IF "Document Type" IN ["Document Type"::"Return Order", "Document Type"::"Credit Memo"] THEN
                PurchLine.Amount := -PurchLine.Amount;

            IF PurchLine."Currency Code" <> '' THEN
                PurchLine."Unit Cost" := ROUND(
                  PurchLine.Amount / QuantityBase, Currency."Unit-Amount Rounding Precision")
            ELSE
                PurchLine."Unit Cost" := ROUND(
                  PurchLine.Amount / QuantityBase, GLSetup."Unit-Amount Rounding Precision");

            TotalChargeAmt := TotalChargeAmt + PurchLine.Amount;
            IF PurchHeader."Currency Code" <> '' THEN
                PurchLine.Amount :=
                  CurrExchRate.ExchangeAmtFCYToLCY(
                    Usedate, PurchHeader."Currency Code", TotalChargeAmt, PurchHeader."Currency Factor");

            PurchLine.Amount := ROUND(PurchLine.Amount, GLSetup."Amount Rounding Precision") - TotalChargeAmtLCY;
            IF PurchHeader."Currency Code" <> '' THEN
                TotalChargeAmtLCY := TotalChargeAmtLCY + PurchLine.Amount;
            PurchLine."Unit Cost (LCY)" :=
              ROUND(
                PurchLine.Amount / QuantityBase, GLSetup."Unit-Amount Rounding Precision");

            PurchLine."Inv. Discount Amount" := ROUND(
              PurchLine."Inv. Discount Amount" / PurchLine.Quantity * QtyToAssign,
              GLSetup."Amount Rounding Precision");

            PurchLine."Line Discount Amount" := ROUND(
                PurchLine."Line Discount Amount" / PurchLine.Quantity * QtyToAssign,
                GLSetup."Amount Rounding Precision");
            PostItemJnlLine(
              PurchLine,
              0, 0,
              QuantityBase, QuantityBase,
              PurchLine."Appl.-to Item Entry", "Item Charge No.", DummyTrackingSpecification);
        END;
    end;

    procedure SaveTempWhseSplitSpec(PurchLine3: Record "Purchase Line")
    begin
        TempWhseSplitSpecification.RESET;
        TempWhseSplitSpecification.DELETEALL;
        IF TempHandlingSpecification.FINDSET THEN
            REPEAT
                TempWhseSplitSpecification := TempHandlingSpecification;
                TempWhseSplitSpecification."Source Type" := DATABASE::"Purchase Line";
                TempWhseSplitSpecification."Source Subtype" := PurchLine3."Document Type";
                TempWhseSplitSpecification."Source ID" := PurchLine3."Document No.";
                TempWhseSplitSpecification."Source Ref. No." := PurchLine3."Line No.";
                TempWhseSplitSpecification.INSERT;
            UNTIL TempHandlingSpecification.NEXT = 0;
    end;

    procedure TransferReservToItemJnlLine(var SalesOrderLine: Record "37"; var ItemJnlLine: Record "83"; var QtyToBeShippedBase: Decimal; ApplySpecificItemTracking: Boolean)
    var
        ReserveSalesLine: Codeunit "99000832";
        RemainingQuantity: Decimal;
        CheckApplFromItemEntry: Boolean;
    begin
        // Handle Item Tracking and reservations, also on drop shipment
        IF QtyToBeShippedBase = 0 THEN
            EXIT;

        IF NOT ApplySpecificItemTracking THEN
            ReserveSalesLine.TransferSalesLineToItemJnlLine(
              SalesOrderLine, ItemJnlLine, QtyToBeShippedBase, CheckApplFromItemEntry)
        ELSE BEGIN
            TempTrackingSpecification.RESET;
            TempTrackingSpecification.SETRANGE("Source Type", DATABASE::"Purchase Line");
            TempTrackingSpecification.SETRANGE("Source Subtype", PurchLine."Document Type");
            TempTrackingSpecification.SETRANGE("Source ID", PurchLine."Document No.");
            TempTrackingSpecification.SETRANGE("Source Batch Name", '');
            TempTrackingSpecification.SETRANGE("Source Prod. Order Line", 0);
            TempTrackingSpecification.SETRANGE("Source Ref. No.", PurchLine."Line No.");
            IF TempTrackingSpecification.ISEMPTY THEN
                ReserveSalesLine.TransferSalesLineToItemJnlLine(
                  SalesOrderLine, ItemJnlLine, QtyToBeShippedBase, CheckApplFromItemEntry)
            ELSE BEGIN
                ReserveSalesLine.SetApplySpecificItemTracking(TRUE);
                ReserveSalesLine.SetOverruleItemTracking(TRUE);
                TempTrackingSpecification.FINDSET;
                IF TempTrackingSpecification."Quantity (Base)" / QtyToBeShippedBase < 0 THEN
                    ERROR(Text043);
                REPEAT
                    ItemJnlLine."Serial No." := TempTrackingSpecification."Serial No.";
                    ItemJnlLine."Lot No." := TempTrackingSpecification."Lot No.";
                    ItemJnlLine."Applies-to Entry" := TempTrackingSpecification."Appl.-to Item Entry";
                    RemainingQuantity :=
                      ReserveSalesLine.TransferSalesLineToItemJnlLine(
                        SalesOrderLine, ItemJnlLine, TempTrackingSpecification."Quantity (Base)", CheckApplFromItemEntry);
                    IF RemainingQuantity <> 0 THEN
                        ERROR(Text044);
                UNTIL TempTrackingSpecification.NEXT = 0;
                ItemJnlLine."Serial No." := '';
                ItemJnlLine."Lot No." := '';
                ItemJnlLine."Applies-to Entry" := 0;
            END;
        END;
    end;

    procedure SetWhseRcptHeader(var WhseRcptHeader2: Record "7316")
    begin
        WhseRcptHeader := WhseRcptHeader2;
        TempWhseRcptHeader := WhseRcptHeader;
        TempWhseRcptHeader.INSERT;
    end;

    procedure SetWhseShptHeader(var WhseShptHeader2: Record "7320")
    begin
        WhseShptHeader := WhseShptHeader2;
        TempWhseShptHeader := WhseShptHeader;
        TempWhseShptHeader.INSERT;
    end;

    local procedure CopySalesCommentLines(FromDocumentType: Integer; ToDocumentType: Integer; FromNumber: Code[20]; ToNumber: Code[20])
    var
        SalesCommentLine: Record "Sales Comment Line";
        SalesCommentLine2: Record "Sales Comment Line";
    begin
        SalesCommentLine.SETRANGE("Document Type", FromDocumentType);
        SalesCommentLine.SETRANGE("No.", FromNumber);
        IF SalesCommentLine.FINDSET THEN
            REPEAT
                SalesCommentLine2 := SalesCommentLine;
                SalesCommentLine2."Document Type" := ToDocumentType;
                SalesCommentLine2."No." := ToNumber;
                SalesCommentLine2.INSERT;
            UNTIL SalesCommentLine.NEXT = 0;
    end;

    local procedure GetNextPurchline(var PurchLine: Record "Purchase Line"): Boolean
    begin
        IF PurchLine.NEXT = 1 THEN
            EXIT(FALSE);
        IF TempPrepmtPurchLine.FIND('-') THEN BEGIN
            PurchLine := TempPrepmtPurchLine;
            TempPrepmtPurchLine.DELETE;
            EXIT(FALSE);
        END;
        EXIT(TRUE);
    end;

    procedure CreatePrepmtLines(PurchHeader: Record "Purchase Header"; var TempPrepmtPurchLine: Record "Purchase Line"; var TempDocDim: Record "Document Dimension"; CompleteFunctionality: Boolean)
    var
        GLAcc: Record "15";
        PurchLine: Record "Purchase Line";
        DocDim: Record "Document Dimension";
        TempExtTextLine: Record "280" temporary;
        DimMgt: Codeunit "408";
        TransferExtText: Codeunit "378";
        NextLineNo: Integer;
        Fraction: Decimal;
        VATDifference: Decimal;
        TempLineFound: Boolean;
        PrePmtTestRun: Boolean;
    begin
        GetGLSetup;
        WITH PurchLine DO BEGIN
            SETRANGE("Document Type", PurchHeader."Document Type");
            SETRANGE("Document No.", PurchHeader."No.");
            IF NOT FIND('+') THEN
                EXIT;
            NextLineNo := "Line No." + 10000;
            SETFILTER(Quantity, '>0');
            SETFILTER("Qty. to Invoice", '>0');
            IF FIND('-') THEN
                REPEAT
                    IF CompleteFunctionality THEN BEGIN
                        IF PurchHeader."Document Type" <> PurchHeader."Document Type"::Invoice THEN BEGIN
                            IF NOT PurchHeader.Receive AND ("Qty. to Invoice" = Quantity - "Quantity Invoiced") THEN
                                Fraction := ("Qty. Rcd. Not Invoiced" + "Quantity Invoiced") / Quantity
                            ELSE
                                Fraction := ("Qty. to Invoice" + "Quantity Invoiced") / Quantity;

                            IF (PurchHeader.Receive = FALSE) AND (PurchHeader.Invoice = TRUE) THEN
                                VALIDATE("Qty. to Receive", 0);

                            CASE TRUE OF
                                ("Prepmt Amt to Deduct" <> 0) AND
                              (ROUND(Fraction * "Line Amount", Currency."Amount Rounding Precision") < "Prepmt Amt to Deduct"):
                                    FIELDERROR(
                                      "Prepmt Amt to Deduct",
                                      STRSUBSTNO(
                                        Text047,
                                        ROUND(Fraction * "Line Amount", Currency."Amount Rounding Precision")));
                                ("Prepmt. Amt. Inv." <> 0) AND
                              (ROUND((1 - Fraction) * "Line Amount", Currency."Amount Rounding Precision") <
                               ROUND(
                                 ROUND(
                                   ROUND("Direct Unit Cost" * (Quantity - "Quantity Invoiced" - "Qty. to Invoice"),
                                     Currency."Amount Rounding Precision") *
                                   (1 - "Line Discount %" / 100), Currency."Amount Rounding Precision") *
                                 "Prepayment %" / 100, Currency."Amount Rounding Precision")):
                                    FIELDERROR(
                                      "Prepmt Amt to Deduct",
                                      STRSUBSTNO(
                                        Text048,
                                        ROUND(
                                          "Prepmt. Amt. Inv." - "Prepmt Amt Deducted" -
                                          (1 - Fraction) * "Line Amount", Currency."Amount Rounding Precision")));
                            END;
                        END ELSE
                            IF NOT PrePmtTestRun THEN BEGIN
                                TestGetRcptPPmtAmtToDeduct(PurchHeader, PurchLine);
                                PrePmtTestRun := TRUE;
                            END;
                    END;

                    IF "Prepmt Amt to Deduct" <> 0 THEN BEGIN
                        IF ("Gen. Bus. Posting Group" <> GenPostingSetup."Gen. Bus. Posting Group") OR
                           ("Gen. Prod. Posting Group" <> GenPostingSetup."Gen. Prod. Posting Group")
                        THEN BEGIN
                            GenPostingSetup.GET("Gen. Bus. Posting Group", "Gen. Prod. Posting Group");
                            GenPostingSetup.TESTFIELD("Purch. Prepayments Account");
                        END;
                        GLAcc.GET(GenPostingSetup."Purch. Prepayments Account");
                        TempLineFound := FALSE;
                        IF PurchHeader."Compress Prepayment" THEN BEGIN
                            TempPrepmtPurchLine.SETRANGE("No.", GLAcc."No.");
                            IF TempPrepmtPurchLine.FIND('-') THEN
                                TempLineFound := DocDimMatch(PurchLine, TempPrepmtPurchLine."Line No.", TempDocDim);
                            TempPrepmtPurchLine.SETRANGE("No.");
                        END;
                        IF TempLineFound THEN BEGIN
                            IF PurchHeader."Currency Code" <> '' THEN BEGIN
                                TempPrePayDeductLCYPurchLine := PurchLine;
                                TempPrePayDeductLCYPurchLine."Prepmt. Amount Inv. (LCY)" :=
                                  ROUND(CurrExchRate.ExchangeAmtFCYToLCY(
                                    PurchHeader."Posting Date",
                                    PurchHeader."Currency Code",
                                    TempPrepmtPurchLine."Direct Unit Cost" + "Prepmt Amt to Deduct",
                                    PurchHeader."Currency Factor")) -
                                  ROUND(CurrExchRate.ExchangeAmtFCYToLCY(
                                    PurchHeader."Posting Date",
                                    PurchHeader."Currency Code",
                                    TempPrepmtPurchLine."Direct Unit Cost",
                                    PurchHeader."Currency Factor"));
                                TempPrePayDeductLCYPurchLine.INSERT;
                            END;
                            VATDifference := TempPrepmtPurchLine."VAT Difference";
                            TempPrepmtPurchLine.VALIDATE(
                              "Direct Unit Cost", TempPrepmtPurchLine."Direct Unit Cost" + "Prepmt Amt to Deduct");
                            TempPrepmtPurchLine.VALIDATE("VAT Difference", VATDifference - "Prepmt VAT Diff. to Deduct");
                            TempPrepmtPurchLine.MODIFY;
                        END ELSE BEGIN
                            TempPrepmtPurchLine.INIT;
                            TempPrepmtPurchLine."Document Type" := PurchHeader."Document Type";
                            TempPrepmtPurchLine."Document No." := PurchHeader."No.";
                            TempPrepmtPurchLine."Line No." := 0;
                            TempPrepmtPurchLine."System-Created Entry" := TRUE;
                            IF CompleteFunctionality THEN
                                TempPrepmtPurchLine.VALIDATE(Type, TempPrepmtPurchLine.Type::"G/L Account")
                            ELSE
                                TempPrepmtPurchLine.Type := TempPrepmtPurchLine.Type::"G/L Account";
                            TempPrepmtPurchLine.VALIDATE("No.", GenPostingSetup."Purch. Prepayments Account");
                            TempPrepmtPurchLine.VALIDATE(Quantity, -1);
                            TempPrepmtPurchLine."Qty. to Receive" := TempPrepmtPurchLine.Quantity;
                            TempPrepmtPurchLine."Qty. to Invoice" := TempPrepmtPurchLine.Quantity;
                            IF PurchHeader."Currency Code" <> '' THEN BEGIN
                                TempPrePayDeductLCYPurchLine := PurchLine;
                                TempPrePayDeductLCYPurchLine."Prepmt. Amount Inv. (LCY)" :=
                                  ROUND(CurrExchRate.ExchangeAmtFCYToLCY(
                                    PurchHeader."Posting Date",
                                    PurchHeader."Currency Code",
                                    "Prepmt Amt to Deduct",
                                    PurchHeader."Currency Factor"));
                                TempPrePayDeductLCYPurchLine.INSERT;
                            END;
                            TempPrepmtPurchLine.VALIDATE("Direct Unit Cost", "Prepmt Amt to Deduct");
                            TempPrepmtPurchLine.VALIDATE("VAT Difference", -"Prepmt VAT Diff. to Deduct");
                            TempPrepmtPurchLine."Prepayment Line" := TRUE;
                            TempPrepmtPurchLine."Line No." := NextLineNo;
                            NextLineNo := NextLineNo + 10000;
                            DocDim.SETRANGE("Table ID", DATABASE::"Purchase Line");
                            DocDim.SETRANGE("Document Type", "Document Type");
                            DocDim.SETRANGE("Document No.", "Document No.");
                            DocDim.SETRANGE("Line No.", "Line No.");
                            IF DocDim.FIND('-') THEN
                                REPEAT
                                    TempDocDim := DocDim;
                                    TempDocDim."Line No." := TempPrepmtPurchLine."Line No.";
                                    TempDocDim.INSERT;
                                    IF TempDocDim."Dimension Code" = GLSetup."Global Dimension 1 Code" THEN
                                        TempPrepmtPurchLine."Shortcut Dimension 1 Code" := TempDocDim."Dimension Value Code";
                                    IF TempDocDim."Dimension Code" = GLSetup."Global Dimension 2 Code" THEN
                                        TempPrepmtPurchLine."Shortcut Dimension 2 Code" := TempDocDim."Dimension Value Code";
                                UNTIL DocDim.NEXT = 0;
                            TempPrepmtPurchLine.INSERT;
                            TransferExtText.PrepmtGetAnyExtText(
                              TempPrepmtPurchLine."No.", DATABASE::"Purch. Inv. Line",
                              PurchHeader."Document Date", PurchHeader."Language Code", TempExtTextLine);
                            IF TempExtTextLine.FIND('-') THEN
                                REPEAT
                                    TempPrepmtPurchLine.INIT;
                                    TempPrepmtPurchLine.Description := TempExtTextLine.Text;
                                    TempPrepmtPurchLine."System-Created Entry" := TRUE;
                                    TempPrepmtPurchLine."Prepayment Line" := TRUE;
                                    TempPrepmtPurchLine."Line No." := NextLineNo;
                                    NextLineNo := NextLineNo + 10000;
                                    TempPrepmtPurchLine.INSERT;
                                UNTIL TempExtTextLine.NEXT = 0;

                        END;
                    END;
                UNTIL NEXT = 0
        END;
    end;

    procedure MergePurchLines(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var PurchLine2: Record "Purchase Line"; var MergedPurchLine: Record "Purchase Line")
    begin
        WITH PurchLine DO BEGIN
            SETRANGE("Document Type", PurchHeader."Document Type");
            SETRANGE("Document No.", PurchHeader."No.");
            IF FIND('-') THEN
                REPEAT
                    MergedPurchLine := PurchLine;
                    MergedPurchLine.INSERT;
                UNTIL NEXT = 0;
        END;
        WITH PurchLine2 DO BEGIN
            SETRANGE("Document Type", PurchHeader."Document Type");
            SETRANGE("Document No.", PurchHeader."No.");
            IF FIND('-') THEN
                REPEAT
                    MergedPurchLine := PurchLine2;
                    MergedPurchLine.INSERT;
                UNTIL NEXT = 0;
        END;
    end;

    local procedure DocDimMatch(PurchLine: Record "Purchase Line"; LineNo2: Integer; var TempDocDim: Record "Document Dimension"): Boolean
    var
        DocDim: Record "Document Dimension";
        Found: Boolean;
        Found2: Boolean;
    begin
        WITH DocDim DO BEGIN
            SETRANGE("Table ID", DATABASE::"Purchase Line");
            SETRANGE("Document Type", PurchLine."Document Type");
            SETRANGE("Document No.", PurchLine."Document No.");
            SETRANGE("Line No.", PurchLine."Line No.");
            IF NOT FIND('-') THEN
                CLEAR(DocDim);
        END;
        WITH TempDocDim DO BEGIN
            SETRANGE("Table ID", DATABASE::"Purchase Line");
            SETRANGE("Document Type", PurchLine."Document Type");
            SETRANGE("Document No.", PurchLine."Document No.");
            SETRANGE("Line No.", LineNo2);
            IF NOT FIND('-') THEN
                CLEAR(TempDocDim);
        END;

        WHILE (DocDim."Dimension Code" = TempDocDim."Dimension Code") AND
              (DocDim."Dimension Value Code" = TempDocDim."Dimension Value Code") AND
              (DocDim."Dimension Code" <> '')
        DO BEGIN
            IF NOT DocDim.FIND('>') THEN
                CLEAR(DocDim);
            IF NOT TempDocDim.FIND('>') THEN
                CLEAR(TempDocDim);
        END;

        TempDocDim.RESET;
        EXIT((DocDim."Dimension Code" = TempDocDim."Dimension Code") AND
            (DocDim."Dimension Value Code" = TempDocDim."Dimension Value Code"));
    end;

    local procedure InsertICGenJnlLine(PurchLine: Record "Purchase Line")
    var
        ICGLAccount: Record "410";
        Cust: Record Customer;
        Currency: Record Currency;
        ICPartner: Record "IC Partner";
    begin
        PurchHeader.TESTFIELD("Buy-from IC Partner Code", '');
        PurchHeader.TESTFIELD("Pay-to IC Partner Code", '');
        PurchLine.TESTFIELD("IC Partner Ref. Type", PurchLine."IC Partner Ref. Type"::"G/L Account");
        ICGLAccount.GET(PurchLine."IC Partner Reference");
        ICGenJnlLineNo := ICGenJnlLineNo + 1;
        TempICGenJnlLine.INIT;
        TempICGenJnlLine."Line No." := ICGenJnlLineNo;
        TempICGenJnlLine.VALIDATE("Posting Date", PurchHeader."Posting Date");
        TempICGenJnlLine."Document Date" := PurchHeader."Document Date";
        TempICGenJnlLine.Description := PurchHeader."Posting Description";
        TempICGenJnlLine."Reason Code" := PurchHeader."Reason Code";
        TempICGenJnlLine."Document Type" := GenJnlLineDocType;
        TempICGenJnlLine."Document No." := GenJnlLineDocNo;
        TempICGenJnlLine."External Document No." := GenJnlLineExtDocNo;
        TempICGenJnlLine.VALIDATE("Account Type", TempICGenJnlLine."Account Type"::"IC Partner");
        TempICGenJnlLine.VALIDATE("Account No.", PurchLine."IC Partner Code");
        TempICGenJnlLine."Source Currency Code" := PurchHeader."Currency Code";
        TempICGenJnlLine."Source Currency Amount" := TempICGenJnlLine.Amount;
        TempICGenJnlLine.Correction := PurchHeader.Correction;
        TempICGenJnlLine."Shortcut Dimension 1 Code" := PurchLine."Shortcut Dimension 1 Code";
        TempICGenJnlLine."Shortcut Dimension 2 Code" := PurchLine."Shortcut Dimension 2 Code";
        TempICGenJnlLine."Source Code" := SrcCode;
        TempICGenJnlLine."Country/Region Code" := PurchHeader."VAT Country/Region Code";
        TempICGenJnlLine."Source Type" := GenJnlLine."Source Type"::Vendor;
        TempICGenJnlLine."Source No." := PurchHeader."Pay-to Vendor No.";
        TempICGenJnlLine."Posting No. Series" := PurchHeader."Posting No. Series";
        TempICGenJnlLine.VALIDATE("Bal. Account Type", TempICGenJnlLine."Bal. Account Type"::"G/L Account");
        TempICGenJnlLine.VALIDATE("Bal. Account No.", PurchLine."No.");
        //APNT-IC1.0
        IF PurchHeader."IC Transaction No." <> 0 THEN BEGIN
            TempICGenJnlLine."IC Transaction No." := PurchHeader."IC Transaction No.";
            TempICGenJnlLine."IC Partner Direction" := PurchHeader."IC Partner Direction";
        END ELSE BEGIN
            TempICGenJnlLine."IC Transaction No." := ICTransactionNo;
            TempICGenJnlLine."IC Partner Direction" := ICDirection;
        END;
        //APNT-IC1.0
        Cust.SETRANGE("IC Partner Code", PurchLine."IC Partner Code");
        IF Cust.FINDFIRST THEN BEGIN
            TempICGenJnlLine.VALIDATE("Bal. Gen. Bus. Posting Group", Cust."Gen. Bus. Posting Group");
            TempICGenJnlLine.VALIDATE("Bal. VAT Bus. Posting Group", Cust."VAT Bus. Posting Group");
        END;
        TempICGenJnlLine."IC Partner Code" := PurchLine."IC Partner Code";
        TempICGenJnlLine."IC Partner G/L Acc. No." := PurchLine."IC Partner Reference";
        TempICGenJnlLine."IC Direction" := TempICGenJnlLine."IC Direction"::Outgoing;
        ICPartner.GET(PurchLine."IC Partner Code");
        IF ICPartner."Cost Distribution in LCY" AND (PurchLine."Currency Code" <> '') THEN BEGIN
            TempICGenJnlLine."Currency Code" := '';
            TempICGenJnlLine."Currency Factor" := 0;
            Currency.GET(PurchLine."Currency Code");
            IF PurchHeader."Document Type" IN
               [PurchHeader."Document Type"::"Return Order", PurchHeader."Document Type"::"Credit Memo"]
            THEN
                TempICGenJnlLine.Amount :=
                  -ROUND(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      PurchHeader."Posting Date", PurchLine."Currency Code",
                      PurchLine.Amount, PurchHeader."Currency Factor"))
            ELSE
                TempICGenJnlLine.Amount :=
                  ROUND(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      PurchHeader."Posting Date", PurchLine."Currency Code",
                      PurchLine.Amount, PurchHeader."Currency Factor"));
        END ELSE BEGIN
            Currency.InitRoundingPrecision;
            TempICGenJnlLine."Currency Code" := PurchHeader."Currency Code";
            TempICGenJnlLine."Currency Factor" := PurchHeader."Currency Factor";
            IF PurchHeader."Document Type" IN
              [PurchHeader."Document Type"::"Return Order", PurchHeader."Document Type"::"Credit Memo"]
            THEN
                TempICGenJnlLine.Amount := -PurchLine.Amount
            ELSE
                TempICGenJnlLine.Amount := PurchLine.Amount;
        END;
        IF TempICGenJnlLine."Bal. VAT %" <> 0 THEN
            TempICGenJnlLine.Amount := ROUND(TempICGenJnlLine.Amount * (1 + TempICGenJnlLine."Bal. VAT %" / 100),
                                                   Currency."Amount Rounding Precision");
        TempICGenJnlLine.VALIDATE(Amount);
        TempICGenJnlLine.INSERT;

        TempDocDim.RESET;
        TempDocDim.SETRANGE("Table ID", DATABASE::"Purchase Line");
        TempDocDim.SETRANGE("Line No.", PurchLine."Line No.");
        IF TempDocDim.FIND('-') THEN
            REPEAT
                TempICJnlLineDim."Table ID" := DATABASE::"Gen. Journal Line";
                TempICJnlLineDim."Journal Line No." := ICGenJnlLineNo;
                TempICJnlLineDim."Dimension Code" := TempDocDim."Dimension Code";
                TempICJnlLineDim."Dimension Value Code" := TempDocDim."Dimension Value Code";
                TempICJnlLineDim.INSERT;
            UNTIL TempDocDim.NEXT = 0;
    end;

    local procedure PostICGenJnl()
    var
        ICTransactionNo: Integer;
        ICPartner: Record "IC Partner";
        ICOutboxTransaction: Record "414";
        ICOutboxExport: Codeunit "431";
    begin
        TempICGenJnlLine.RESET;
        IF TempICGenJnlLine.FIND('-') THEN
            REPEAT
                TempICJnlLineDim.RESET;
                TempICJnlLineDim.SETRANGE("Table ID", DATABASE::"Gen. Journal Line");
                TempICJnlLineDim.SETRANGE("Journal Line No.", TempICGenJnlLine."Line No.");
                ICTransactionNo := ICInOutBoxMgt.CreateOutboxJnlTransaction(TempICGenJnlLine, FALSE);
                ICInOutBoxMgt.CreateOutboxJnlLine(ICTransactionNo, 1, TempICGenJnlLine, TempICJnlLineDim);
                GenJnlPostLine.RunWithCheck(TempICGenJnlLine, TempICJnlLineDim);
            UNTIL TempICGenJnlLine.NEXT = 0;

        //APNT-IC1.0
        ICPartner.GET(TempICGenJnlLine."IC Partner Code");
        IF ICPartner."Auto Post Outbox Transactions" THEN BEGIN
            ICOutboxTransaction.RESET;
            ICOutboxTransaction.SETRANGE("Transaction No.", ICTransactionNo);
            IF ICOutboxTransaction.FINDFIRST THEN BEGIN
                CLEAR(ICOutboxExport);
                ICOutboxExport.AutoPostICOutbocTransaction(ICOutboxTransaction."Transaction No.");
            END;
        END;
        //APNT-IC1.0
    end;

    procedure TestGetRcptPPmtAmtToDeduct(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line")
    var
        TempPurchLine2: Record "Purchase Line";
        TempPurchLine3: Record "Purchase Line" temporary;
        OrderNo: Code[20];
        TotalPrePmtAmtToDeduct: Decimal;
        QtyToInv: Decimal;
        LineNo: Decimal;
    begin
        TempPurchLine.SETRANGE("Document Type", PurchHeader."Document Type");
        TempPurchLine.SETRANGE("Document No.", PurchHeader."No.");
        IF NOT TempPurchLine.FIND('+') THEN
            EXIT;
        TempPurchLine.SETFILTER(Quantity, '>0');
        TempPurchLine.SETFILTER("Qty. to Invoice", '>0');
        TempPurchLine.SETFILTER("Receipt No.", '<>%1', '');

        IF TempPurchLine.FINDSET THEN
            REPEAT
                TempPurchLine3 := TempPurchLine;
                TempPurchLine3.INSERT;
            UNTIL TempPurchLine.NEXT = 0;

        IF TempPurchLine.FINDSET THEN
            REPEAT
                IF PurchRcptLine.GET(TempPurchLine."Receipt No.", TempPurchLine."Receipt Line No.") THEN BEGIN
                    TempPurchLine2.GET(
                      TempPurchLine."Document Type"::Order,
                      PurchRcptLine."Order No.", PurchRcptLine."Order Line No.");
                    OrderNo := PurchRcptLine."Order No.";
                    LineNo := PurchRcptLine."Line No.";

                    IF TempPurchLine3.FINDSET THEN
                        REPEAT
                            IF PurchRcptLine.GET(TempPurchLine3."Receipt No.", TempPurchLine3."Receipt Line No.") THEN
                                IF (PurchRcptLine."Order No." = OrderNo) AND (PurchRcptLine."Line No." = LineNo) THEN BEGIN
                                    QtyToInv := QtyToInv + TempPurchLine3."Qty. to Invoice";
                                    TotalPrePmtAmtToDeduct := TotalPrePmtAmtToDeduct + TempPurchLine3."Prepmt Amt to Deduct";
                                END;
                        UNTIL TempPurchLine3.NEXT = 0;
                    CASE TRUE OF
                        (TotalPrePmtAmtToDeduct > TempPurchLine2."Prepmt. Amt. Inv." - TempPurchLine2."Prepmt Amt Deducted"):
                            ERROR(
                              STRSUBSTNO(Text050,
                                TempPurchLine2.FIELDCAPTION("Prepmt Amt to Deduct"),
                                ROUND(
                                  TempPurchLine2."Prepmt. Amt. Inv." - TempPurchLine2."Prepmt Amt Deducted",
                                  GLSetup."Amount Rounding Precision")));
                        (QtyToInv = TempPurchLine2.Quantity - TempPurchLine2."Quantity Invoiced"):
                            IF NOT (TotalPrePmtAmtToDeduct = TempPurchLine2."Prepmt. Amt. Inv." - TempPurchLine2."Prepmt Amt Deducted") THEN
                                ERROR(
                                  STRSUBSTNO(Text051,
                                    TempPurchLine2.FIELDCAPTION("Prepmt Amt to Deduct"),
                                    ROUND(
                                      TempPurchLine2."Prepmt. Amt. Inv." - TempPurchLine2."Prepmt Amt Deducted",
                                      GLSetup."Amount Rounding Precision")));
                    END;
                    TotalPrePmtAmtToDeduct := 0;
                    QtyToInv := 0;
                END;
            UNTIL TempPurchLine.NEXT = 0;
    end;

    procedure ArchiveUnpostedOrder()
    var
        ArchiveManagement: Codeunit "5063";
    begin
        IF NOT PurchSetup."Archive Quotes and Orders" THEN
            EXIT;
        IF NOT (PurchHeader."Document Type" IN [PurchHeader."Document Type"::Order, PurchHeader."Document Type"::"Return Order"]) THEN
            EXIT;
        PurchLine.RESET;
        PurchLine.SETRANGE("Document Type", PurchHeader."Document Type");
        PurchLine.SETRANGE("Document No.", PurchHeader."No.");
        PurchLine.SETFILTER(Quantity, '<>0');
        IF PurchHeader."Document Type" = PurchHeader."Document Type"::Order THEN BEGIN
            PurchLine.SETRANGE("Quantity Received", 0);
            PurchLine.SETFILTER("Qty. to Receive", '<>0');
        END ELSE BEGIN
            PurchLine.SETRANGE("Return Qty. Shipped", 0);
            PurchLine.SETFILTER("Return Qty. to Ship", '<>0');
        END;
        IF NOT PurchLine.ISEMPTY THEN BEGIN
            ArchiveManagement.ArchPurchDocumentNoConfirm(PurchHeader);
            COMMIT;
        END;
    end;

    procedure PrepayRealizeGainLoss(PurchLine: Record "Purchase Line")
    var
        TempJnlLineDim: Record "Gen. Journal Line Dimension" temporary;
        PurchasePostPrepayments: Codeunit "444";
    begin
        WITH PurchHeader DO BEGIN
            IF (PurchLine."Prepmt. Amount Inv. (LCY)" <> 0) THEN BEGIN
                GenJnlLine.INIT;
                GenJnlLine."Posting Date" := "Posting Date";
                GenJnlLine."Document Date" := "Document Date";
                GenJnlLine.Description := "Posting Description";
                GenJnlLine."Reason Code" := "Reason Code";
                GenJnlLine."Document Type" := GenJnlLineDocType;
                GenJnlLine."Document No." := GenJnlLineDocNo;
                GenJnlLine."External Document No." := GenJnlLineExtDocNo;
                DocDim.SETRANGE("Table ID", DATABASE::"Purchase Line");
                DocDim.SETRANGE("Document Type", "Document Type");
                DocDim.SETRANGE("Document No.", PurchLine."Document No.");
                DocDim.SETRANGE("Line No.", PurchLine."Line No.");
                TempJnlLineDim.RESET;
                TempJnlLineDim.DELETEALL;
                DimMgt.CopyDocDimToJnlLineDim(DocDim, TempJnlLineDim);
                GenJnlLine."Shortcut Dimension 1 Code" := PurchLine."Shortcut Dimension 1 Code";
                GenJnlLine."Shortcut Dimension 2 Code" := PurchLine."Shortcut Dimension 2 Code";
                GenJnlLine."Source Code" := SrcCode;
                GenJnlLine."Source Type" := GenJnlLine."Source Type"::Customer;
                GenJnlLine."Source No." := "Pay-to Vendor No.";
                GenJnlLine."Posting No. Series" := "Posting No. Series";
                GenJnlLine."Source Currency Code" := "Currency Code";
                PurchasePostPrepayments.RealizeGainLoss(GenJnlLine, PurchLine);
                GenJnlPostLine.RunWithCheck(GenJnlLine, TempJnlLineDim);
            END;
        END;
    end;

    procedure PostItemJrnlLineJobConsumption(var PurchLine: Record "Purchase Line"; var NextReservationEntryNo: Integer; var QtyToBeInvoiced: Decimal; var QtyToBeInvoicedBase: Decimal; var QtyToBeReceived: Decimal; var QtyToBeReceivedBase: Decimal; var CheckApplToItemEntry: Boolean; var TempJnlLineDim: Record "Gen. Journal Line Dimension" temporary)
    begin
        WITH PurchLine DO BEGIN
            IF ("Job No." <> '') THEN BEGIN
                ItemJnlLine2."Entry Type" := ItemJnlLine2."Entry Type"::"Negative Adjmt.";
                Job.GET("Job No.");
                ItemJnlLine2."Source No." := Job."Bill-to Customer No.";
                ItemJnlLine2."Source Type" := ItemJnlLine2."Source Type"::Customer;
                ItemJnlLine2."Discount Amount" := 0;
                IF "Quantity Received" <> 0 THEN
                    GetNextItemLedgEntryNo(ItemJnlLine2);

                IF (QtyToBeReceived <> 0) THEN BEGIN
                    // item tracking for consumption
                    ReservationEntry2.RESET;
                    IF ReservationEntry3.FIND('-') THEN BEGIN
                        IF ReservationEntry2.FIND('+') THEN
                            NextReservationEntryNo := ReservationEntry2."Entry No." + 1
                        ELSE
                            NextReservationEntryNo := 1;
                        REPEAT
                            ReservationEntry2 := ReservationEntry3;
                            ReservationEntry2."Entry No." := NextReservationEntryNo;
                            IF ReservationEntry2.Positive THEN
                                ReservationEntry2.Positive := FALSE
                            ELSE
                                ReservationEntry2.Positive := TRUE;
                            ReservationEntry2."Quantity (Base)" := ReservationEntry2."Quantity (Base)" * -1;
                            ReservationEntry2."Shipment Date" := ReservationEntry2."Expected Receipt Date";
                            ReservationEntry2."Expected Receipt Date" := 0D;
                            ReservationEntry2.Quantity := ReservationEntry2.Quantity * -1;
                            ReservationEntry2."Qty. to Handle (Base)" := ReservationEntry2."Qty. to Handle (Base)" * -1;
                            ReservationEntry2."Qty. to Invoice (Base)" := ReservationEntry2."Qty. to Invoice (Base)" * -1;
                            ReservationEntry2.INSERT;
                            NextReservationEntryNo := NextReservationEntryNo + 1;
                        UNTIL ReservationEntry3.NEXT = 0;
                        IF (QtyToBeReceivedBase <> 0) THEN
                            IF "Document Type" IN ["Document Type"::"Return Order", "Document Type"::"Credit Memo"] THEN
                                ReservePurchLine.TransferPurchLineToItemJnlLine(PurchLine, ItemJnlLine2, QtyToBeReceivedBase, CheckApplToItemEntry)
                            ELSE
                                ReservePurchLine.TransferPurchLineToItemJnlLine(PurchLine, ItemJnlLine2, -QtyToBeReceivedBase, CheckApplToItemEntry);
                    END;
                END;

                ItemJnlPostLine.RunWithCheck(ItemJnlLine2, TempJnlLineDim);

                IF (QtyToBeInvoiced <> 0) THEN BEGIN
                    JobPostLine.InsertPurchLine(PurchHeader, PurchInvHeader, PurchCrMemoHeader, PurchLine, SrcCode, TempJnlLineDim);
                END;
            END;
        END;
    end;

    procedure GetNextItemLedgEntryNo(var ItemJnlLine: Record "83")
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        WITH ItemLedgEntry DO BEGIN
            SETRANGE("Job No.", ItemJnlLine."Job No.");
            SETRANGE("Job Task No.", ItemJnlLine."Job Task No.");
            SETRANGE("Item No.", ItemJnlLine."Item No.");

            SETFILTER("Item Tracking", '<>%1', "Item Tracking"::None);
            IF FINDFIRST THEN BEGIN
                SETRANGE("Entry Type", ItemJnlLine."Entry Type"::"Negative Adjmt.");
                SETRANGE("Serial No.", ItemJnlLine."Serial No.");
                SETRANGE("Lot No.", ItemJnlLine."Lot No.");
                IF FINDFIRST THEN
                    ItemJnlLine."Item Shpt. Entry No." := "Entry No.";
                EXIT;
            END;
            SETRANGE("Item Tracking");

            IF FINDSET THEN
                REPEAT
                    IF "Entry No." = ItemJnlLine."Item Shpt. Entry No." THEN BEGIN
                        NEXT;
                        ItemJnlLine."Item Shpt. Entry No." := "Entry No.";
                        EXIT;
                    END;
                UNTIL NEXT = 0;
        END;
    end;

    local procedure ItemLedgerEntryExist(PurchLine2: Record "Purchase Line"): Boolean
    var
        HasItemLedgerEntry: Boolean;
    begin
        IF PurchHeader.Receive OR PurchHeader.Ship THEN
            // item ledger entry will be created during posting in this transaction
            HasItemLedgerEntry :=
            ((PurchLine2."Qty. to Receive" + PurchLine2."Quantity Received") <> 0) OR
            ((PurchLine2."Qty. to Invoice" + PurchLine2."Quantity Invoiced") <> 0) OR
            ((PurchLine2."Return Qty. to Ship" + PurchLine2."Return Qty. Shipped") <> 0)
        ELSE
            // item ledger entry must already exist
            HasItemLedgerEntry :=
            (PurchLine2."Quantity Received" <> 0) OR
            (PurchLine2."Return Qty. Shipped" <> 0);

        EXIT(HasItemLedgerEntry);
    end;

    procedure CheckCostSheet(Pheader: Record "Purchase Header")
    var
        CostSheet: Record "50000";
        hasvalue: Boolean;
        ExtDocNo: Code[20];
    begin
        hasvalue := FALSE;
        CostSheet.RESET;
        //CostSheet.SETRANGE("Document Type",CostSheet."Document Type"::Order);
        CostSheet.SETRANGE("No.", Pheader."No.");
        IF CostSheet.FIND('-') THEN
            REPEAT
                IF (CostSheet.Amount <> 0) OR (CostSheet."Amount (LCY)" <> 0) THEN BEGIN
                    hasvalue := TRUE;
                    IF (CostSheet."Account Type" = CostSheet."Account Type"::Vendor) OR
                       (CostSheet."Bal. Account Type" = CostSheet."Bal. Account Type"::Vendor) THEN
                        IF CostSheet."External Document No." = '' THEN
                            ERROR('Please enter the Vendor Invoice No. in the Cost Sheet');
                END ELSE
                    ERROR('Please enter the charges in the cost sheet form');
            UNTIL CostSheet.NEXT = 0;
        IF NOT hasvalue THEN
            ERROR('Please enter the charges in the cost sheet form');
    end;

    procedure CheckCostSheetCM(Pheader: Record "Purchase Header")
    var
        CostSheet: Record "50000";
        hasvalue: Boolean;
        ExtDocNo: Code[20];
    begin
        hasvalue := FALSE;
        CostSheet.RESET;
        CostSheet.SETRANGE("Document Type", CostSheet."Document Type"::"Credit Memo");
        CostSheet.SETRANGE("No.", Pheader."No.");
        IF CostSheet.FIND('-') THEN
            REPEAT
                IF (CostSheet.Amount <> 0) OR (CostSheet."Amount (LCY)" <> 0) THEN BEGIN
                    hasvalue := TRUE;
                    IF (CostSheet."Account Type" = CostSheet."Account Type"::Vendor) OR
                       (CostSheet."Bal. Account Type" = CostSheet."Bal. Account Type"::Vendor) THEN
                        IF CostSheet."External Document No." = '' THEN
                            ERROR('Please enter the Vendor Invoice No. in the Cost Sheet in the External Document No. field');
                END ELSE
                    ERROR('Please enter the charges in the cost sheet form');
            UNTIL CostSheet.NEXT = 0;
        IF NOT hasvalue THEN
            ERROR('Please enter the charges in the cost sheet form');
    end;

    procedure PostCostSheet(Pheader: Record "Purchase Header")
    var
        CostSheet: Record "50000";
        GenJnl: Record "81";
        JnlLineDim: Record "Gen. Journal Line Dimension";
        GenJnlPostBatch: Codeunit "13";
        CounterVal: Integer;
        LineNo: Integer;
        CostSheet2: Record "50000";
    begin
        WITH Pheader DO BEGIN
            SourceCodeSetup.GET;
            GLSetup.GET;
            PurchSetup.GET;
            PurchSetup.TESTFIELD("Cost Sheet Journal Template");
            PurchSetup.TESTFIELD("Cost Sheet Journal Batch");

            GenJnl.RESET;
            GenJnl.SETRANGE("Journal Template Name", PurchSetup."Cost Sheet Journal Template");
            GenJnl.SETRANGE("Journal Batch Name", PurchSetup."Cost Sheet Journal Batch");
            GenJnl.DELETEALL;

            LineNo := 10000;

            IF "Document Type" = "Document Type"::Order THEN BEGIN
                CLEAR(GenJnlPostBatch);
                CounterVal := 0;
                CostSheet.RESET;
                CostSheet.SETRANGE(Sequence, Sequence); //APNT-CO2.0
                CostSheet.SETFILTER("Document Type", '%1', "Document Type");
                CostSheet.SETFILTER("No.", "No.");
                CostSheet.SETFILTER(Amount, '<>%1', 0);
                IF CostSheet.FIND('-') THEN
                    REPEAT
                        IF NOT CostSheet.Posted THEN BEGIN
                            GenJnl.INIT;
                            GenJnl.VALIDATE("Journal Template Name", PurchSetup."Cost Sheet Journal Template");
                            GenJnl.VALIDATE("Journal Batch Name", PurchSetup."Cost Sheet Journal Batch");
                            GenJnl."Line No." := LineNo;
                            GenJnl.VALIDATE("Posting Date", "Posting Date");
                            GenJnl.VALIDATE("Document Date", "Document Date");
                            GenJnl.VALIDATE("Document Type", GenJnl."Document Type"::" ");
                            GenJnl.VALIDATE("Document No.", GenJnlLineDocNo);
                            GenJnl.VALIDATE("Account Type", CostSheet."Account Type");
                            GenJnl.VALIDATE("Account No.", CostSheet."Account No.");
                            GenJnl.VALIDATE("External Document No.", CostSheet."External Document No.");
                            GenJnl.VALIDATE(Description, CostSheet.Description);
                            GenJnl."Source Type" := CostSheet."Bal. Account Type";
                            GenJnl."Source No." := CostSheet."Bal. Account No.";
                            GenJnl."Source Code" := SourceCodeSetup."Landed Cost";
                            GenJnl.VALIDATE("Currency Code", CostSheet."Currency Code");
                            GenJnl.VALIDATE(Amount, ROUND(CostSheet.Amount));
                            GenJnl.VALIDATE("Shortcut Dimension 1 Code", CostSheet."Shortcut Dimension 1 Code");
                            GenJnl.VALIDATE("Shortcut Dimension 2 Code", CostSheet."Shortcut Dimension 2 Code");
                            //GC++
                            GenJnl."Invoice Received Date" := Pheader."Date Received";
                            //GC--
                            GenJnl.INSERT;

                            DocDim.RESET;
                            DocDim.SETRANGE("Table ID", DATABASE::"Landed Cost Sheet");
                            DocDim.SETRANGE("Document Type", "Document Type");
                            DocDim.SETRANGE("Document No.", "No.");
                            DocDim.SETRANGE("Line No.", CostSheet."Line No.");
                            IF DocDim.FIND('-') THEN
                                REPEAT
                                    IF JnlLineDim.GET(DATABASE::"Gen. Journal Line", GenJnl."Journal Template Name",
                                          GenJnl."Journal Batch Name", GenJnl."Line No.", 0, DocDim."Dimension Code") THEN BEGIN
                                        JnlLineDim."Dimension Value Code" := DocDim."Dimension Value Code";
                                        JnlLineDim.MODIFY;
                                    END ELSE BEGIN
                                        JnlLineDim.INIT;
                                        JnlLineDim."Table ID" := DATABASE::"Gen. Journal Line";
                                        JnlLineDim."Journal Template Name" := GenJnl."Journal Template Name";
                                        JnlLineDim."Journal Batch Name" := GenJnl."Journal Batch Name";
                                        JnlLineDim."Journal Line No." := GenJnl."Line No.";
                                        JnlLineDim."Dimension Code" := DocDim."Dimension Code";
                                        JnlLineDim."Dimension Value Code" := DocDim."Dimension Value Code";
                                        JnlLineDim.INSERT;
                                    END;
                                UNTIL DocDim.NEXT = 0;
                            LineNo += 10000;

                            GenJnl.INIT;
                            GenJnl.VALIDATE("Journal Template Name", PurchSetup."Cost Sheet Journal Template");
                            GenJnl.VALIDATE("Journal Batch Name", PurchSetup."Cost Sheet Journal Batch");
                            GenJnl."Line No." := LineNo;
                            GenJnl.VALIDATE("Posting Date", "Posting Date");
                            GenJnl.VALIDATE("Document Date", "Document Date");
                            GenJnl.VALIDATE("Document Type", GenJnl."Document Type"::" ");
                            /*
                            IF CostSheet."Bal. Account Type" = CostSheet."Bal. Account Type"::Vendor THEN BEGIN
                              CounterVal := CounterVal + 1;
                              GenJnl."Document Type" := GenJnl."Document Type"::Invoice;
                              GenJnl.VALIDATE("Document No.",GenJnlLineDocNo + 'OH' + FORMAT(CounterVal));
                            END
                            ELSE
                            */
                            GenJnl.VALIDATE("Document No.", GenJnlLineDocNo);
                            GenJnl.VALIDATE("Account Type", CostSheet."Bal. Account Type");
                            GenJnl.VALIDATE("Account No.", CostSheet."Bal. Account No.");
                            GenJnl.Description := CostSheet.Description;
                            GenJnl.VALIDATE("External Document No.", CostSheet."External Document No.");
                            GenJnl."Source Type" := CostSheet."Bal. Account Type";
                            GenJnl."Source No." := CostSheet."Bal. Account No.";
                            GenJnl."Source Code" := SourceCodeSetup."Landed Cost";
                            GenJnl.VALIDATE("Currency Code", CostSheet."Currency Code");
                            GenJnl.VALIDATE(Amount, ROUND(-CostSheet.Amount));
                            GenJnl.VALIDATE("Shortcut Dimension 1 Code", CostSheet."Shortcut Dimension 1 Code");
                            GenJnl.VALIDATE("Shortcut Dimension 2 Code", CostSheet."Shortcut Dimension 2 Code");
                            //GC++
                            GenJnl."Invoice Received Date" := Pheader."Date Received";
                            //GC--
                            GenJnl.INSERT;

                            DocDim.RESET;
                            DocDim.SETRANGE("Table ID", DATABASE::"Landed Cost Sheet");
                            DocDim.SETRANGE("Document Type", "Document Type");
                            DocDim.SETRANGE("Document No.", "No.");
                            DocDim.SETRANGE("Line No.", CostSheet."Line No.");
                            IF DocDim.FIND('-') THEN
                                REPEAT
                                    IF JnlLineDim.GET(DATABASE::"Gen. Journal Line", GenJnl."Journal Template Name",
                                          GenJnl."Journal Batch Name", GenJnl."Line No.", 0, DocDim."Dimension Code") THEN BEGIN
                                        JnlLineDim."Dimension Value Code" := DocDim."Dimension Value Code";
                                        JnlLineDim.MODIFY;
                                    END ELSE BEGIN
                                        JnlLineDim.INIT;
                                        JnlLineDim."Table ID" := DATABASE::"Gen. Journal Line";
                                        JnlLineDim."Journal Template Name" := GenJnl."Journal Template Name";
                                        JnlLineDim."Journal Batch Name" := GenJnl."Journal Batch Name";
                                        JnlLineDim."Journal Line No." := GenJnl."Line No.";
                                        JnlLineDim."Dimension Code" := DocDim."Dimension Code";
                                        JnlLineDim."Dimension Value Code" := DocDim."Dimension Value Code";
                                        JnlLineDim.INSERT;
                                    END;
                                UNTIL DocDim.NEXT = 0;
                            //APNT-CO2.1 -
                            //GenJnlPostBatch.RUN(GenJnl);//Commented Olde Code
                            CLEAR(CostSheet2);
                            CostSheet2.COPY(CostSheet);
                            CostSheet2.Posted := TRUE;
                            CostSheet2.MODIFY;
                            //APNT-CO2.1 +
                            LineNo += 10000;
                        END;
                    UNTIL CostSheet.NEXT = 0;
            END ELSE
                IF Pheader."Document Type" = Pheader."Document Type"::Invoice THEN BEGIN
                    CLEAR(GenJnlPostBatch);
                    CounterVal := 0;

                    CostSheet.RESET;
                    CostSheet.SETRANGE(Sequence, Sequence); //APNT-CO2.0
                    CostSheet.SETFILTER("Document Type", '%1', Pheader."Document Type");
                    CostSheet.SETFILTER("No.", Pheader."No.");
                    CostSheet.SETFILTER(Amount, '<>%1', 0);
                    IF CostSheet.FIND('-') THEN
                        REPEAT
                            IF NOT CostSheet.Posted THEN BEGIN//APNT-CO2.1
                                GenJnl.INIT;
                                GenJnl.VALIDATE("Journal Template Name", PurchSetup."Cost Sheet Journal Template");
                                GenJnl.VALIDATE("Journal Batch Name", PurchSetup."Cost Sheet Journal Batch");
                                GenJnl."Line No." := LineNo;
                                GenJnl.VALIDATE("Posting Date", "Posting Date");
                                GenJnl.VALIDATE("Document Date", "Document Date");
                                GenJnl.VALIDATE("Document Type", GenJnl."Document Type"::" ");
                                GenJnl.VALIDATE("Document No.", GenJnlLineDocNo);
                                GenJnl.VALIDATE("Account Type", CostSheet."Account Type");
                                GenJnl.VALIDATE("Account No.", CostSheet."Account No.");
                                GenJnl.VALIDATE(Description, CostSheet.Description);
                                GenJnl.VALIDATE("External Document No.", CostSheet."External Document No.");
                                GenJnl."Source Type" := CostSheet."Bal. Account Type";
                                GenJnl."Source No." := CostSheet."Bal. Account No.";
                                GenJnl."Source Code" := SourceCodeSetup."Landed Cost";
                                GenJnl.VALIDATE("Currency Code", CostSheet."Currency Code");
                                GenJnl.VALIDATE(Amount, ROUND(CostSheet.Amount));
                                GenJnl.VALIDATE("Shortcut Dimension 1 Code", CostSheet."Shortcut Dimension 1 Code");
                                GenJnl.VALIDATE("Shortcut Dimension 2 Code", CostSheet."Shortcut Dimension 2 Code");
                                GenJnl."Invoice Received Date" := Pheader."Date Received";  //GC--
                                GenJnl.INSERT;

                                GLSetup.GET;
                                DocDim.RESET;
                                DocDim.SETRANGE("Table ID", DATABASE::"Landed Cost Sheet");
                                DocDim.SETRANGE("Document Type", "Document Type");
                                DocDim.SETRANGE("Document No.", "No.");
                                DocDim.SETRANGE("Line No.", CostSheet."Line No.");
                                IF DocDim.FIND('-') THEN
                                    REPEAT
                                        IF JnlLineDim.GET(DATABASE::"Gen. Journal Line", GenJnl."Journal Template Name",
                                              GenJnl."Journal Batch Name", GenJnl."Line No.", 0, DocDim."Dimension Code") THEN BEGIN
                                            JnlLineDim."Dimension Value Code" := DocDim."Dimension Value Code";
                                            JnlLineDim.MODIFY;
                                        END ELSE BEGIN
                                            JnlLineDim.INIT;
                                            JnlLineDim."Table ID" := DATABASE::"Gen. Journal Line";
                                            JnlLineDim."Journal Template Name" := GenJnl."Journal Template Name";
                                            JnlLineDim."Journal Batch Name" := GenJnl."Journal Batch Name";
                                            JnlLineDim."Journal Line No." := GenJnl."Line No.";
                                            JnlLineDim."Dimension Code" := DocDim."Dimension Code";
                                            JnlLineDim."Dimension Value Code" := DocDim."Dimension Value Code";
                                            JnlLineDim.INSERT;
                                        END;
                                    UNTIL DocDim.NEXT = 0;
                                LineNo += 10000;

                                GenJnl.INIT;
                                GenJnl.VALIDATE("Journal Template Name", PurchSetup."Cost Sheet Journal Template");
                                GenJnl.VALIDATE("Journal Batch Name", PurchSetup."Cost Sheet Journal Batch");
                                GenJnl."Line No." := LineNo;
                                GenJnl.VALIDATE("Posting Date", "Posting Date");
                                GenJnl.VALIDATE("Document Date", "Document Date");
                                GenJnl.VALIDATE("Document Type", GenJnl."Document Type"::" ");
                                /*
                                IF CostSheet."Bal. Account Type" = CostSheet."Bal. Account Type"::Vendor THEN BEGIN
                                  CounterVal := CounterVal + 1;
                                  GenJnl."Document Type":= CostSheet."Doc Type"::Invoice;
                                  GenJnl.VALIDATE("External Document No.",CostSheet."External Document No.");
                                  GenJnl.VALIDATE("Document No.",GenJnlLineDocNo + 'OH' + FORMAT(CounterVal));
                                END ELSE
                                */
                                GenJnl.VALIDATE("Document No.", GenJnlLineDocNo);
                                GenJnl.VALIDATE("Account Type", CostSheet."Bal. Account Type");
                                GenJnl.VALIDATE("Account No.", CostSheet."Bal. Account No.");
                                GenJnl.VALIDATE(Description, CostSheet.Description);
                                GenJnl.VALIDATE("External Document No.", CostSheet."External Document No.");
                                GenJnl."Source Type" := CostSheet."Bal. Account Type";
                                GenJnl."Source No." := CostSheet."Bal. Account No.";
                                GenJnl."Source Code" := SourceCodeSetup."Landed Cost";
                                GenJnl.VALIDATE("Currency Code", CostSheet."Currency Code");
                                GenJnl.VALIDATE(Amount, ROUND(-CostSheet.Amount));
                                GenJnl.VALIDATE("Shortcut Dimension 1 Code", CostSheet."Shortcut Dimension 1 Code");
                                GenJnl.VALIDATE("Shortcut Dimension 2 Code", CostSheet."Shortcut Dimension 2 Code");
                                GenJnl."Invoice Received Date" := Pheader."Date Received";//GC--
                                GenJnl.INSERT;

                                DocDim.RESET;
                                DocDim.SETRANGE("Table ID", DATABASE::"Landed Cost Sheet");
                                DocDim.SETRANGE("Document Type", "Document Type");
                                DocDim.SETRANGE("Document No.", "No.");
                                DocDim.SETRANGE("Line No.", CostSheet."Line No.");
                                IF DocDim.FIND('-') THEN
                                    REPEAT
                                        IF JnlLineDim.GET(DATABASE::"Gen. Journal Line", GenJnl."Journal Template Name",
                                              GenJnl."Journal Batch Name", GenJnl."Line No.", 0, DocDim."Dimension Code") THEN BEGIN
                                            JnlLineDim."Dimension Value Code" := DocDim."Dimension Value Code";
                                            JnlLineDim.MODIFY;
                                        END ELSE BEGIN
                                            JnlLineDim.INIT;
                                            JnlLineDim."Table ID" := DATABASE::"Gen. Journal Line";
                                            JnlLineDim."Journal Template Name" := GenJnl."Journal Template Name";
                                            JnlLineDim."Journal Batch Name" := GenJnl."Journal Batch Name";
                                            JnlLineDim."Journal Line No." := GenJnl."Line No.";
                                            JnlLineDim."Dimension Code" := DocDim."Dimension Code";
                                            JnlLineDim."Dimension Value Code" := DocDim."Dimension Value Code";
                                            JnlLineDim.INSERT;
                                        END;
                                    UNTIL DocDim.NEXT = 0;

                                //APNT-CO2.1 -
                                //GenJnlPostBatch.RUN(GenJnl);//Commented Olde Code
                                CLEAR(CostSheet2);
                                CostSheet2.COPY(CostSheet);
                                CostSheet2.Posted := TRUE;
                                CostSheet2.MODIFY;
                                //APNT-CO2.1 +

                                LineNo += 10000;
                            END;
                        UNTIL CostSheet.NEXT = 0;
                END ELSE
                    IF Pheader."Document Type" = Pheader."Document Type"::"Credit Memo" THEN BEGIN
                        CLEAR(GenJnlPostBatch);
                        CounterVal := 0;

                        CostSheet.RESET;
                        CostSheet.SETRANGE(Sequence, Sequence); //APNT-CO2.0
                        CostSheet.SETFILTER("Document Type", '%1', Pheader."Document Type");
                        CostSheet.SETFILTER("No.", Pheader."No.");
                        CostSheet.SETFILTER(Amount, '<>%1', 0);
                        IF CostSheet.FIND('-') THEN
                            REPEAT
                                IF NOT CostSheet.Posted THEN BEGIN//APNT-CO2.1
                                    GenJnl.INIT;
                                    GenJnl.VALIDATE("Journal Template Name", PurchSetup."Cost Sheet Journal Template");
                                    GenJnl.VALIDATE("Journal Batch Name", PurchSetup."Cost Sheet Journal Batch");
                                    GenJnl."Line No." := LineNo;
                                    GenJnl.VALIDATE("Posting Date", PurchHeader."Posting Date");
                                    GenJnl.VALIDATE("Document Date", PurchHeader."Document Date");
                                    GenJnl.VALIDATE("Document Type", GenJnl."Document Type"::" ");
                                    GenJnl.VALIDATE("Document No.", GenJnlLineDocNo);
                                    GenJnl.VALIDATE("Account Type", CostSheet."Bal. Account Type");
                                    GenJnl.VALIDATE("Account No.", CostSheet."Bal. Account No.");
                                    GenJnl.VALIDATE(Description, CostSheet.Description);
                                    GenJnl.VALIDATE("External Document No.", CostSheet."External Document No.");
                                    GenJnl."Source Type" := CostSheet."Account Type";
                                    GenJnl."Source No." := CostSheet."Account No.";
                                    GenJnl."Source Code" := SourceCodeSetup."Landed Cost";
                                    GenJnl.VALIDATE("Currency Code", CostSheet."Currency Code");
                                    GenJnl.VALIDATE(Amount, ROUND(CostSheet.Amount));
                                    GenJnl.VALIDATE("Shortcut Dimension 1 Code", CostSheet."Shortcut Dimension 1 Code");
                                    GenJnl.VALIDATE("Shortcut Dimension 2 Code", CostSheet."Shortcut Dimension 2 Code");
                                    GenJnl."Invoice Received Date" := Pheader."Date Received";//gc
                                    GenJnl.INSERT;

                                    DocDim.RESET;
                                    DocDim.SETRANGE("Table ID", DATABASE::"Landed Cost Sheet");
                                    DocDim.SETRANGE("Document Type", "Document Type");
                                    DocDim.SETRANGE("Document No.", "No.");
                                    DocDim.SETRANGE("Line No.", CostSheet."Line No.");
                                    IF DocDim.FIND('-') THEN
                                        REPEAT
                                            IF JnlLineDim.GET(DATABASE::"Gen. Journal Line", GenJnl."Journal Template Name",
                                                  GenJnl."Journal Batch Name", GenJnl."Line No.", 0, DocDim."Dimension Code") THEN BEGIN
                                                JnlLineDim."Dimension Value Code" := DocDim."Dimension Value Code";
                                                JnlLineDim.MODIFY;
                                            END ELSE BEGIN
                                                JnlLineDim.INIT;
                                                JnlLineDim."Table ID" := DATABASE::"Gen. Journal Line";
                                                JnlLineDim."Journal Template Name" := GenJnl."Journal Template Name";
                                                JnlLineDim."Journal Batch Name" := GenJnl."Journal Batch Name";
                                                JnlLineDim."Journal Line No." := GenJnl."Line No.";
                                                JnlLineDim."Dimension Code" := DocDim."Dimension Code";
                                                JnlLineDim."Dimension Value Code" := DocDim."Dimension Value Code";
                                                JnlLineDim.INSERT;
                                            END;
                                        UNTIL DocDim.NEXT = 0;

                                    LineNo += 10000;

                                    GenJnl.INIT;
                                    GenJnl.VALIDATE("Journal Template Name", PurchSetup."Cost Sheet Journal Template");
                                    GenJnl.VALIDATE("Journal Batch Name", PurchSetup."Cost Sheet Journal Batch");
                                    GenJnl."Line No." := LineNo;
                                    GenJnl.VALIDATE("Posting Date", PurchHeader."Posting Date");
                                    GenJnl.VALIDATE("Document Date", PurchHeader."Document Date");
                                    GenJnl.VALIDATE("Document Type", GenJnl."Document Type"::" ");
                                    /*
                                    IF CostSheet."Account Type" = CostSheet."Account Type"::Vendor THEN BEGIN
                                      CounterVal := CounterVal + 1;
                                      GenJnl."Document Type" := CostSheet."Doc Type"::"Credit Memo";
                                      GenJnl.VALIDATE("External Document No.",CostSheet."External Document No.");
                                      GenJnl.VALIDATE("Document No.",GenJnlLineDocNo + 'OH' + FORMAT(CounterVal));
                                    END
                                    ELSE
                                    */
                                    GenJnl.VALIDATE("Document No.", GenJnlLineDocNo);
                                    GenJnl.VALIDATE("Account Type", CostSheet."Account Type");
                                    GenJnl.VALIDATE("Account No.", CostSheet."Account No.");
                                    GenJnl.VALIDATE(Description, CostSheet.Description);
                                    GenJnl.VALIDATE("External Document No.", CostSheet."External Document No.");
                                    GenJnl."Source Type" := CostSheet."Account Type";
                                    GenJnl."Source No." := CostSheet."Account No.";
                                    GenJnl."Source Code" := SourceCodeSetup."Landed Cost";
                                    GenJnl.VALIDATE("Currency Code", CostSheet."Currency Code");
                                    GenJnl.VALIDATE(Amount, ROUND(-CostSheet.Amount));
                                    GenJnl.VALIDATE("Shortcut Dimension 1 Code", CostSheet."Shortcut Dimension 1 Code");
                                    GenJnl.VALIDATE("Shortcut Dimension 2 Code", CostSheet."Shortcut Dimension 2 Code");
                                    GenJnl."Invoice Received Date" := Pheader."Date Received"; //GC--
                                    GenJnl.INSERT;

                                    DocDim.RESET;
                                    DocDim.SETRANGE("Table ID", DATABASE::"Landed Cost Sheet");
                                    DocDim.SETRANGE("Document Type", "Document Type");
                                    DocDim.SETRANGE("Document No.", "No.");
                                    DocDim.SETRANGE("Line No.", CostSheet."Line No.");
                                    IF DocDim.FIND('-') THEN
                                        REPEAT
                                            IF JnlLineDim.GET(DATABASE::"Gen. Journal Line", GenJnl."Journal Template Name",
                                                  GenJnl."Journal Batch Name", GenJnl."Line No.", 0, DocDim."Dimension Code") THEN BEGIN
                                                JnlLineDim."Dimension Value Code" := DocDim."Dimension Value Code";
                                                JnlLineDim.MODIFY;
                                            END ELSE BEGIN
                                                JnlLineDim.INIT;
                                                JnlLineDim."Table ID" := DATABASE::"Gen. Journal Line";
                                                JnlLineDim."Journal Template Name" := GenJnl."Journal Template Name";
                                                JnlLineDim."Journal Batch Name" := GenJnl."Journal Batch Name";
                                                JnlLineDim."Journal Line No." := GenJnl."Line No.";
                                                JnlLineDim."Dimension Code" := DocDim."Dimension Code";
                                                JnlLineDim."Dimension Value Code" := DocDim."Dimension Value Code";
                                                JnlLineDim.INSERT;
                                            END;
                                        UNTIL DocDim.NEXT = 0;

                                    //APNT-CO2.1 -
                                    //GenJnlPostBatch.RUN(GenJnl);//Commented Olde Code
                                    CLEAR(CostSheet2);
                                    CostSheet2.COPY(CostSheet);
                                    CostSheet2.Posted := TRUE;
                                    CostSheet2.MODIFY;
                                    //APNT-CO2.1 +

                                    LineNo += 10000;
                                END;
                            UNTIL CostSheet.NEXT = 0;
                    END;
        END;

        //APNT-CO2.1 -
        IF LineNo > 10000 THEN
            GenJnlPostBatch.RUN(GenJnl);
        //APNT-CO2.1 +

    end;

    procedure PostCostSheetForPostedDoc(PurchInvHeader: Record "Purch. Inv. Header")
    var
        CostSheet: Record "50000";
        GenJnl: Record "81";
        JnlLineDim: Record "Gen. Journal Line Dimension";
        GenJnlPostBatch: Codeunit "13";
        CounterVal: Integer;
        LineNo: Integer;
        CostSheet2: Record "50000";
    begin
        //APNT-CO2.1 -

        WITH PurchInvHeader DO BEGIN
            SourceCodeSetup.GET;

            GLSetup.GET;
            PurchSetup.GET;
            PurchSetup.TESTFIELD("Cost Sheet Journal Template");
            PurchSetup.TESTFIELD("Cost Sheet Journal Batch");

            GenJnl.RESET;
            GenJnl.SETRANGE("Journal Template Name", PurchSetup."Cost Sheet Journal Template");
            GenJnl.SETRANGE("Journal Batch Name", PurchSetup."Cost Sheet Journal Batch");
            GenJnl.DELETEALL;

            LineNo := 10000;

            CLEAR(GenJnlPostBatch);
            CounterVal := 0;
            CostSheet.RESET;
            CostSheet.SETRANGE(Sequence, Sequence); //APNT-CO2.0

            IF PurchInvHeader."Order No." <> '' THEN BEGIN
                CostSheet.SETRANGE("Document Type", CostSheet."Document Type"::Order);
                CostSheet.SETFILTER("No.", PurchInvHeader."Order No.");
            END ELSE BEGIN
                CostSheet.SETRANGE("Document Type", CostSheet."Document Type"::Invoice);
                CostSheet.SETFILTER("No.", PurchInvHeader."Pre-Assigned No.");
            END;

            CostSheet.SETFILTER(Amount, '<>%1', 0);
            IF CostSheet.FIND('-') THEN
                REPEAT
                    IF NOT CostSheet.Posted THEN BEGIN
                        GenJnl.INIT;
                        GenJnl.VALIDATE("Journal Template Name", PurchSetup."Cost Sheet Journal Template");
                        GenJnl.VALIDATE("Journal Batch Name", PurchSetup."Cost Sheet Journal Batch");
                        GenJnl."Line No." := LineNo;
                        GenJnl.VALIDATE("Posting Date", "Posting Date");
                        GenJnl.VALIDATE("Document Date", "Document Date");
                        GenJnl.VALIDATE("Document Type", GenJnl."Document Type"::" ");
                        GenJnl.VALIDATE("Document No.", "No.");
                        GenJnl.VALIDATE("Account Type", CostSheet."Account Type");
                        GenJnl.VALIDATE("Account No.", CostSheet."Account No.");
                        GenJnl.VALIDATE("External Document No.", CostSheet."External Document No.");
                        GenJnl.VALIDATE(Description, CostSheet.Description);
                        GenJnl."Source Type" := CostSheet."Bal. Account Type";
                        GenJnl."Source No." := CostSheet."Bal. Account No.";
                        GenJnl."Source Code" := SourceCodeSetup."Landed Cost";
                        GenJnl.VALIDATE("Currency Code", CostSheet."Currency Code");
                        GenJnl.VALIDATE(Amount, ROUND(CostSheet.Amount));
                        GenJnl.VALIDATE("Shortcut Dimension 1 Code", CostSheet."Shortcut Dimension 1 Code");
                        GenJnl.VALIDATE("Shortcut Dimension 2 Code", CostSheet."Shortcut Dimension 2 Code");
                        //GC++
                        GenJnl."Invoice Received Date" := PurchInvHeader."Date Received";
                        //GC--
                        GenJnl.INSERT;

                        DocDim.RESET;
                        DocDim.SETRANGE("Table ID", DATABASE::"Landed Cost Sheet");
                        DocDim.SETRANGE("Document Type", CostSheet."Document Type");
                        DocDim.SETRANGE("Document No.", CostSheet."No.");
                        DocDim.SETRANGE("Line No.", CostSheet."Line No.");
                        IF DocDim.FIND('-') THEN
                            REPEAT
                                IF JnlLineDim.GET(DATABASE::"Gen. Journal Line", GenJnl."Journal Template Name",
                                      GenJnl."Journal Batch Name", GenJnl."Line No.", 0, DocDim."Dimension Code") THEN BEGIN
                                    JnlLineDim."Dimension Value Code" := DocDim."Dimension Value Code";
                                    JnlLineDim.MODIFY;
                                END ELSE BEGIN
                                    JnlLineDim.INIT;
                                    JnlLineDim."Table ID" := DATABASE::"Gen. Journal Line";
                                    JnlLineDim."Journal Template Name" := GenJnl."Journal Template Name";
                                    JnlLineDim."Journal Batch Name" := GenJnl."Journal Batch Name";
                                    JnlLineDim."Journal Line No." := GenJnl."Line No.";
                                    JnlLineDim."Dimension Code" := DocDim."Dimension Code";
                                    JnlLineDim."Dimension Value Code" := DocDim."Dimension Value Code";
                                    JnlLineDim.INSERT;
                                END;
                            UNTIL DocDim.NEXT = 0;
                        LineNo += 10000;

                        GenJnl.INIT;
                        GenJnl.VALIDATE("Journal Template Name", PurchSetup."Cost Sheet Journal Template");
                        GenJnl.VALIDATE("Journal Batch Name", PurchSetup."Cost Sheet Journal Batch");
                        GenJnl."Line No." := LineNo;
                        GenJnl.VALIDATE("Posting Date", "Posting Date");
                        GenJnl.VALIDATE("Document Date", "Document Date");
                        GenJnl.VALIDATE("Document Type", GenJnl."Document Type"::" ");
                        GenJnl.VALIDATE("Document No.", "No.");
                        GenJnl.VALIDATE("Account Type", CostSheet."Bal. Account Type");
                        GenJnl.VALIDATE("Account No.", CostSheet."Bal. Account No.");
                        GenJnl.Description := CostSheet.Description;
                        GenJnl.VALIDATE("External Document No.", CostSheet."External Document No.");
                        GenJnl."Source Type" := CostSheet."Bal. Account Type";
                        GenJnl."Source No." := CostSheet."Bal. Account No.";
                        GenJnl."Source Code" := SourceCodeSetup."Landed Cost";
                        GenJnl.VALIDATE("Currency Code", CostSheet."Currency Code");
                        GenJnl.VALIDATE(Amount, ROUND(-CostSheet.Amount));
                        GenJnl.VALIDATE("Shortcut Dimension 1 Code", CostSheet."Shortcut Dimension 1 Code");
                        GenJnl.VALIDATE("Shortcut Dimension 2 Code", CostSheet."Shortcut Dimension 2 Code");

                        //GC++
                        GenJnl."Invoice Received Date" := PurchInvHeader."Date Received";
                        //GC--

                        GenJnl.INSERT;

                        DocDim.RESET;
                        DocDim.SETRANGE("Table ID", DATABASE::"Landed Cost Sheet");
                        DocDim.SETRANGE("Document Type", CostSheet."Document Type");
                        DocDim.SETRANGE("Document No.", CostSheet."No.");
                        DocDim.SETRANGE("Line No.", CostSheet."Line No.");
                        IF DocDim.FIND('-') THEN
                            REPEAT
                                IF JnlLineDim.GET(DATABASE::"Gen. Journal Line", GenJnl."Journal Template Name",
                                      GenJnl."Journal Batch Name", GenJnl."Line No.", 0, DocDim."Dimension Code") THEN BEGIN
                                    JnlLineDim."Dimension Value Code" := DocDim."Dimension Value Code";
                                    JnlLineDim.MODIFY;
                                END ELSE BEGIN
                                    JnlLineDim.INIT;
                                    JnlLineDim."Table ID" := DATABASE::"Gen. Journal Line";
                                    JnlLineDim."Journal Template Name" := GenJnl."Journal Template Name";
                                    JnlLineDim."Journal Batch Name" := GenJnl."Journal Batch Name";
                                    JnlLineDim."Journal Line No." := GenJnl."Line No.";
                                    JnlLineDim."Dimension Code" := DocDim."Dimension Code";
                                    JnlLineDim."Dimension Value Code" := DocDim."Dimension Value Code";
                                    JnlLineDim.INSERT;
                                END;
                            UNTIL DocDim.NEXT = 0;

                        CLEAR(CostSheet2);
                        CostSheet2.COPY(CostSheet);
                        CostSheet2.Posted := TRUE;
                        CostSheet2.MODIFY;
                        LineNo += 10000;
                    END;
                UNTIL CostSheet.NEXT = 0;
        END;

        IF LineNo > 10000 THEN
            GenJnlPostBatch.RUN(GenJnl);
        //APNT-CO2.1 +
    end;

    procedure PostCostSheetForPostedCrMemo(PurchCrMemoHdr: Record "124")
    var
        CostSheet: Record "50000";
        GenJnl: Record "81";
        JnlLineDim: Record "Gen. Journal Line Dimension";
        GenJnlPostBatch: Codeunit "13";
        CounterVal: Integer;
        LineNo: Integer;
        CostSheet2: Record "50000";
    begin
        //APNT-CO2.1 -
        WITH PurchCrMemoHdr DO BEGIN
            SourceCodeSetup.GET;

            GLSetup.GET;
            PurchSetup.GET;
            PurchSetup.TESTFIELD("Cost Sheet Journal Template");
            PurchSetup.TESTFIELD("Cost Sheet Journal Batch");

            GenJnl.RESET;
            GenJnl.SETRANGE("Journal Template Name", PurchSetup."Cost Sheet Journal Template");
            GenJnl.SETRANGE("Journal Batch Name", PurchSetup."Cost Sheet Journal Batch");
            GenJnl.DELETEALL;

            LineNo := 10000;

            CLEAR(GenJnlPostBatch);
            CounterVal := 0;
            CostSheet.RESET;
            CostSheet.SETRANGE(Sequence, Sequence);
            CostSheet.SETRANGE("Document Type", CostSheet."Document Type"::"Credit Memo");
            CostSheet.SETFILTER("No.", "Pre-Assigned No.");
            CostSheet.SETFILTER(Amount, '<>%1', 0);
            IF CostSheet.FIND('-') THEN
                REPEAT
                    IF NOT CostSheet.Posted THEN BEGIN
                        GenJnl.INIT;
                        GenJnl.VALIDATE("Journal Template Name", PurchSetup."Cost Sheet Journal Template");
                        GenJnl.VALIDATE("Journal Batch Name", PurchSetup."Cost Sheet Journal Batch");
                        GenJnl."Line No." := LineNo;
                        GenJnl.VALIDATE("Posting Date", "Posting Date");
                        GenJnl.VALIDATE("Document Date", "Document Date");
                        GenJnl.VALIDATE("Document Type", GenJnl."Document Type"::" ");
                        GenJnl.VALIDATE("Document No.", "No.");
                        GenJnl.VALIDATE("Account Type", CostSheet."Account Type");
                        GenJnl.VALIDATE("Account No.", CostSheet."Account No.");
                        GenJnl.VALIDATE("External Document No.", CostSheet."External Document No.");
                        GenJnl.VALIDATE(Description, CostSheet.Description);
                        GenJnl."Source Type" := CostSheet."Bal. Account Type";
                        GenJnl."Source No." := CostSheet."Bal. Account No.";
                        GenJnl."Source Code" := SourceCodeSetup."Landed Cost";
                        GenJnl.VALIDATE("Currency Code", CostSheet."Currency Code");
                        GenJnl.VALIDATE(Amount, ROUND(CostSheet.Amount));
                        GenJnl.VALIDATE("Shortcut Dimension 1 Code", CostSheet."Shortcut Dimension 1 Code");
                        GenJnl.VALIDATE("Shortcut Dimension 2 Code", CostSheet."Shortcut Dimension 2 Code");
                        GenJnl."Invoice Received Date" := PurchCrMemoHdr."Date Received"; //GC++
                        GenJnl.INSERT;

                        DocDim.RESET;
                        DocDim.SETRANGE("Table ID", DATABASE::"Landed Cost Sheet");
                        DocDim.SETRANGE("Document Type", CostSheet."Document Type");
                        DocDim.SETRANGE("Document No.", CostSheet."No.");
                        DocDim.SETRANGE("Line No.", CostSheet."Line No.");
                        IF DocDim.FIND('-') THEN
                            REPEAT
                                IF JnlLineDim.GET(DATABASE::"Gen. Journal Line", GenJnl."Journal Template Name",
                                      GenJnl."Journal Batch Name", GenJnl."Line No.", 0, DocDim."Dimension Code") THEN BEGIN
                                    JnlLineDim."Dimension Value Code" := DocDim."Dimension Value Code";
                                    JnlLineDim.MODIFY;
                                END ELSE BEGIN
                                    JnlLineDim.INIT;
                                    JnlLineDim."Table ID" := DATABASE::"Gen. Journal Line";
                                    JnlLineDim."Journal Template Name" := GenJnl."Journal Template Name";
                                    JnlLineDim."Journal Batch Name" := GenJnl."Journal Batch Name";
                                    JnlLineDim."Journal Line No." := GenJnl."Line No.";
                                    JnlLineDim."Dimension Code" := DocDim."Dimension Code";
                                    JnlLineDim."Dimension Value Code" := DocDim."Dimension Value Code";
                                    JnlLineDim.INSERT;
                                END;
                            UNTIL DocDim.NEXT = 0;
                        LineNo += 10000;

                        GenJnl.INIT;
                        GenJnl.VALIDATE("Journal Template Name", PurchSetup."Cost Sheet Journal Template");
                        GenJnl.VALIDATE("Journal Batch Name", PurchSetup."Cost Sheet Journal Batch");
                        GenJnl."Line No." := LineNo;
                        GenJnl.VALIDATE("Posting Date", "Posting Date");
                        GenJnl.VALIDATE("Document Date", "Document Date");
                        GenJnl.VALIDATE("Document Type", GenJnl."Document Type"::" ");
                        GenJnl.VALIDATE("Document No.", "No.");
                        GenJnl.VALIDATE("Account Type", CostSheet."Bal. Account Type");
                        GenJnl.VALIDATE("Account No.", CostSheet."Bal. Account No.");
                        GenJnl.Description := CostSheet.Description;
                        GenJnl.VALIDATE("External Document No.", CostSheet."External Document No.");
                        GenJnl."Source Type" := CostSheet."Bal. Account Type";
                        GenJnl."Source No." := CostSheet."Bal. Account No.";
                        GenJnl."Source Code" := SourceCodeSetup."Landed Cost";
                        GenJnl.VALIDATE("Currency Code", CostSheet."Currency Code");
                        GenJnl.VALIDATE(Amount, ROUND(-CostSheet.Amount));
                        GenJnl.VALIDATE("Shortcut Dimension 1 Code", CostSheet."Shortcut Dimension 1 Code");
                        GenJnl.VALIDATE("Shortcut Dimension 2 Code", CostSheet."Shortcut Dimension 2 Code");
                        GenJnl."Invoice Received Date" := PurchCrMemoHdr."Date Received"; //GC++
                        GenJnl.INSERT;

                        DocDim.RESET;
                        DocDim.SETRANGE("Table ID", DATABASE::"Landed Cost Sheet");
                        DocDim.SETRANGE("Document Type", CostSheet."Document Type");
                        DocDim.SETRANGE("Document No.", CostSheet."No.");
                        DocDim.SETRANGE("Line No.", CostSheet."Line No.");
                        IF DocDim.FIND('-') THEN
                            REPEAT
                                IF JnlLineDim.GET(DATABASE::"Gen. Journal Line", GenJnl."Journal Template Name",
                                      GenJnl."Journal Batch Name", GenJnl."Line No.", 0, DocDim."Dimension Code") THEN BEGIN
                                    JnlLineDim."Dimension Value Code" := DocDim."Dimension Value Code";
                                    JnlLineDim.MODIFY;
                                END ELSE BEGIN
                                    JnlLineDim.INIT;
                                    JnlLineDim."Table ID" := DATABASE::"Gen. Journal Line";
                                    JnlLineDim."Journal Template Name" := GenJnl."Journal Template Name";
                                    JnlLineDim."Journal Batch Name" := GenJnl."Journal Batch Name";
                                    JnlLineDim."Journal Line No." := GenJnl."Line No.";
                                    JnlLineDim."Dimension Code" := DocDim."Dimension Code";
                                    JnlLineDim."Dimension Value Code" := DocDim."Dimension Value Code";
                                    JnlLineDim.INSERT;
                                END;
                            UNTIL DocDim.NEXT = 0;

                        CLEAR(CostSheet2);
                        CostSheet2.COPY(CostSheet);
                        CostSheet2.Posted := TRUE;
                        CostSheet2.MODIFY;
                        LineNo += 10000;
                    END;
                UNTIL CostSheet.NEXT = 0;
        END;

        IF LineNo > 10000 THEN
            GenJnlPostBatch.RUN(GenJnl);
        //APNT-CO2.1 +
    end;

    procedure CreateBinLedgerEntries(RecPurchaseHdr: Record "Purchase Header"; PurchRcptHdr: Record "Purch. Rcpt. Header")
    var
        RecPurchaseLine: Record "Purchase Line";
        BinLedgers: Record "50081";
        DocumentBin: Record "50082";
        BinLedgersInsert: Record "50081";
        BinLedgersEntryNo: Record "50081";
        EntryNo: Integer;
        DocumentBinCpy: Record "50082";
    begin
        //APNT-T009914
        CheckBinMandatory(RecPurchaseHdr);
        CLEAR(EntryNo);
        BinLedgersEntryNo.RESET;
        IF BinLedgersEntryNo.FINDLAST THEN
            EntryNo := BinLedgersEntryNo."Entry No." + 1
        ELSE
            EntryNo := 1;

        DocumentBin.RESET;
        DocumentBin.SETRANGE(Type, DocumentBin.Type::GRN);
        DocumentBin.SETRANGE("Document Type", DocumentBin."Document Type"::Order);
        DocumentBin.SETRANGE("Document No.", RecPurchaseHdr."No.");
        DocumentBin.SETRANGE(Posted, FALSE);
        IF DocumentBin.FINDFIRST THEN
            REPEAT
                BinLedgers.RESET;
                BinLedgers.SETRANGE("Barcode No.", DocumentBin."Barcode No.");
                BinLedgers.SETRANGE("Bin Code", DocumentBin."Bin Code");
                IF NOT BinLedgers.FINDFIRST THEN BEGIN
                    BinLedgersInsert.INIT;
                    BinLedgersInsert."Barcode No." := DocumentBin."Barcode No.";
                    BinLedgersInsert."Bin Code" := DocumentBin."Bin Code";
                    BinLedgersInsert."Entry No." := EntryNo;
                    BinLedgersInsert.INSERT;
                    EntryNo += 1;
                END;
                DocumentBinCpy.COPY(DocumentBin);
                DocumentBinCpy.Posted := TRUE;
                DocumentBinCpy."Posting date" := RecPurchaseHdr."Posting Date";
                DocumentBinCpy."Purchase Receipt No." := PurchRcptHdr."No.";
                DocumentBinCpy.MODIFY;
            UNTIL DocumentBin.NEXT = 0;
        //APNT-T009914
    end;

    procedure CheckBinMandatory(RecPHrd: Record "Purchase Header")
    var
        RecPurLine: Record "Purchase Line";
        RecLocation: Record "14";
        RecItem: Record "27";
        RecDoBin: Record "50082";
    begin
        //APNT-T009914
        WITH RecPHrd DO BEGIN
            TESTFIELD("Location Code");
            CLEAR(RecLocation);
            IF RecLocation.GET(RecPHrd."Location Code") THEN;
            RecPurLine.RESET;
            RecPurLine.SETRANGE("Document Type", RecPHrd."Document Type");
            RecPurLine.SETRANGE("Document No.", RecPHrd."No.");
            RecPurLine.SETRANGE(Type, RecPurLine.Type::Item);
            IF RecPurLine.FINDFIRST THEN
                REPEAT
                    CLEAR(RecItem);
                    IF RecItem.GET(RecPurLine."No.") THEN;
                    IF (RecLocation."WMS Active" = TRUE) AND (RecItem."WMS Active" = TRUE) THEN BEGIN
                        IF RecPurLine."Receipt No." = '' THEN BEGIN
                            RecDoBin.RESET;
                            RecDoBin.SETRANGE("Document No.", RecPurLine."Document No.");
                            RecDoBin.SETRANGE("Barcode No.", RecPurLine.Barcode);
                            RecDoBin.SETRANGE("Location Code", RecPurLine."Location Code");
                            RecDoBin.SETRANGE(Posted, FALSE);
                            IF NOT RecDoBin.FINDFIRST THEN BEGIN
                                IF RecPurLine."Qty. to Receive" <> 0 THEN
                                    ERROR('There should be atleast one Bin code for the Barcode %1', RecPurLine.Barcode)
                            END ELSE BEGIN
                                IF RecPurLine."Qty. to Receive" <> 0 THEN BEGIN
                                    IF RecDoBin."Bin Code" = '' THEN
                                        ERROR('There should be atleast one Bin code for the Barcode %1', RecPurLine.Barcode)
                                END;
                            END;
                        END;
                    END;
                UNTIL RecPurLine.NEXT = 0;
        END;
    end;
}

