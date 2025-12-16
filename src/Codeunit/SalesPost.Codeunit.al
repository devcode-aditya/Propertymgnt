codeunit 80 "Sales-Post"
{
    // LS = changes made by LS Retail
    // 
    // LS6.10.00.01-01 StK #LS04-03762#            - Customer Blocking when posting from statement fix.
    // 
    // CODE          DATE      NAME        DESCRIPTION
    // APNT-IC1.0    16.02.12  Tanweer     Added code for IC Customization
    // DP =  changes made by DVS
    // T003898       19.06.14  Shameema    Added code to create actions for sales inv. based on setup
    // T004720       26.08.14  Shameema    Added code for hru document location reference in ledgers
    // APNT-T004576  22.09.14  Sangeeta    Temp Addd error to check if Rev. Gen. prod posting group exists or not
    //                                     while releasing
    // APNT-T006534  12.03.15  Sangeeta    Added code for Warehouse employee posting restrictions.
    // APNT-T006534  23.03.15  Sangeeta    Added code for Warehouse employee posting restrictions for sales & return order
    // T007477       24.06.15  Sangeeta    Added code to filter Qty. to Ship
    // APNT-T007550  05.07.15  Sangeeta    Added code to filter Quantity Shipped.
    // APNT-T018890  16Jan18   Ajay        Modification for VAT Sale Invoice
    // APNT-WMS1.0   19.07.18  Sujith      Added code to clear Qty to ship in case of partial shipment posting only for WMS active location
    // APNT-T027996  02.07.19  Sujith      Modified code for location restriction.
    // T029871       04.11.19  Aarti       Added code for HHT serial/lo no customization
    // SP-03-02-2020           Sumit       Added for reflecting same description as mentioned in Sales Order/Inv./Cr. Memo lines
    //                                     for G/L account in "Gen. Journal Line" table if G/L description is true in GLS (Table 98)
    // APNT-eCom     09.11.20  Sujith      Added code for eCommerce integration.
    // eCom-CR       25.02.21  Sujith      Added field for eCommerce integration CR
    // 20210404      04-Apr-21 KPS         Merged code for allowing SO's having only G/L Accounts to post w/o
    //                                       location restriction OTRS#5797757

    Permissions = TableData 37 = imd,
                  TableData 38 = m,
                  TableData 39 = m,
                  TableData 49 = imd,
                  TableData 110 = imd,
                  TableData 111 = imd,
                  TableData 112 = imd,
                  TableData 113 = imd,
                  TableData 114 = imd,
                  TableData 115 = imd,
                  TableData 120 = imd,
                  TableData 121 = imd,
                  TableData 223 = imd,
                  TableData 252 = imd,
                  TableData 357 = imd,
                  TableData 359 = imd,
                  TableData 6507 = ri,
                  TableData 6508 = rid,
                  TableData 6660 = imd,
                  TableData 6661 = imd;
    TableNo = 36;

    trigger OnRun()
    var
        TempJnlLineDim: Record "Gen. Journal Line Dimension" temporary;
        Opp: Record Opportunity;
        OpportunityEntry: Record "Opportunity Entry";
        ItemEntryRelation: Record "Item Entry Relation";
        TempInvoicingSpecification: Record "Tracking Specification" temporary;
        DummyTrackingSpecification: Record "Tracking Specification";
        ICHandledInboxTransaction: Record "IC Inbox Transaction";
        Cust: Record Customer;
        ICPartner: Record "IC Partner";
        PurchSetup: Record "Purchases & Payables Setup";
        PurchCommentLine: Record "Purch. Comment Line";
        UpdateAnalysisView: Codeunit "410";
        UpdateItemAnalysisView: Codeunit "7150";
        ICInOutBoxMgt: Codeunit "427";
        CostBaseAmount: Decimal;
        TrackingSpecificationExists: Boolean;
        EndLoop: Boolean;
        DocType: Option " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund,Shipment;
        TempJnlLineDim2: Record "Gen. Journal Line Dimension" temporary;
        TempPrePmtAmtToDeduct: Decimal;
        tempSalesInvoiceOff: Boolean;
        TempDocDim2: Record "Document Dimension" temporary;
        GLReg: Record "G/L Register";
        ItemReg: Record "Item Register";
        ICTProcesses: Codeunit "10001416";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICOutboxTransactionNo: Integer;
        ICOutboxExport: Codeunit "IC Outbox Export";
        WorkOrderMgt: Codeunit "Work Order Management";
        PremiseMgmtSetup: Record "Premise Management Setup";
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseEmployee2: Record "Warehouse Employee";
        SalesLine2: Record "Sales Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ReleaseSalesDoc: Codeunit "Release Sales Document";
        InventorySetup: Record "Inventory Setup";
        PrevUnitPrice: Decimal;
        RecLocation: Record Location;
        RecSalesLine: Record "Sales Line";
        HHTTransactions: Record "HHT Transactions";
        HHTTransHdr: Record "HHT Trans Hdr";
        eComProcessUtility: Codeunit "eCom Process Utility";
        eComCustomerOrderStatusL: Record "eCom Customer Order Status L";
        eEntryNo: Integer;
    begin
        IF PostingDateExists AND (ReplacePostingDate OR ("Posting Date" = 0D)) THEN BEGIN
            "Posting Date" := PostingDate;
            VALIDATE("Currency Code");
        END;

        //>> 02210404 Merged by KPS on 04-Apr-2021 OTRS#5797757
        //APNT-T006534 -
        SalesLine2.RESET;
        SalesLine2.SETFILTER("Document Type", '%1|%2', SalesLine2."Document Type"::Order,
        SalesLine2."Document Type"::"Return Order");
        SalesLine2.SETRANGE("Document No.", "No.");
        SalesLine2.SETFILTER(Type, '<>%1&<>%2', SalesLine2.Type::" ", SalesLine2.Type::"G/L Account");
        IF SalesLine2.FINDFIRST THEN
            CheckLines := TRUE;
        //<< End of merging by KPS on 04-Apr-2021

        //APNT-T006534 -
        CLEAR(InvtSetup);
        InvtSetup.GET;
        IF InvtSetup."Restrict Order Posting" THEN BEGIN  //APNT-T027996
            WarehouseEmployee.RESET;
            WarehouseEmployee.SETRANGE("User ID", USERID);
            IF WarehouseEmployee.FINDFIRST THEN BEGIN
                CLEAR(SalesLine2);
                SalesLine2.RESET;
                SalesLine2.SETFILTER("Document Type", '%1|%2', SalesLine2."Document Type"::Order, SalesLine2."Document Type"::"Return Order");
                SalesLine2.SETRANGE("Document No.", "No.");
                IF "Document Type" = "Document Type"::Order THEN
                    SalesLine2.SETFILTER("Qty. to Ship", '<>%1', 0)
                ELSE
                    IF "Document Type" = "Document Type"::"Return Order" THEN
                        SalesLine2.SETFILTER("Return Qty. to Receive", '<>%1', 0);
                IF SalesLine2.FINDFIRST THEN
                    REPEAT
                        WarehouseEmployee2.RESET;
                        WarehouseEmployee2.SETRANGE("User ID", USERID);
                        WarehouseEmployee2.SETFILTER("Location Code", '%1|%2', SalesLine2."Location Code", '');//APNT-T027996
                        WarehouseEmployee2.SETRANGE(Sales, TRUE);
                        IF NOT WarehouseEmployee2.FINDFIRST THEN
                            ERROR('You do not have permissions to post Sales %2 %1.', "No.", SalesLine2."Document Type"); //APNT-T027996
                    UNTIL SalesLine2.NEXT = 0;
            END ELSE
                ERROR('You do not have permissions to post Sales %2 %1.', "No.", "Document Type");//APNT-T027996
        END;

        IF "HRU Document" = TRUE THEN BEGIN
            CLEAR(SalesLine2);
            SalesLine2.RESET;
            SalesLine2.SETRANGE("Document Type", "Document Type");
            SalesLine2.SETRANGE("Document No.", "No.");
            SalesLine2.SETFILTER("Transfer Order No.", '<>%1', '');
            SalesLine2.SETFILTER("Qty. to Ship", '<>%1', 0);//APNT-T007477
            SalesLine2.SETFILTER("Quantity Shipped", '%1', 0);//APNT-T007550
            IF SalesLine2.FINDFIRST THEN
                REPEAT
                    IF TransferLine.GET(SalesLine2."Transfer Order No.", SalesLine2."Transfer Order Line No.") THEN
                        IF TransferLine."Quantity Received" = 0 THEN
                            ERROR('Transfer Order No. %1 is linked to Sales Order No. %2. Kindly post Transfer Order before posting Sales Order.'
                                      , SalesLine2."Transfer Order No.", "No.");
                UNTIL SalesLine2.NEXT = 0;
        END;
        //APNT-T006534 +

        //APNT-VAT1.0
        IF ("HRU Document" = TRUE) AND ("Transaction Posted" = TRUE) AND ("SO Lines Reversed" = TRUE) THEN BEGIN
            InventorySetup.GET;
            InventorySetup.TESTFIELD("VAT Prod. Post. Grp - Reversal");
            ReleaseSalesDoc.PerformManualReopen(Rec);
            CLEAR(SalesLine2);
            SalesLine2.RESET;
            SalesLine2.SETRANGE("Document Type", "Document Type");
            SalesLine2.SETRANGE("Document No.", "No.");
            IF SalesLine2.FINDFIRST THEN
                REPEAT
                    CLEAR(PrevUnitPrice);
                    PrevUnitPrice := SalesLine2."Unit Price";
                    SalesLine2.VALIDATE("VAT Prod. Posting Group", InventorySetup."VAT Prod. Post. Grp - Reversal");
                    SalesLine2.VALIDATE("Unit Price", PrevUnitPrice);
                    SalesLine2.MODIFY;
                UNTIL SalesLine2.NEXT = 0;
            ReleaseSalesDoc.PerformManualRelease(Rec);
        END;
        //APNT-VAT1.0

        IF PostingDateExists AND (ReplaceDocumentDate OR ("Document Date" = 0D)) THEN
            VALIDATE("Document Date", PostingDate);

        CLEARALL;

        //LS -
        gNotShowDialog := "Not Show Dialog";

        IF tempStatement.FIND('-') THEN
            FromStatement := TRUE
        ELSE
            FromStatement := FALSE;

        IF NOT "SPO-Created Entry" THEN
            TESTFIELD("Retail Special Order", FALSE);
        //LS +

        SalesHeader := Rec;
        ServiceItemTmp2.DELETEALL;
        ServiceItemCmpTmp2.DELETEALL;
        WITH SalesHeader DO BEGIN
            TESTFIELD("Document Type");
            TESTFIELD("Sell-to Customer No.");
            TESTFIELD("Bill-to Customer No.");
            TESTFIELD("Posting Date");
            TESTFIELD("Document Date");
            IF GenJnlCheckLine.DateNotAllowed("Posting Date") THEN
                FIELDERROR("Posting Date", Text045);

            CASE "Document Type" OF
                "Document Type"::Order:
                    Receive := FALSE;
                "Document Type"::Invoice:
                    BEGIN
                        Ship := TRUE;
                        Invoice := TRUE;
                        Receive := FALSE;
                    END;
                "Document Type"::"Return Order":
                    Ship := FALSE;
                "Document Type"::"Credit Memo":
                    BEGIN
                        Ship := FALSE;
                        Invoice := TRUE;
                        Receive := TRUE;
                    END;
            END;

            IF NOT (Ship OR Invoice OR Receive) THEN
                ERROR(
                  Text020,
                  FIELDCAPTION(Ship), FIELDCAPTION(Invoice), FIELDCAPTION(Receive));
            /*
            //APNT-T009914
            IF Receive THEN
              CreateBinLedgerEntries(SalesHeader);
            //APNT-T009914
            */
            WhseReference := "Posting from Whse. Ref.";
            "Posting from Whse. Ref." := 0;

            //APNT-eCom +
            IF SalesHeader."eCOM Order" AND ("Document Type" = "Document Type"::Order) THEN BEGIN
                IF Ship AND Invoice THEN BEGIN
                    IF eComProcessCustomerOrders.CheckAllLinesShipped(SalesHeader, FALSE) THEN
                        ERROR(Txt10002, Rec."No.");
                END ELSE
                    IF Invoice THEN BEGIN
                        IF eComProcessCustomerOrders.CheckAllLinesShipped(SalesHeader, TRUE) THEN
                            ERROR(Txt10001, Rec."No.");
                    END;
            END;
            //APNT-eCom -

            GLSetup.GET;  //LS
            IF Invoice THEN
                CreatePrepaymentLines(SalesHeader, TempPrepaymentSalesLine, PrepmtDocDim, TRUE);
            CopyAndCheckDocDimToTempDocDim;

            CopyAprvlToTempApprvl;

            SalesSetup.GET;
            Cust.GET("Sell-to Customer No.");

            IF NOT FromStatement THEN BEGIN  //LS6.10.00.01-01
                IF Receive THEN
                    Cust.CheckBlockedCustOnDocs(Cust, "Document Type", FALSE, TRUE)
                ELSE BEGIN
                    IF Ship AND
                       ("Document Type" = "Document Type"::Order) OR
                       (("Document Type" = "Document Type"::Invoice) AND SalesSetup."Shipment on Invoice")
                    THEN BEGIN
                        SalesLine.RESET;
                        SalesLine.SETRANGE("Document Type", "Document Type");
                        SalesLine.SETRANGE("Document No.", "No.");
                        SalesLine.SETFILTER(SalesLine."Qty. to Ship", '<>0');
                        SalesLine.SETRANGE("Shipment No.", '');
                        IF NOT SalesLine.ISEMPTY THEN
                            Cust.CheckBlockedCustOnDocs(Cust, "Document Type", TRUE, TRUE);
                    END ELSE
                        Cust.CheckBlockedCustOnDocs(Cust, "Document Type", FALSE, TRUE);
                END;

                IF "Bill-to Customer No." <> "Sell-to Customer No." THEN BEGIN
                    Cust.GET("Bill-to Customer No.");
                    IF Receive THEN
                        Cust.CheckBlockedCustOnDocs(Cust, "Document Type", FALSE, TRUE)
                    ELSE BEGIN
                        IF Ship THEN BEGIN
                            SalesLine.RESET;
                            SalesLine.SETRANGE("Document Type", "Document Type");
                            SalesLine.SETRANGE("Document No.", "No.");
                            SalesLine.SETFILTER(SalesLine."Qty. to Ship", '<>0');
                            IF NOT SalesLine.ISEMPTY THEN
                                Cust.CheckBlockedCustOnDocs(Cust, "Document Type", TRUE, TRUE);
                        END ELSE
                            Cust.CheckBlockedCustOnDocs(Cust, "Document Type", FALSE, TRUE);
                    END;
                END;
            END;  //LS6.10.00.01-01

            IF Invoice THEN BEGIN
                SalesLine.RESET;
                SalesLine.SETRANGE("Document Type", "Document Type");
                SalesLine.SETRANGE("Document No.", "No.");
                SalesLine.SETFILTER(Quantity, '<>0');
                IF "Document Type" IN ["Document Type"::Order, "Document Type"::"Return Order"] THEN
                    SalesLine.SETFILTER("Qty. to Invoice", '<>0');
                Invoice := NOT SalesLine.ISEMPTY;
                IF Invoice AND (NOT Ship) AND ("Document Type" = "Document Type"::Order) THEN BEGIN
                    SalesLine.FINDSET;
                    Invoice := FALSE;
                    REPEAT
                        Invoice := SalesLine."Quantity Shipped" - SalesLine."Quantity Invoiced" <> 0;
                    UNTIL Invoice OR (SalesLine.NEXT = 0);
                END ELSE
                    IF Invoice AND (NOT Receive) AND ("Document Type" = "Document Type"::"Return Order") THEN BEGIN
                        SalesLine.FINDSET;
                        Invoice := FALSE;
                        REPEAT
                            Invoice := SalesLine."Return Qty. Received" - SalesLine."Quantity Invoiced" <> 0;
                        UNTIL Invoice OR (SalesLine.NEXT = 0);
                    END;
            END;
            IF Invoice THEN
                CopyAndCheckItemCharge(SalesHeader);

            IF Ship THEN BEGIN
                SalesLine.RESET;
                SalesLine.SETRANGE("Document Type", "Document Type");
                SalesLine.SETRANGE("Document No.", "No.");
                SalesLine.SETFILTER(Quantity, '<>0');
                IF "Document Type" = "Document Type"::Order THEN
                    SalesLine.SETFILTER("Qty. to Ship", '<>0');
                SalesLine.SETRANGE("Shipment No.", '');
                Ship := SalesLine.FINDFIRST;
                WhseShip := TempWhseShptHeader.FINDFIRST;
                WhseReceive := TempWhseRcptHeader.FINDFIRST;
                InvtPickPutaway := WhseReference <> 0;
                IF Ship THEN
                    CheckTrackingSpecification(SalesLine);
                IF Ship AND NOT (WhseShip OR WhseReceive OR InvtPickPutaway) THEN
                    CheckWarehouse(SalesLine);
            END;

            IF Receive THEN BEGIN
                SalesLine.RESET;
                SalesLine.SETRANGE("Document Type", "Document Type");
                SalesLine.SETRANGE("Document No.", "No.");
                SalesLine.SETFILTER(Quantity, '<>0');
                SalesLine.SETFILTER("Return Qty. to Receive", '<>0');
                SalesLine.SETRANGE("Return Receipt No.", '');
                Receive := SalesLine.FINDFIRST;
                WhseShip := TempWhseShptHeader.FINDFIRST;
                WhseReceive := TempWhseRcptHeader.FINDFIRST;
                InvtPickPutaway := WhseReference <> 0;
                IF Receive THEN
                    CheckTrackingSpecification(SalesLine);
                IF Receive AND NOT (WhseReceive OR WhseShip OR InvtPickPutaway) THEN
                    CheckWarehouse(SalesLine);
            END;

            IF NOT (Ship OR Invoice OR Receive) THEN
                IF NOT OnlyAssgntPosting THEN
                    ERROR(Text001);

            IF ("Shipping Advice" = "Shipping Advice"::Complete) AND
               SalesLine.IsShipment
            THEN
                IF NOT GetShippingAdvice THEN
                    ERROR(Text023);

            IF Invoice THEN BEGIN
                IF NOT ("Document Type" IN ["Document Type"::"Return Order", "Document Type"::"Credit Memo"]) THEN
                    TESTFIELD("Due Date");
                IF ShowDialog THEN  //LS
                    Window.OPEN(
                      '#1#################################\\' +
                      Text002 +
                      Text003 +
                      Text004 +
                      Text005)
            END ELSE
                IF ShowDialog THEN  //LS
                    Window.OPEN(
                      '#1#################################\\' +
                      Text006);

            IF ShowDialog THEN  //LS
                Window.UPDATE(1, STRSUBSTNO('%1 %2', "Document Type", "No."));

            //GLSetup.GET;  //LS
            GetCurrency;

            IF Ship AND ("Shipping No." = '') THEN
                IF ("Document Type" = "Document Type"::Order) OR
                   (("Document Type" = "Document Type"::Invoice) AND SalesSetup."Shipment on Invoice")
                THEN BEGIN
                    TESTFIELD("Shipping No. Series");
                    "Shipping No." := NoSeriesMgt.GetNextNo("Shipping No. Series", "Posting Date", TRUE);
                    ModifyHeader := TRUE;
                END;

            IF Receive AND ("Return Receipt No." = '') THEN
                IF ("Document Type" = "Document Type"::"Return Order") OR
                   (("Document Type" = "Document Type"::"Credit Memo") AND SalesSetup."Return Receipt on Credit Memo")
                THEN BEGIN
                    TESTFIELD("Return Receipt No. Series");
                    "Return Receipt No." := NoSeriesMgt.GetNextNo("Return Receipt No. Series", "Posting Date", TRUE);
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
                SalesLine.RESET;
                SalesLine.SETRANGE("Document Type", "Document Type");
                SalesLine.SETRANGE("Document No.", "No.");
                SalesLine.SETFILTER("Purch. Order Line No.", '<>0');
                IF NOT SalesLine.ISEMPTY THEN BEGIN
                    DropShipOrder := TRUE;
                    IF Ship THEN BEGIN
                        SalesLine.FINDSET;
                        REPEAT
                            IF PurchOrderHeader."No." <> SalesLine."Purchase Order No." THEN BEGIN
                                PurchOrderHeader.GET(
                                  PurchOrderHeader."Document Type"::Order,
                                  SalesLine."Purchase Order No.");
                                PurchOrderHeader.TESTFIELD("Pay-to Vendor No.");
                                IF PurchOrderHeader."Receiving No." = '' THEN BEGIN
                                    PurchOrderHeader.TESTFIELD("Receiving No. Series");
                                    PurchOrderHeader."Receiving No." :=
                                      NoSeriesMgt.GetNextNo(PurchOrderHeader."Receiving No. Series", "Posting Date", TRUE);
                                    PurchOrderHeader.MODIFY;
                                    ModifyHeader := TRUE;
                                END;
                            END;
                        UNTIL SalesLine.NEXT = 0;
                    END;
                END;
            END;
            IF ModifyHeader THEN BEGIN
                MODIFY;
                IF (NOT FromStatement) AND (NOT "SPO-Created Entry") THEN //LS
                    COMMIT;
            END;

            IF SalesSetup."Calc. Inv. Discount" AND
               (Status <> Status::Open) AND
               NOT ItemChargeAssgntOnly
            THEN BEGIN
                SalesLine.RESET;
                SalesLine.SETRANGE("Document Type", "Document Type");
                SalesLine.SETRANGE("Document No.", "No.");
                SalesLine.FINDFIRST;
                TempInvoice := Invoice;
                TempShpt := Ship;
                TempReturn := Receive;
                SalesCalcDisc.RUN(SalesLine);
                GET("Document Type", "No.");
                Invoice := TempInvoice;
                Ship := TempShpt;
                Receive := TempReturn;
                IF (NOT FromStatement) AND (NOT "SPO-Created Entry") THEN //LS
                    COMMIT;
            END;

            IF (Status = Status::Open) OR (Status = Status::"Pending Prepayment") THEN BEGIN
                TempInvoice := Invoice;
                TempShpt := Ship;
                TempReturn := Receive;
                //LS -
                IF FromStatement AND SalesSetup."Calc. Inv. Discount" THEN BEGIN
                    SalesSetup."Calc. Inv. Discount" := FALSE;
                    SalesSetup.MODIFY;
                    tempSalesInvoiceOff := TRUE;
                END;
                //LS +
                CODEUNIT.RUN(CODEUNIT::"Release Sales Document", SalesHeader);
                //LS -
                IF tempSalesInvoiceOff THEN BEGIN
                    SalesSetup.GET;
                    SalesSetup."Calc. Inv. Discount" := TRUE;
                    SalesSetup.MODIFY;
                    tempSalesInvoiceOff := FALSE;
                END;
                //LS +
                Status := Status::Open;
                Invoice := TempInvoice;
                Ship := TempShpt;
                Receive := TempReturn;
                MODIFY;
                IF (NOT FromStatement) AND (NOT "SPO-Created Entry") THEN //LS
                    COMMIT;
                Status := Status::Released;
            END;

            IF (NOT FromStatement) AND (NOT "SPO-Created Entry") THEN //LS
                IF Ship OR Receive THEN
                    ArchiveUnpostedOrder; // has a COMMIT;

            IF (SalesHeader."Sell-to IC Partner Code" <> '') AND (ICPartner.GET(SalesHeader."Sell-to IC Partner Code")) THEN
                ICPartner.TESTFIELD(Blocked, FALSE);
            IF (SalesHeader."Bill-to IC Partner Code" <> '') AND (ICPartner.GET(SalesHeader."Bill-to IC Partner Code")) THEN
                ICPartner.TESTFIELD(Blocked, FALSE);
            IF "Send IC Document" AND ("IC Status" = "IC Status"::New) AND ("IC Direction" = "IC Direction"::Outgoing) AND
               ("Document Type" IN ["Document Type"::Order, "Document Type"::"Return Order"])
            THEN BEGIN
                //APNT-IC1.0
                /*
                ICInOutBoxMgt.SendSalesDoc(Rec,TRUE);
                "IC Status" := "IC Status"::Pending;
                ModifyHeader := TRUE;
                */
                CLEAR(ICTransactionNo);
                IF ICPartner."Auto Post Outbox Transactions" THEN BEGIN
                    CLEAR(ICOutboxExport);
                    ICDirection := ICDirection::Outgoing;
                    ICTransactionNo := ICInOutBoxMgt.SendandPostSalesDoc(Rec, TRUE);
                    ICOutboxExport.AutoPostICOutbocTransaction(ICTransactionNo);
                    "IC Status" := "IC Status"::Sent;
                    ModifyHeader := TRUE;
                END ELSE BEGIN
                    ICDirection := ICDirection::Outgoing;
                    ICTransactionNo := ICInOutBoxMgt.SendandPostSalesDoc(Rec, TRUE);
                    "IC Status" := "IC Status"::Pending;
                    ModifyHeader := TRUE;
                END;
                //APNT-IC1.0
            END;
            IF "IC Direction" = "IC Direction"::Incoming THEN BEGIN
                ICHandledInboxTransaction.SETRANGE("Document No.", SalesHeader."External Document No.");
                Cust.GET(SalesHeader."Sell-to Customer No.");
                ICHandledInboxTransaction.SETRANGE("IC Partner Code", Cust."IC Partner Code");
                ICHandledInboxTransaction.LOCKTABLE;
                IF ICHandledInboxTransaction.FINDFIRST THEN BEGIN
                    ICHandledInboxTransaction.Status := ICHandledInboxTransaction.Status::Posted;
                    ICHandledInboxTransaction.MODIFY;
                END;
            END;

            IF RECORDLEVELLOCKING THEN BEGIN
                DocDim.LOCKTABLE;
                SalesLine.LOCKTABLE;
                ItemChargeAssgntSales.LOCKTABLE;
                PurchOrderLine.LOCKTABLE;
                PurchOrderHeader.LOCKTABLE;
                GLEntry.LOCKTABLE;
                IF GLEntry.FINDLAST THEN;
            END;

            SourceCodeSetup.GET;
            SrcCode := SourceCodeSetup.Sales;

            //LS -
            IF BOUtils.IsInStorePermitted() THEN
                CASE SalesHeader."Document Type" OF
                    SalesHeader."Document Type"::Order:
                        InStoreMgt.SendSalesDocShip(SalesHeader);
                    SalesHeader."Document Type"::"Return Order":
                        InStoreMgt.SendSalesDocReceive(SalesHeader);
                END;
            //LS +

            //DP6.01.01 START
            IF "Ref. Document No." <> '' THEN BEGIN
                PremiseMgmtSetup.GET;
                SrcCode := PremiseMgmtSetup."Default Source Code";
            END;
            //DP6.01.01 STOP

            // Insert shipment header
            IF Ship THEN BEGIN
                IF ("Document Type" = "Document Type"::Order) OR
                   (("Document Type" = "Document Type"::Invoice) AND SalesSetup."Shipment on Invoice")
                THEN BEGIN
                    IF DropShipOrder THEN BEGIN
                        PurchRcptHeader.LOCKTABLE;
                        PurchRcptLine.LOCKTABLE;
                        SalesShptHeader.LOCKTABLE;
                        SalesShptLine.LOCKTABLE;
                    END;
                    SalesShptHeader.INIT;
                    SalesShptHeader.TRANSFERFIELDS(SalesHeader);

                    SalesShptHeader."Date Sent" := 0D;
                    SalesShptHeader."Time Sent" := 0T;

                    SalesShptHeader."No." := "Shipping No.";
                    IF "Document Type" = "Document Type"::Order THEN BEGIN
                        SalesShptHeader."Order No. Series" := "No. Series";
                        SalesShptHeader."Order No." := "No.";
                        IF SalesSetup."Ext. Doc. No. Mandatory" THEN
                            TESTFIELD("External Document No.");
                    END;
                    //LS -
                    IF SalesHeader."Source Code" <> '' THEN
                        SalesShptHeader."Source Code" := SalesHeader."Source Code"
                    ELSE
                        //LS +
                        SalesShptHeader."Source Code" := SrcCode;
                    //LS -
                    SalesHeader.CALCFIELDS("Retail Zones Description");
                    SalesShptHeader."Retail Zones Description" := SalesHeader."Retail Zones Description";
                    //LS +
                    SalesShptHeader."User ID" := USERID;
                    SalesShptHeader."No. Printed" := 0;
                    //APNT-VAN1.0 +
                    SalesShptHeader."VAN Sales Order" := SalesHeader."VAN Sales Order";
                    ///////////SalesShptHeader."Push to VAN" := SalesHeader."Push to VAN";
                    //APNT-VAN1.0 -
                    //>> 20230818 Added by KPS on 18-Aug-2023
                    SalesHeader.GetLastEComStatusEntryNo(SalesHeader."No.", gintMAGLastEntryNo, gtxtMAGLastStatus);
                    SalesShptHeader."Magento Last Entry No" := gintMAGLastEntryNo;
                    SalesShptHeader."Magento Last Status" := gtxtMAGLastStatus;
                    //<< 20230818 End of addition by KPS on 18-Aug-2023
                    SalesShptHeader.INSERT;
                    //APNT-eCom -
                    IF SalesHeader."eCOM Order" THEN BEGIN
                        CLEAR(eComCustomerOrderStatus);
                        eComCustomerOrderStatus.RESET;
                        eComCustomerOrderStatus.SETRANGE("Document ID", SalesHeader."No.");
                        IF eComCustomerOrderStatus.FINDLAST THEN BEGIN
                            IF eComProcessCustomerOrders.CheckAllLinesShipped(SalesHeader, FALSE) THEN
                                eComCustomerOrderStatus."NAV-Status" := 'Shipment Posted Partially'
                            ELSE
                                eComCustomerOrderStatus."NAV-Status" := 'Shipment Posted';
                            eComCustomerOrderStatus.MODIFY;
                        END;
                    END;
                    //APNT-eCom +
                    //LS -
                    IF SalesHeader."Only Two Dimensions" THEN BEGIN
                        TempDocDim.SETRANGE(TempDocDim."Table ID", DATABASE::"Sales Header");
                        TempDocDim.SETRANGE(TempDocDim."Line No.", 0);
                        DimMgt.MoveDocDimToPostedDocDim(TempDocDim, DATABASE::"Sales Shipment Header", SalesShptHeader."No.");
                    END ELSE BEGIN
                        //LS +
                        DimMgt.MoveOneDocDimToPostedDocDim(
                          TempDocDim, DATABASE::"Sales Header", "Document Type", "No.", 0,
                          DATABASE::"Sales Shipment Header", SalesShptHeader."No.");
                    END;  //LS
                    ApprovalMgt.MoveApprvalEntryToPosted(TempApprovalEntry, DATABASE::"Sales Shipment Header", SalesShptHeader."No.");

                    IF SalesSetup."Copy Comments Order to Shpt." THEN BEGIN
                        CopyCommentLines(
                          "Document Type", SalesCommentLine."Document Type"::Shipment,
                          "No.", SalesShptHeader."No.");
                        SalesShptHeader.COPYLINKS(Rec);
                    END;
                    IF WhseShip THEN BEGIN
                        WhseShptHeader.GET(TempWhseShptHeader."No.");
                        WhsePostShpt.CreatePostedShptHeader(
                          PostedWhseShptHeader, WhseShptHeader, "Shipping No.", "Posting Date");
                    END;
                    IF WhseReceive THEN BEGIN
                        WhseRcptHeader.GET(TempWhseRcptHeader."No.");
                        WhsePostRcpt.CreatePostedRcptHeader(
                          PostedWhseRcptHeader, WhseRcptHeader, "Shipping No.", "Posting Date");
                    END;
                END;

                ServItemMgt.CopyReservationEntry(SalesHeader);

                IF ("Document Type" = "Document Type"::Invoice) AND
                   (NOT SalesSetup."Shipment on Invoice")
                THEN
                    ServItemMgt.CreateServItemOnSalesInvoice(SalesHeader);
            END;

            // Insert return receipt header
            IF Receive THEN
                IF ("Document Type" = "Document Type"::"Return Order") OR
                   (("Document Type" = "Document Type"::"Credit Memo") AND SalesSetup."Return Receipt on Credit Memo")
                THEN BEGIN
                    ReturnRcptHeader.INIT;
                    ReturnRcptHeader.TRANSFERFIELDS(SalesHeader);
                    ReturnRcptHeader."No." := "Return Receipt No.";
                    IF "Document Type" = "Document Type"::"Return Order" THEN BEGIN
                        ReturnRcptHeader."Return Order No. Series" := "No. Series";
                        ReturnRcptHeader."Return Order No." := "No.";
                        IF SalesSetup."Ext. Doc. No. Mandatory" THEN
                            TESTFIELD("External Document No.");
                    END;
                    ReturnRcptHeader."No. Series" := "Return Receipt No. Series";
                    ReturnRcptHeader."Source Code" := SrcCode;
                    ReturnRcptHeader."User ID" := USERID;
                    ReturnRcptHeader."No. Printed" := 0;
                    ReturnRcptHeader.INSERT(TRUE);
                    //APNT-T009914
                    //CreateBinLedgerEntriesSReturn(SalesHeader,ReturnRcptHeader);
                    //APNT-T009914
                    //APNT-eCom -
                    IF (SalesHeader."Document Type" = SalesHeader."Document Type"::"Credit Memo") OR
                    (SalesHeader."Document Type" = SalesHeader."Document Type"::"Return Order") THEN BEGIN
                        IF SalesHeader."eCOM Order" THEN BEGIN
                            CLEAR(eComCustomerOrderStatus);
                            eComCustomerOrderStatus.RESET;
                            eComCustomerOrderStatus.SETRANGE("Document ID", SalesHeader."No.");
                            IF eComCustomerOrderStatus.FINDLAST THEN BEGIN
                                CLEAR(eEntryNo);
                                eComCustomerOrderStatusL.RESET;
                                IF eComCustomerOrderStatusL.FINDLAST THEN
                                    eEntryNo := eComCustomerOrderStatusL."Entry No." + 1
                                ELSE
                                    eEntryNo := 1;

                                eComCustomerOrderStatusL.INIT;
                                eComCustomerOrderStatusL."Entry No." := eEntryNo;
                                eComCustomerOrderStatusL."Document ID" := eComCustomerOrderStatus."Document ID";
                                eComCustomerOrderStatusL."Status Source" := eComCustomerOrderStatusL."Status Source"::NAV;
                                eComCustomerOrderStatusL."NAV-Status" := 'Return Received';
                                eComCustomerOrderStatusL."Date Created" := TODAY;
                                eComCustomerOrderStatusL.INSERT;
                                eComProcessUtility.CreateLog(eComCustomerOrderStatus, 'Processed');
                            END;
                            ReturnRcptHeader."eCom Original Sales Order No." := SalesHeader."eCom Original Sales Order No.";
                            //eCom-CR +
                            CLEAR(SalesInvoiceHeader);
                            SalesInvoiceHeader.RESET;
                            SalesInvoiceHeader.SETRANGE("Order No.", SalesHeader."eCom Original Sales Order No.");
                            IF SalesInvoiceHeader.FINDFIRST THEN
                                ReturnRcptHeader."eCom Original Sales Invoice No" := SalesInvoiceHeader."No.";
                            //eCom-CR +
                        END;
                    END;
                    //APNT-eCom +

                    //LS -
                    IF SalesHeader."Only Two Dimensions" THEN BEGIN
                        TempDocDim.SETRANGE(TempDocDim."Table ID", DATABASE::"Sales Header");
                        TempDocDim.SETRANGE(TempDocDim."Line No.", 0);
                        DimMgt.MoveDocDimToPostedDocDim(TempDocDim, DATABASE::"Return Receipt Header", ReturnRcptHeader."No.");
                    END ELSE BEGIN
                        //LS +
                        DimMgt.MoveOneDocDimToPostedDocDim(
                          TempDocDim, DATABASE::"Sales Header", "Document Type", "No.", 0,
                          DATABASE::"Return Receipt Header", ReturnRcptHeader."No.");
                    END;  //LS

                    ApprovalMgt.MoveApprvalEntryToPosted(TempApprovalEntry, DATABASE::"Return Receipt Header", ReturnRcptHeader."No.");

                    IF SalesSetup."Copy Cmts Ret.Ord. to Ret.Rcpt" THEN BEGIN
                        CopyCommentLines(
                          "Document Type", SalesCommentLine."Document Type"::"Posted Return Receipt",
                          "No.", ReturnRcptHeader."No.");
                        ReturnRcptHeader.COPYLINKS(Rec);
                    END;
                    IF WhseReceive THEN BEGIN
                        WhseRcptHeader.GET(TempWhseRcptHeader."No.");
                        WhsePostRcpt.CreatePostedRcptHeader(PostedWhseRcptHeader, WhseRcptHeader, "Return Receipt No.", "Posting Date");
                    END;
                    IF WhseShip THEN BEGIN
                        WhseShptHeader.GET(TempWhseShptHeader."No.");
                        WhsePostShpt.CreatePostedShptHeader(PostedWhseShptHeader, WhseShptHeader, "Return Receipt No.", "Posting Date");
                    END;
                END;

            // Insert invoice header or credit memo header
            IF Invoice THEN
                IF "Document Type" IN ["Document Type"::Order, "Document Type"::Invoice] THEN BEGIN
                    SalesInvHeader.INIT;
                    SalesInvHeader.TRANSFERFIELDS(SalesHeader);

                    SalesInvHeader."Date Sent" := 0D;
                    SalesInvHeader."Time Sent" := 0T;

                    IF "Document Type" = "Document Type"::Order THEN BEGIN
                        SalesInvHeader."No." := "Posting No.";
                        IF SalesSetup."Ext. Doc. No. Mandatory" THEN
                            TESTFIELD("External Document No.");
                        SalesInvHeader."Pre-Assigned No. Series" := '';
                        SalesInvHeader."Order No. Series" := "No. Series";
                        SalesInvHeader."Order No." := "No.";
                        IF ShowDialog THEN  //LS
                            Window.UPDATE(1, STRSUBSTNO(Text007, "Document Type", "No.", SalesInvHeader."No."));
                    END ELSE BEGIN
                        SalesInvHeader."Pre-Assigned No. Series" := "No. Series";
                        SalesInvHeader."Pre-Assigned No." := "No.";
                        IF "Posting No." <> '' THEN BEGIN
                            SalesInvHeader."No." := "Posting No.";
                            IF ShowDialog THEN  //LS
                                Window.UPDATE(1, STRSUBSTNO(Text007, "Document Type", "No.", SalesInvHeader."No."));
                        END;
                    END;
                    //LS -
                    IF SalesHeader."Source Code" <> '' THEN
                        SalesInvHeader."Source Code" := SalesHeader."Source Code"
                    ELSE
                        //LS +
                        SalesInvHeader."Source Code" := SrcCode;
                    //LS -
                    SalesHeader.CALCFIELDS("Order Amount", "Payment-At Order Entry-Limit", "Payment-At Delivery-Limit",
                                           "Retail Zones Description", "Non Refund Amount",
                                           "Payment-At PurchaseOrder-Limit");
                    SalesInvHeader."Order Amount" := SalesHeader."Order Amount";
                    SalesInvHeader."Payment-At Order Entry-Limit" := SalesHeader."Payment-At Order Entry-Limit";
                    SalesInvHeader."Payment-At Delivery-Limit" := SalesHeader."Payment-At Delivery-Limit";
                    SalesInvHeader."Retail Zones Description" := SalesHeader."Retail Zones Description";
                    SalesInvHeader."Non Refund Amount" := SalesHeader."Non Refund Amount";
                    SalesInvHeader."Payment-At PurchaseOrder-Limit" := SalesHeader."Payment-At PurchaseOrder-Limit";
                    //LS +
                    SalesInvHeader."User ID" := USERID;
                    SalesInvHeader."No. Printed" := 0;
                    //APNT-VAN1.0 +
                    SalesInvHeader."VAN Sales Order" := SalesHeader."VAN Sales Order";
                    /////SalesInvHeader."Push to VAN" := SalesHeader."Push to VAN";
                    //APNT-VAN1.0 -
                    //T003898 -
                    //SalesInvHeader.INSERT;//Commented Base
                    //>> 20230818 Added by KPS on 18-Aug-2023
                    SalesHeader.GetLastEComStatusEntryNo(SalesHeader."No.", gintMAGLastEntryNo, gtxtMAGLastStatus);
                    SalesInvHeader."Magento Last Entry No" := gintMAGLastEntryNo;
                    SalesInvHeader."Magento Last Status" := gtxtMAGLastStatus;
                    //<< 20230818 End of addition by KPS on 18-Aug-2023
                    SalesInvHeader.INSERT(TRUE);
                    //T003898 +

                    //APNT-eCom -
                    IF SalesHeader."eCOM Order" THEN BEGIN
                        CLEAR(eComCustomerOrderStatus);
                        eComCustomerOrderStatus.RESET;
                        eComCustomerOrderStatus.SETRANGE("Document ID", SalesHeader."No.");
                        IF eComCustomerOrderStatus.FINDLAST THEN BEGIN
                            eComCustomerOrderStatus."NAV-Status" := 'Invoice Posted';
                            eComCustomerOrderStatus.MODIFY;
                        END;
                    END;
                    //APNT-eCom +

                    //DP6.01.01 START
                    IF "Document Type" = "Document Type"::Invoice THEN BEGIN
                        IF PremiseMgmtSetup.GET THEN
                            IF PremiseMgmtSetup."Revenue Sharing" THEN
                                WorkOrderMgt.ClientRevenueInvoicePost("No.");
                    END;
                    //DP6.01.01 STOP

                    IF "Document Type" = "Document Type"::Order THEN BEGIN
                        Opp.RESET;
                        Opp.SETCURRENTKEY("Sales Document Type", "Sales Document No.");
                        Opp.SETRANGE("Sales Document Type", Opp."Sales Document Type"::Order);
                        Opp.SETRANGE("Sales Document No.", "No.");
                        Opp.SETRANGE(Status, Opp.Status::Won);
                        IF Opp.FINDFIRST THEN BEGIN
                            Opp."Sales Document Type" := Opp."Sales Document Type"::"Posted Invoice";
                            Opp."Sales Document No." := SalesInvHeader."No.";
                            Opp.MODIFY;
                            OpportunityEntry.RESET;
                            OpportunityEntry.SETCURRENTKEY(Active, "Opportunity No.");
                            OpportunityEntry.SETRANGE(Active, TRUE);
                            OpportunityEntry.SETRANGE("Opportunity No.", Opp."No.");
                            IF OpportunityEntry.FINDFIRST THEN BEGIN
                                OpportunityEntry."Calcd. Current Value (LCY)" := OpportunityEntry.GetSalesDocValue(Rec);
                                OpportunityEntry.MODIFY;
                            END;
                        END;
                    END;

                    //LS -
                    IF SalesHeader."Only Two Dimensions" THEN BEGIN
                        TempDocDim.SETRANGE(TempDocDim."Table ID", DATABASE::"Sales Header");
                        TempDocDim.SETRANGE(TempDocDim."Line No.", 0);
                        DimMgt.MoveDocDimToPostedDocDim(TempDocDim, DATABASE::"Sales Invoice Header", SalesInvHeader."No.");
                    END ELSE BEGIN
                        //LS +
                        DimMgt.MoveOneDocDimToPostedDocDim(
                          TempDocDim, DATABASE::"Sales Header", "Document Type", "No.", 0,
                          DATABASE::"Sales Invoice Header", SalesInvHeader."No.");
                    END;  //LS

                    ApprovalMgt.MoveApprvalEntryToPosted(TempApprovalEntry, DATABASE::"Sales Invoice Header", SalesInvHeader."No.");

                    IF SalesSetup."Copy Comments Order to Invoice" THEN BEGIN
                        CopyCommentLines(
                          "Document Type", SalesCommentLine."Document Type"::"Posted Invoice",
                          "No.", SalesInvHeader."No.");
                        SalesInvHeader.COPYLINKS(Rec);
                    END;
                    GenJnlLineDocType := GenJnlLine."Document Type"::Invoice;
                    GenJnlLineDocNo := SalesInvHeader."No.";
                    GenJnlLineExtDocNo := SalesInvHeader."External Document No.";
                END ELSE BEGIN // Credit Memo
                    SalesCrMemoHeader.INIT;
                    SalesCrMemoHeader.TRANSFERFIELDS(SalesHeader);
                    IF "Document Type" = "Document Type"::"Return Order" THEN BEGIN
                        SalesCrMemoHeader."No." := "Posting No.";
                        IF SalesSetup."Ext. Doc. No. Mandatory" THEN
                            TESTFIELD("External Document No.");
                        SalesCrMemoHeader."Pre-Assigned No. Series" := '';
                        SalesCrMemoHeader."Return Order No. Series" := "No. Series";
                        SalesCrMemoHeader."Return Order No." := "No.";
                        IF ShowDialog THEN  //LS
                            Window.UPDATE(1, STRSUBSTNO(Text008, "Document Type", "No.", SalesCrMemoHeader."No."))
                    END ELSE BEGIN
                        SalesCrMemoHeader."Pre-Assigned No. Series" := "No. Series";
                        SalesCrMemoHeader."Pre-Assigned No." := "No.";
                        IF "Posting No." <> '' THEN BEGIN
                            SalesCrMemoHeader."No." := "Posting No.";
                            IF ShowDialog THEN  //LS
                                Window.UPDATE(1, STRSUBSTNO(Text008, "Document Type", "No.", SalesCrMemoHeader."No."));
                        END;
                    END;
                    SalesCrMemoHeader."Source Code" := SrcCode;
                    SalesCrMemoHeader."User ID" := USERID;
                    SalesCrMemoHeader."No. Printed" := 0;
                    //eCom +
                    SalesCrMemoHeader."Mobile Phone No." := "Mobile Phone No.";
                    SalesCrMemoHeader."E-Mail" := "E-Mail";
                    SalesCrMemoHeader."Bill-to House No." := "Bill-to House No.";
                    SalesCrMemoHeader."Ship-to House No." := "Ship-to House No.";
                    //eCom +
                    SalesCrMemoHeader.INSERT;
                    //APNT-T009914
                    CreateBinLedgerEntries(SalesHeader, SalesCrMemoHeader);
                    //APNT-T009914
                    //APNT-eCom -
                    IF ("Document Type" = "Document Type"::"Credit Memo") OR ("Document Type" = "Document Type"::"Return Order") THEN BEGIN
                        IF SalesHeader."eCOM Order" THEN BEGIN
                            CLEAR(eComCustomerOrderStatus);
                            eComCustomerOrderStatus.RESET;
                            eComCustomerOrderStatus.SETRANGE("Document ID", SalesHeader."No.");
                            IF eComCustomerOrderStatus.FINDLAST THEN BEGIN
                                CLEAR(eEntryNo);
                                eComCustomerOrderStatusL.RESET;
                                IF eComCustomerOrderStatusL.FINDLAST THEN
                                    eEntryNo := eComCustomerOrderStatusL."Entry No." + 1
                                ELSE
                                    eEntryNo := 1;

                                eComCustomerOrderStatusL.INIT;
                                eComCustomerOrderStatusL."Entry No." := eEntryNo;
                                eComCustomerOrderStatusL."Document ID" := eComCustomerOrderStatus."Document ID";
                                eComCustomerOrderStatusL."Status Source" := eComCustomerOrderStatusL."Status Source"::NAV;
                                eComCustomerOrderStatusL."NAV-Status" := 'Return Received';
                                eComCustomerOrderStatusL."Date Created" := TODAY;
                                eComCustomerOrderStatusL.INSERT;
                                eComProcessUtility.CreateLog(eComCustomerOrderStatus, 'Processed');
                            END;
                            SalesCrMemoHeader."eCom Original Sales Order No." := SalesHeader."eCom Original Sales Order No.";
                            //eCom-CR +
                            CLEAR(SalesInvoiceHeader);
                            SalesInvoiceHeader.RESET;
                            SalesInvoiceHeader.SETRANGE("Order No.", SalesHeader."eCom Original Sales Order No.");
                            IF SalesInvoiceHeader.FINDFIRST THEN
                                SalesCrMemoHeader."eCom Original Sales Invoice No" := SalesInvoiceHeader."No.";
                            //eCom-CR -
                        END;
                    END;
                    //APNT-eCom +

                    //LS -
                    IF SalesHeader."Only Two Dimensions" THEN BEGIN
                        TempDocDim.SETRANGE(TempDocDim."Table ID", DATABASE::"Sales Header");
                        TempDocDim.SETRANGE(TempDocDim."Line No.", 0);
                        DimMgt.MoveDocDimToPostedDocDim(TempDocDim, DATABASE::"Sales Cr.Memo Header", SalesCrMemoHeader."No.");
                    END ELSE BEGIN
                        //LS +
                        DimMgt.MoveOneDocDimToPostedDocDim(
                          TempDocDim, DATABASE::"Sales Header", "Document Type", "No.", 0,
                          DATABASE::"Sales Cr.Memo Header", SalesCrMemoHeader."No.");
                    END;  //LS

                    ApprovalMgt.MoveApprvalEntryToPosted(TempApprovalEntry, DATABASE::"Sales Cr.Memo Header", SalesCrMemoHeader."No.");

                    IF SalesSetup."Copy Cmts Ret.Ord. to Cr. Memo" THEN BEGIN
                        CopyCommentLines(
                          "Document Type", SalesCommentLine."Document Type"::"Posted Credit Memo",
                          "No.", SalesCrMemoHeader."No.");
                        SalesCrMemoHeader.COPYLINKS(Rec);
                    END;
                    GenJnlLineDocType := GenJnlLine."Document Type"::"Credit Memo";
                    GenJnlLineDocNo := SalesCrMemoHeader."No.";
                    GenJnlLineExtDocNo := SalesCrMemoHeader."External Document No.";
                END;

            //T029871 <<
            HHTTransactions.RESET;
            HHTTransactions.SETRANGE("Transaction No.", "No.");
            IF "Document Type" = "Document Type"::Order THEN
                HHTTransactions.SETRANGE("Transaction Type", 'SI')
            ELSE
                IF "Document Type" = "Document Type"::"Credit Memo" THEN
                    HHTTransactions.SETRANGE("Transaction Type", 'SR')
                ELSE
                    IF "Document Type" = "Document Type"::"Return Order" THEN
                        HHTTransactions.SETRANGE("Transaction Type", 'SR');
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
                HHTTransHdr.SETRANGE("Transaction Type", 'SI')
            ELSE
                IF "Document Type" = "Document Type"::"Credit Memo" THEN
                    HHTTransHdr.SETRANGE("Transaction Type", 'SR')
                ELSE
                    IF "Document Type" = "Document Type"::"Return Order" THEN
                        HHTTransHdr.SETRANGE("Transaction Type", 'SR');
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
            DropShipPostBuffer.DELETEALL;
            EverythingInvoiced := TRUE;

            SalesLine.RESET;
            SalesLine.SETRANGE("Document Type", "Document Type");
            SalesLine.SETRANGE("Document No.", "No.");
            LineCount := 0;
            RoundingLineInserted := FALSE;
            MergeSaleslines(SalesHeader, SalesLine, TempPrepaymentSalesLine, CombinedSalesLineTemp);

            TempVATAmountLineRemainder.DELETEALL;
            SalesLine.CalcVATAmountLines(1, SalesHeader, CombinedSalesLineTemp, TempVATAmountLine);

            IF SalesLine.FINDSET THEN
                REPEAT
                    ItemJnlRollRndg := FALSE;
                    LineCount := LineCount + 1;
                    IF ShowDialog THEN  //LS
                        Window.UPDATE(2, LineCount);
                    IF SalesLine.Type = SalesLine.Type::"Charge (Item)" THEN BEGIN
                        SalesLine.TESTFIELD(Amount);
                        SalesLine.TESTFIELD("Job No.", '');
                        SalesLine.TESTFIELD("Job Contract Entry No.", 0);
                    END;
                    IF SalesLine.Type = SalesLine.Type::Item THEN
                        CostBaseAmount := SalesLine."Line Amount";
                    IF SalesLine."Qty. per Unit of Measure" = 0 THEN
                        SalesLine."Qty. per Unit of Measure" := 1;
                    CASE "Document Type" OF
                        "Document Type"::Order:
                            SalesLine.TESTFIELD("Return Qty. to Receive", 0);
                        "Document Type"::Invoice:
                            BEGIN
                                IF SalesLine."Shipment No." = '' THEN
                                    SalesLine.TESTFIELD("Qty. to Ship", SalesLine.Quantity);
                                SalesLine.TESTFIELD("Return Qty. to Receive", 0);
                                SalesLine.TESTFIELD("Qty. to Invoice", SalesLine.Quantity);
                            END;
                        "Document Type"::"Return Order":
                            SalesLine.TESTFIELD("Qty. to Ship", 0);
                        "Document Type"::"Credit Memo":
                            BEGIN
                                IF SalesLine."Return Receipt No." = '' THEN
                                    SalesLine.TESTFIELD("Return Qty. to Receive", SalesLine.Quantity);
                                SalesLine.TESTFIELD("Qty. to Ship", 0);
                                SalesLine.TESTFIELD("Qty. to Invoice", SalesLine.Quantity);
                            END;
                    END;

                    IF NOT (Ship OR RoundingLineInserted) THEN BEGIN
                        SalesLine."Qty. to Ship" := 0;
                        SalesLine."Qty. to Ship (Base)" := 0;
                    END;
                    IF NOT (Receive OR RoundingLineInserted) THEN BEGIN
                        SalesLine."Return Qty. to Receive" := 0;
                        SalesLine."Return Qty. to Receive (Base)" := 0;
                    END;

                    JobContractLine := FALSE;
                    TempJnlLineDim2.RESET;
                    TempJnlLineDim2.DELETEALL;
                    TempDocDim.RESET;
                    TempDocDim.SETRANGE("Table ID", DATABASE::"Sales Line");
                    TempDocDim.SETRANGE("Line No.", SalesLine."Line No.");
                    DimMgt.CopyDocDimToJnlLineDim(TempDocDim, TempJnlLineDim2);
                    IF TempJnlLineDim2.FIND('-') THEN;
                    IF (SalesLine.Type = SalesLine.Type::Item) OR
                       (SalesLine.Type = SalesLine.Type::"G/L Account") OR
                       (SalesLine.Type = SalesLine.Type::" ")
                    THEN
                        IF SalesLine."Job Contract Entry No." > 0 THEN
                            PostJobContractLine(SalesLine, TempJnlLineDim2);
                    IF (SalesLine.Type = SalesLine.Type::Resource) THEN
                        JobTaskSalesLine := SalesLine;

                    IF SalesLine.Type = SalesLine.Type::"Fixed Asset" THEN BEGIN
                        SalesLine.TESTFIELD("Job No.", '');
                        SalesLine.TESTFIELD("Depreciation Book Code");
                        DeprBook.GET(SalesLine."Depreciation Book Code");
                        DeprBook.TESTFIELD("G/L Integration - Disposal", TRUE);
                        FA.GET(SalesLine."No.");
                        FA.TESTFIELD("Budgeted Asset", FALSE);
                    END ELSE BEGIN
                        SalesLine.TESTFIELD("Depreciation Book Code", '');
                        SalesLine.TESTFIELD("Depr. until FA Posting Date", FALSE);
                        SalesLine.TESTFIELD("FA Posting Date", 0D);
                        SalesLine.TESTFIELD("Duplicate in Depreciation Book", '');
                        SalesLine.TESTFIELD("Use Duplication List", FALSE);
                    END;

                    IF ("Document Type" = "Document Type"::Invoice) AND (SalesLine."Shipment No." <> '') THEN BEGIN
                        SalesLine."Quantity Shipped" := SalesLine.Quantity;
                        SalesLine."Qty. Shipped (Base)" := SalesLine."Quantity (Base)";
                        SalesLine."Qty. to Ship" := 0;
                        SalesLine."Qty. to Ship (Base)" := 0;
                    END;

                    IF ("Document Type" = "Document Type"::"Credit Memo") AND (SalesLine."Return Receipt No." <> '') THEN BEGIN
                        SalesLine."Return Qty. Received" := SalesLine.Quantity;
                        SalesLine."Return Qty. Received (Base)" := SalesLine."Quantity (Base)";
                        SalesLine."Return Qty. to Receive" := 0;
                        SalesLine."Return Qty. to Receive (Base)" := 0;
                    END;

                    IF Invoice THEN BEGIN
                        IF ABS(SalesLine."Qty. to Invoice") > ABS(SalesLine.MaxQtyToInvoice) THEN
                            SalesLine.InitQtyToInvoice;
                    END ELSE BEGIN
                        SalesLine."Qty. to Invoice" := 0;
                        SalesLine."Qty. to Invoice (Base)" := 0;
                    END;

                    IF (SalesLine.Type = SalesLine.Type::Item) AND (SalesLine."No." <> '') THEN BEGIN
                        GetItem(SalesLine);
                        IF (Item."Costing Method" = Item."Costing Method"::Standard) AND NOT SalesLine.IsShipment THEN
                            SalesLine.GetUnitCost;
                    END;

                    IF SalesLine."Qty. to Invoice" + SalesLine."Quantity Invoiced" <> SalesLine.Quantity THEN
                        EverythingInvoiced := FALSE;

                    IF SalesLine.Quantity = 0 THEN
                        SalesLine.TESTFIELD(Amount, 0)
                    ELSE BEGIN
                        SalesLine.TESTFIELD("No.");
                        SalesLine.TESTFIELD(Type);
                        SalesLine.TESTFIELD("Gen. Bus. Posting Group");
                        SalesLine.TESTFIELD("Gen. Prod. Posting Group");
                        DivideAmount(1, SalesLine."Qty. to Invoice");
                    END;

                    IF SalesLine."Drop Shipment" THEN BEGIN
                        IF SalesLine.Type <> SalesLine.Type::Item THEN
                            SalesLine.TESTFIELD("Drop Shipment", FALSE);
                        IF (SalesLine."Qty. to Ship" <> 0) AND (SalesLine."Purch. Order Line No." = 0) THEN
                            ERROR(
                              Text009 +
                              Text010,
                              SalesLine."Line No.");
                    END;

                    RoundAmount(SalesLine."Qty. to Invoice");

                    IF NOT ("Document Type" IN ["Document Type"::"Return Order", "Document Type"::"Credit Memo"]) THEN BEGIN
                        ReverseAmount(SalesLine);
                        ReverseAmount(SalesLineACY);
                    END;

                    RemQtyToBeInvoiced := SalesLine."Qty. to Invoice";
                    RemQtyToBeInvoicedBase := SalesLine."Qty. to Invoice (Base)";

                    // Item Tracking:
                    IF NOT SalesLine."Prepayment Line" THEN BEGIN
                        IF Invoice THEN
                            IF SalesLine."Qty. to Invoice" = 0 THEN
                                TrackingSpecificationExists := FALSE
                            ELSE
                                TrackingSpecificationExists :=
                                  ReserveSalesLine.RetrieveInvoiceSpecification(SalesLine, TempInvoicingSpecification);
                        EndLoop := FALSE;

                        IF "Document Type" IN ["Document Type"::"Return Order", "Document Type"::"Credit Memo"] THEN BEGIN
                            IF ABS(RemQtyToBeInvoiced) > ABS(SalesLine."Return Qty. to Receive") THEN BEGIN
                                ReturnRcptLine.RESET;
                                CASE "Document Type" OF
                                    "Document Type"::"Return Order":
                                        BEGIN
                                            ReturnRcptLine.SETCURRENTKEY("Return Order No.", "Return Order Line No.");
                                            ReturnRcptLine.SETRANGE("Return Order No.", SalesLine."Document No.");
                                            ReturnRcptLine.SETRANGE("Return Order Line No.", SalesLine."Line No.");
                                        END;
                                    "Document Type"::"Credit Memo":
                                        BEGIN
                                            ReturnRcptLine.SETRANGE("Document No.", SalesLine."Return Receipt No.");
                                            ReturnRcptLine.SETRANGE("Line No.", SalesLine."Return Receipt Line No.");
                                        END;
                                END;
                                ReturnRcptLine.SETFILTER("Return Qty. Rcd. Not Invd.", '<>0');
                                IF ReturnRcptLine.FIND('-') THEN BEGIN
                                    ItemJnlRollRndg := TRUE;
                                    REPEAT
                                        IF TrackingSpecificationExists THEN BEGIN  // Item Tracking
                                            ItemEntryRelation.GET(TempInvoicingSpecification."Appl.-to Item Entry");
                                            ReturnRcptLine.GET(ItemEntryRelation."Source ID", ItemEntryRelation."Source Ref. No.");
                                        END ELSE
                                            ItemEntryRelation."Item Entry No." := ReturnRcptLine."Item Rcpt. Entry No.";
                                        ReturnRcptLine.TESTFIELD("Sell-to Customer No.", SalesLine."Sell-to Customer No.");
                                        ReturnRcptLine.TESTFIELD(Type, SalesLine.Type);
                                        ReturnRcptLine.TESTFIELD("No.", SalesLine."No.");
                                        ReturnRcptLine.TESTFIELD("Gen. Bus. Posting Group", SalesLine."Gen. Bus. Posting Group");
                                        ReturnRcptLine.TESTFIELD("Gen. Prod. Posting Group", SalesLine."Gen. Prod. Posting Group");
                                        ReturnRcptLine.TESTFIELD("Job No.", SalesLine."Job No.");
                                        ReturnRcptLine.TESTFIELD("Unit of Measure Code", SalesLine."Unit of Measure Code");
                                        ReturnRcptLine.TESTFIELD("Variant Code", SalesLine."Variant Code");
                                        IF SalesLine."Qty. to Invoice" * ReturnRcptLine.Quantity < 0 THEN
                                            SalesLine.FIELDERROR("Qty. to Invoice", Text024);
                                        IF TrackingSpecificationExists THEN BEGIN  // Item Tracking
                                            QtyToBeInvoiced := TempInvoicingSpecification."Qty. to Invoice";
                                            QtyToBeInvoicedBase := TempInvoicingSpecification."Qty. to Invoice (Base)";
                                        END ELSE BEGIN
                                            QtyToBeInvoiced := RemQtyToBeInvoiced - SalesLine."Return Qty. to Receive";
                                            QtyToBeInvoicedBase := RemQtyToBeInvoicedBase - SalesLine."Return Qty. to Receive (Base)";
                                        END;
                                        IF ABS(QtyToBeInvoiced) >
                                           ABS(ReturnRcptLine.Quantity - ReturnRcptLine."Quantity Invoiced")
                                        THEN BEGIN
                                            QtyToBeInvoiced := ReturnRcptLine.Quantity - ReturnRcptLine."Quantity Invoiced";
                                            QtyToBeInvoicedBase := ReturnRcptLine."Quantity (Base)" - ReturnRcptLine."Qty. Invoiced (Base)";
                                        END;

                                        IF TrackingSpecificationExists THEN
                                            ItemTrackingMgt.AdjustQuantityRounding(
                                              RemQtyToBeInvoiced, QtyToBeInvoiced,
                                              RemQtyToBeInvoicedBase, QtyToBeInvoicedBase);

                                        RemQtyToBeInvoiced := RemQtyToBeInvoiced - QtyToBeInvoiced;
                                        RemQtyToBeInvoicedBase := RemQtyToBeInvoicedBase - QtyToBeInvoicedBase;
                                        ReturnRcptLine."Quantity Invoiced" :=
                                          ReturnRcptLine."Quantity Invoiced" + QtyToBeInvoiced;
                                        ReturnRcptLine."Qty. Invoiced (Base)" :=
                                          ReturnRcptLine."Qty. Invoiced (Base)" + QtyToBeInvoicedBase;
                                        ReturnRcptLine."Return Qty. Rcd. Not Invd." :=
                                          ReturnRcptLine.Quantity - ReturnRcptLine."Quantity Invoiced";
                                        ReturnRcptLine.MODIFY;
                                        IF SalesLine.Type = SalesLine.Type::Item THEN
                                            PostItemJnlLine(
                                              SalesLine,
                                              0, 0,
                                              QtyToBeInvoiced,
                                              QtyToBeInvoicedBase,
                                              /*ReturnRcptLine."Item Rcpt. Entry No."*/
                                              ItemEntryRelation."Item Entry No.", '', TempInvoicingSpecification);
                                        IF TrackingSpecificationExists THEN
                                            EndLoop := (TempInvoicingSpecification.NEXT = 0)
                                        ELSE
                                            EndLoop :=
                                              (ReturnRcptLine.NEXT = 0) OR (ABS(RemQtyToBeInvoiced) <= ABS(SalesLine."Return Qty. to Receive"));
                                    UNTIL EndLoop;
                                END ELSE
                                    ERROR(
                                      Text025,
                                      SalesLine."Return Receipt Line No.", SalesLine."Return Receipt No.");
                            END;

                            IF ABS(RemQtyToBeInvoiced) > ABS(SalesLine."Return Qty. to Receive") THEN BEGIN
                                IF "Document Type" = "Document Type"::"Credit Memo" THEN
                                    ERROR(
                                      Text038,
                                      ReturnRcptLine."Document No.");
                                ERROR(Text037);
                            END;

                        END ELSE BEGIN

                            IF ABS(RemQtyToBeInvoiced) > ABS(SalesLine."Qty. to Ship") THEN BEGIN
                                SalesShptLine.RESET;
                                CASE "Document Type" OF
                                    "Document Type"::Order:
                                        BEGIN
                                            SalesShptLine.SETCURRENTKEY("Order No.", "Order Line No.");
                                            SalesShptLine.SETRANGE("Order No.", SalesLine."Document No.");
                                            SalesShptLine.SETRANGE("Order Line No.", SalesLine."Line No.");
                                        END;
                                    "Document Type"::Invoice:
                                        BEGIN
                                            SalesShptLine.SETRANGE("Document No.", SalesLine."Shipment No.");
                                            SalesShptLine.SETRANGE("Line No.", SalesLine."Shipment Line No.");
                                        END;
                                END;

                                SalesShptLine.SETFILTER("Qty. Shipped Not Invoiced", '<>0');
                                IF SalesShptLine.FIND('-') THEN BEGIN
                                    ItemJnlRollRndg := TRUE;
                                    REPEAT
                                        IF TrackingSpecificationExists THEN BEGIN
                                            ItemEntryRelation.GET(TempInvoicingSpecification."Appl.-to Item Entry");
                                            SalesShptLine.GET(ItemEntryRelation."Source ID", ItemEntryRelation."Source Ref. No.");
                                        END ELSE
                                            ItemEntryRelation."Item Entry No." := SalesShptLine."Item Shpt. Entry No.";
                                        SalesShptLine.TESTFIELD("Sell-to Customer No.", SalesLine."Sell-to Customer No.");
                                        SalesShptLine.TESTFIELD(Type, SalesLine.Type);
                                        SalesShptLine.TESTFIELD("No.", SalesLine."No.");
                                        SalesShptLine.TESTFIELD("Gen. Bus. Posting Group", SalesLine."Gen. Bus. Posting Group");
                                        SalesShptLine.TESTFIELD("Gen. Prod. Posting Group", SalesLine."Gen. Prod. Posting Group");
                                        SalesShptLine.TESTFIELD("Job No.", SalesLine."Job No.");
                                        SalesShptLine.TESTFIELD("Unit of Measure Code", SalesLine."Unit of Measure Code");
                                        SalesShptLine.TESTFIELD("Variant Code", SalesLine."Variant Code");
                                        IF (-SalesLine."Qty. to Invoice") * SalesShptLine.Quantity < 0 THEN
                                            SalesLine.FIELDERROR("Qty. to Invoice", Text011);
                                        IF TrackingSpecificationExists THEN BEGIN
                                            QtyToBeInvoiced := TempInvoicingSpecification."Qty. to Invoice";
                                            QtyToBeInvoicedBase := TempInvoicingSpecification."Qty. to Invoice (Base)";
                                        END ELSE BEGIN
                                            QtyToBeInvoiced := RemQtyToBeInvoiced - SalesLine."Qty. to Ship";
                                            QtyToBeInvoicedBase := RemQtyToBeInvoicedBase - SalesLine."Qty. to Ship (Base)";
                                        END;
                                        IF ABS(QtyToBeInvoiced) >
                                           ABS(SalesShptLine.Quantity - SalesShptLine."Quantity Invoiced")
                                        THEN BEGIN
                                            QtyToBeInvoiced := -(SalesShptLine.Quantity - SalesShptLine."Quantity Invoiced");
                                            QtyToBeInvoicedBase := -(SalesShptLine."Quantity (Base)" - SalesShptLine."Qty. Invoiced (Base)");
                                        END;

                                        IF TrackingSpecificationExists THEN
                                            ItemTrackingMgt.AdjustQuantityRounding(
                                              RemQtyToBeInvoiced, QtyToBeInvoiced,
                                              RemQtyToBeInvoicedBase, QtyToBeInvoicedBase);

                                        RemQtyToBeInvoiced := RemQtyToBeInvoiced - QtyToBeInvoiced;
                                        RemQtyToBeInvoicedBase := RemQtyToBeInvoicedBase - QtyToBeInvoicedBase;
                                        SalesShptLine."Quantity Invoiced" :=
                                          SalesShptLine."Quantity Invoiced" - QtyToBeInvoiced;
                                        SalesShptLine."Qty. Invoiced (Base)" :=
                                          SalesShptLine."Qty. Invoiced (Base)" - QtyToBeInvoicedBase;
                                        SalesShptLine."Qty. Shipped Not Invoiced" :=
                                          SalesShptLine.Quantity - SalesShptLine."Quantity Invoiced";
                                        SalesShptLine.MODIFY;
                                        IF SalesLine.Type = SalesLine.Type::Item THEN
                                            PostItemJnlLine(
                                              SalesLine,
                                              0, 0,
                                              QtyToBeInvoiced,
                                              QtyToBeInvoicedBase,
                                              /*SalesShptLine."Item Shpt. Entry No."*/
                                              ItemEntryRelation."Item Entry No.", '', TempInvoicingSpecification);
                                        IF TrackingSpecificationExists THEN
                                            EndLoop := (TempInvoicingSpecification.NEXT = 0)
                                        ELSE
                                            EndLoop :=
                                              (SalesShptLine.NEXT = 0) OR (ABS(RemQtyToBeInvoiced) <= ABS(SalesLine."Qty. to Ship"))
                                    UNTIL EndLoop;
                                END ELSE
                                    ERROR(
                                      Text026,
                                      SalesLine."Shipment Line No.", SalesLine."Shipment No.");
                            END;

                            IF ABS(RemQtyToBeInvoiced) > ABS(SalesLine."Qty. to Ship") THEN BEGIN
                                IF "Document Type" = "Document Type"::Invoice THEN
                                    ERROR(
                                      Text027,
                                      SalesShptLine."Document No.");
                                ERROR(Text013);
                            END;
                        END;

                        IF TrackingSpecificationExists THEN
                            SaveInvoiceSpecification(TempInvoicingSpecification);
                    END;

                    CASE SalesLine.Type OF
                        SalesLine.Type::"G/L Account":
                            IF (SalesLine."No." <> '') AND NOT SalesLine."System-Created Entry" THEN BEGIN
                                GLAcc.GET(SalesLine."No.");
                                GLAcc.TESTFIELD("Direct Posting", TRUE);
                                IF (SalesLine."IC Partner Code" <> '') AND Invoice THEN
                                    InsertICGenJnlLine(TempSalesLine);
                            END;
                        SalesLine.Type::Item:
                            BEGIN
                                IF (SalesLine."Qty. to Ship" <> 0) AND (SalesLine."Purch. Order Line No." <> 0) THEN BEGIN
                                    DropShipPostBuffer."Order No." := SalesLine."Purchase Order No.";
                                    DropShipPostBuffer."Order Line No." := SalesLine."Purch. Order Line No.";
                                    DropShipPostBuffer.Quantity := -SalesLine."Qty. to Ship";
                                    DropShipPostBuffer."Quantity (Base)" := -SalesLine."Qty. to Ship (Base)";
                                    DropShipPostBuffer."Item Shpt. Entry No." :=
                                      PostAssocItemJnlLine(DropShipPostBuffer.Quantity, DropShipPostBuffer."Quantity (Base)");
                                    DropShipPostBuffer.INSERT;
                                    SalesLine."Appl.-to Item Entry" := DropShipPostBuffer."Item Shpt. Entry No.";
                                END;
                                IF RemQtyToBeInvoiced <> 0 THEN
                                    ItemLedgShptEntryNo :=
                                      PostItemJnlLine(
                                        SalesLine,
                                        RemQtyToBeInvoiced, RemQtyToBeInvoicedBase,
                                        RemQtyToBeInvoiced, RemQtyToBeInvoicedBase,
                                        0, '', DummyTrackingSpecification);

                                IF "Document Type" IN ["Document Type"::"Return Order", "Document Type"::"Credit Memo"] THEN BEGIN
                                    IF ABS(SalesLine."Return Qty. to Receive") > ABS(RemQtyToBeInvoiced) THEN
                                        ItemLedgShptEntryNo :=
                                          PostItemJnlLine(
                                            SalesLine,
                                            SalesLine."Return Qty. to Receive" - RemQtyToBeInvoiced,
                                            SalesLine."Return Qty. to Receive (Base)" - RemQtyToBeInvoicedBase,
                                            0, 0, 0, '', DummyTrackingSpecification);
                                END ELSE BEGIN
                                    IF ABS(SalesLine."Qty. to Ship") > ABS(RemQtyToBeInvoiced) THEN
                                        ItemLedgShptEntryNo :=
                                          PostItemJnlLine(
                                            SalesLine,
                                            SalesLine."Qty. to Ship" - RemQtyToBeInvoiced,
                                            SalesLine."Qty. to Ship (Base)" - RemQtyToBeInvoicedBase,
                                            0, 0, 0, '', DummyTrackingSpecification);
                                END;
                            END;
                        SalesLine.Type::Resource:
                            IF SalesLine."Qty. to Invoice" <> 0 THEN BEGIN
                                ResJnlLine.INIT;
                                ResJnlLine."Posting Date" := "Posting Date";
                                ResJnlLine."Document Date" := "Document Date";
                                ResJnlLine."Reason Code" := "Reason Code";
                                ResJnlLine."Resource No." := SalesLine."No.";
                                ResJnlLine.Description := SalesLine.Description;
                                ResJnlLine."Source Type" := ResJnlLine."Source Type"::Customer;
                                ResJnlLine."Source No." := SalesLine."Sell-to Customer No.";
                                ResJnlLine."Work Type Code" := SalesLine."Work Type Code";
                                ResJnlLine."Job No." := SalesLine."Job No.";
                                ResJnlLine."Unit of Measure Code" := SalesLine."Unit of Measure Code";
                                ResJnlLine."Shortcut Dimension 1 Code" := SalesLine."Shortcut Dimension 1 Code";
                                ResJnlLine."Shortcut Dimension 2 Code" := SalesLine."Shortcut Dimension 2 Code";
                                ResJnlLine."Gen. Bus. Posting Group" := SalesLine."Gen. Bus. Posting Group";
                                ResJnlLine."Gen. Prod. Posting Group" := SalesLine."Gen. Prod. Posting Group";
                                ResJnlLine."Entry Type" := ResJnlLine."Entry Type"::Sale;
                                ResJnlLine."Document No." := GenJnlLineDocNo;
                                ResJnlLine."External Document No." := GenJnlLineExtDocNo;
                                ResJnlLine.Quantity := -SalesLine."Qty. to Invoice";
                                ResJnlLine."Unit Cost" := SalesLine."Unit Cost (LCY)";
                                ResJnlLine."Total Cost" := SalesLine."Unit Cost (LCY)" * ResJnlLine.Quantity;
                                ResJnlLine."Unit Price" := -SalesLine.Amount / SalesLine.Quantity;
                                ResJnlLine."Total Price" := -SalesLine.Amount;
                                ResJnlLine."Source Code" := SrcCode;
                                ResJnlLine.Chargeable := TRUE;
                                ResJnlLine."Posting No. Series" := "Posting No. Series";
                                ResJnlLine."Qty. per Unit of Measure" := SalesLine."Qty. per Unit of Measure";
                                TempJnlLineDim.DELETEALL;
                                TempDocDim.RESET;
                                TempDocDim.SETRANGE("Table ID", DATABASE::"Sales Line");
                                TempDocDim.SETRANGE("Line No.", SalesLine."Line No.");
                                DimMgt.CopyDocDimToJnlLineDim(TempDocDim, TempJnlLineDim);
                                ResJnlPostLine.RunWithCheck(ResJnlLine, TempJnlLineDim);
                                IF JobTaskSalesLine."Job Contract Entry No." > 0 THEN
                                    PostJobContractLine(JobTaskSalesLine, TempJnlLineDim2);
                            END;
                        SalesLine.Type::"Charge (Item)":
                            IF Invoice OR ItemChargeAssgntOnly THEN BEGIN
                                ItemJnlRollRndg := FALSE;
                                ClearItemChargeAssgntFilter;
                                TempItemChargeAssgntSales.SETCURRENTKEY("Applies-to Doc. Type");
                                TempItemChargeAssgntSales.SETFILTER("Applies-to Doc. Type", '<>%1', "Document Type");
                                TempItemChargeAssgntSales.SETRANGE("Document Line No.", SalesLine."Line No.");
                                IF TempItemChargeAssgntSales.FINDSET THEN
                                    REPEAT
                                        IF ItemChargeAssgntOnly AND (GenJnlLineDocNo = '') THEN
                                            GenJnlLineDocNo := TempItemChargeAssgntSales."Applies-to Doc. No.";
                                        CASE TempItemChargeAssgntSales."Applies-to Doc. Type" OF
                                            TempItemChargeAssgntSales."Applies-to Doc. Type"::Shipment:
                                                PostItemChargePerShpt(SalesLine);
                                            TempItemChargeAssgntSales."Applies-to Doc. Type"::"Return Receipt":
                                                PostItemChargePerRetRcpt(SalesLine);
                                        END;
                                        TempItemChargeAssgntSales.MARK(TRUE);
                                    UNTIL TempItemChargeAssgntSales.NEXT = 0;
                            END;
                    END;

                    IF (SalesLine.Type >= SalesLine.Type::"G/L Account") AND (SalesLine."Qty. to Invoice" <> 0) THEN BEGIN
                        // Copy sales to buffer
                        FillInvPostingBuffer(SalesLine, SalesLineACY);
                        TempDocDim.SETRANGE("Table ID");
                        TempDocDim.SETRANGE("Line No.");
                    END;

                    IF NOT ("Document Type" IN ["Document Type"::Invoice, "Document Type"::"Credit Memo"]) THEN
                        SalesLine.TESTFIELD("Job No.", '');

                    IF (SalesShptHeader."No." <> '') AND (SalesLine."Shipment No." = '') AND
                       NOT RoundingLineInserted AND NOT TempSalesLine."Prepayment Line"
                    THEN BEGIN
                        // Insert shipment line
                        SalesShptLine.INIT;
                        SalesShptLine.TRANSFERFIELDS(TempSalesLine);
                        SalesShptLine."Posting Date" := "Posting Date";
                        SalesShptLine."Document No." := SalesShptHeader."No.";
                        SalesShptLine.Quantity := TempSalesLine."Qty. to Ship";
                        SalesShptLine."Quantity (Base)" := TempSalesLine."Qty. to Ship (Base)";
                        IF ABS(TempSalesLine."Qty. to Invoice") > ABS(TempSalesLine."Qty. to Ship") THEN BEGIN
                            SalesShptLine."Quantity Invoiced" := TempSalesLine."Qty. to Ship";
                            SalesShptLine."Qty. Invoiced (Base)" := TempSalesLine."Qty. to Ship (Base)";
                        END ELSE BEGIN
                            SalesShptLine."Quantity Invoiced" := TempSalesLine."Qty. to Invoice";
                            SalesShptLine."Qty. Invoiced (Base)" := TempSalesLine."Qty. to Invoice (Base)";
                        END;
                        SalesShptLine."Qty. Shipped Not Invoiced" :=
                          SalesShptLine.Quantity - SalesShptLine."Quantity Invoiced";
                        IF "Document Type" = "Document Type"::Order THEN BEGIN
                            SalesShptLine."Order No." := TempSalesLine."Document No.";
                            SalesShptLine."Order Line No." := TempSalesLine."Line No.";
                        END;

                        IF (SalesLine.Type = SalesLine.Type::Item) AND (TempSalesLine."Qty. to Ship" <> 0) THEN BEGIN
                            IF WhseShip THEN BEGIN
                                WhseShptLine.SETCURRENTKEY(
                                  "No.", "Source Type", "Source Subtype", "Source No.", "Source Line No.");
                                WhseShptLine.SETRANGE("No.", WhseShptHeader."No.");
                                WhseShptLine.SETRANGE("Source Type", DATABASE::"Sales Line");
                                WhseShptLine.SETRANGE("Source Subtype", SalesLine."Document Type");
                                WhseShptLine.SETRANGE("Source No.", SalesLine."Document No.");
                                WhseShptLine.SETRANGE("Source Line No.", SalesLine."Line No.");
                                WhseShptLine.FINDFIRST;
                                WhseShptLine.TESTFIELD("Qty. to Ship", SalesShptLine.Quantity);
                                SaveTempWhseSplitSpec(SalesLine);
                                WhsePostShpt.CreatePostedShptLine(
                                  WhseShptLine, PostedWhseShptHeader, PostedWhseShptLine, TempWhseSplitSpecification);
                            END;
                            IF WhseReceive THEN BEGIN
                                WhseRcptLine.SETCURRENTKEY(
                                  "No.", "Source Type", "Source Subtype", "Source No.", "Source Line No.");
                                WhseRcptLine.SETRANGE("No.", WhseRcptHeader."No.");
                                WhseRcptLine.SETRANGE("Source Type", DATABASE::"Sales Line");
                                WhseRcptLine.SETRANGE("Source Subtype", SalesLine."Document Type");
                                WhseRcptLine.SETRANGE("Source No.", SalesLine."Document No.");
                                WhseRcptLine.SETRANGE("Source Line No.", SalesLine."Line No.");
                                WhseRcptLine.FINDFIRST;
                                WhseRcptLine.TESTFIELD("Qty. to Receive", -SalesShptLine.Quantity);
                                SaveTempWhseSplitSpec(SalesLine);
                                WhsePostRcpt.CreatePostedRcptLine(
                                  WhseRcptLine, PostedWhseRcptHeader, PostedWhseRcptLine, TempWhseSplitSpecification);
                            END;

                            SalesShptLine."Item Shpt. Entry No." :=
                              InsertShptEntryRelation(SalesShptLine); // ItemLedgShptEntryNo
                            SalesShptLine."Item Charge Base Amount" :=
                              ROUND(CostBaseAmount / SalesLine.Quantity * SalesShptLine.Quantity);
                        END;
                        SalesShptLine.INSERT;

                        //LS -
                        IF (TempSalesLine."Retail Special Order") AND (TempSalesLine."Configuration ID" <> '') THEN
                            PostSPOOptionTypeValues();
                        //LS +

                        ServItemMgt.CreateServItemOnSalesLineShpt(Rec, TempSalesLine, SalesShptLine);

                        IF SalesLine."BOM Item No." <> '' THEN BEGIN
                            ServItemMgt.ReturnServItemComp(ServiceItemTmp1, ServiceItemCmpTmp1);
                            IF ServiceItemTmp1.FIND('-') THEN
                                REPEAT
                                    ServiceItemTmp2 := ServiceItemTmp1;
                                    IF ServiceItemTmp2.INSERT THEN;
                                UNTIL ServiceItemTmp1.NEXT = 0;
                            IF ServiceItemCmpTmp1.FIND('-') THEN
                                REPEAT
                                    ServiceItemCmpTmp2 := ServiceItemCmpTmp1;
                                    IF ServiceItemCmpTmp2.INSERT THEN;
                                UNTIL ServiceItemCmpTmp1.NEXT = 0;
                        END;

                        //LS -
                        IF SalesHeader."Only Two Dimensions" THEN BEGIN
                            TempDocDim.SETRANGE(TempDocDim."Table ID", DATABASE::"Sales Line");
                            TempDocDim.SETRANGE(TempDocDim."Line No.", SalesShptLine."Line No.");
                            DimMgt.MoveDocDimToPostedDocDim(TempDocDim, DATABASE::"Sales Shipment Line", SalesShptHeader."No.");
                        END ELSE BEGIN
                            //LS +
                            DimMgt.MoveOneDocDimToPostedDocDim(
                              TempDocDim, DATABASE::"Sales Line", "Document Type", "No.", SalesShptLine."Line No.",
                              DATABASE::"Sales Shipment Line", SalesShptHeader."No.");
                        END;  //LS
                    END;

                    IF (ReturnRcptHeader."No." <> '') AND (SalesLine."Return Receipt No." = '') AND
                       NOT RoundingLineInserted
                    THEN BEGIN
                        // Insert return receipt line
                        ReturnRcptLine.INIT;
                        ReturnRcptLine.TRANSFERFIELDS(TempSalesLine);
                        ReturnRcptLine."Document No." := ReturnRcptHeader."No.";
                        ReturnRcptLine."Posting Date" := ReturnRcptHeader."Posting Date";
                        ReturnRcptLine.Quantity := TempSalesLine."Return Qty. to Receive";
                        ReturnRcptLine."Quantity (Base)" := TempSalesLine."Return Qty. to Receive (Base)";
                        IF ABS(TempSalesLine."Qty. to Invoice") > ABS(TempSalesLine."Return Qty. to Receive") THEN BEGIN
                            ReturnRcptLine."Quantity Invoiced" := TempSalesLine."Return Qty. to Receive";
                            ReturnRcptLine."Qty. Invoiced (Base)" := TempSalesLine."Return Qty. to Receive (Base)";
                        END ELSE BEGIN
                            ReturnRcptLine."Quantity Invoiced" := TempSalesLine."Qty. to Invoice";
                            ReturnRcptLine."Qty. Invoiced (Base)" := TempSalesLine."Qty. to Invoice (Base)";
                        END;
                        ReturnRcptLine."Return Qty. Rcd. Not Invd." :=
                          ReturnRcptLine.Quantity - ReturnRcptLine."Quantity Invoiced";
                        IF "Document Type" = "Document Type"::"Return Order" THEN BEGIN
                            ReturnRcptLine."Return Order No." := TempSalesLine."Document No.";
                            ReturnRcptLine."Return Order Line No." := TempSalesLine."Line No.";
                        END;
                        IF (SalesLine.Type = SalesLine.Type::Item) AND (TempSalesLine."Return Qty. to Receive" <> 0) THEN BEGIN
                            IF WhseReceive THEN BEGIN
                                WhseRcptLine.SETCURRENTKEY(
                                  "No.", "Source Type", "Source Subtype", "Source No.", "Source Line No.");
                                WhseRcptLine.SETRANGE("No.", WhseRcptHeader."No.");
                                WhseRcptLine.SETRANGE("Source Type", DATABASE::"Sales Line");
                                WhseRcptLine.SETRANGE("Source Subtype", SalesLine."Document Type");
                                WhseRcptLine.SETRANGE("Source No.", SalesLine."Document No.");
                                WhseRcptLine.SETRANGE("Source Line No.", SalesLine."Line No.");
                                WhseRcptLine.FINDFIRST;
                                WhseRcptLine.TESTFIELD("Qty. to Receive", ReturnRcptLine.Quantity);
                                SaveTempWhseSplitSpec(SalesLine);
                                WhsePostRcpt.CreatePostedRcptLine(
                                  WhseRcptLine, PostedWhseRcptHeader, PostedWhseRcptLine, TempWhseSplitSpecification);
                            END;
                            IF WhseShip THEN BEGIN
                                WhseShptLine.SETCURRENTKEY(
                                  "No.", "Source Type", "Source Subtype", "Source No.", "Source Line No.");
                                WhseShptLine.SETRANGE("No.", WhseShptHeader."No.");
                                WhseShptLine.SETRANGE("Source Type", DATABASE::"Sales Line");
                                WhseShptLine.SETRANGE("Source Subtype", SalesLine."Document Type");
                                WhseShptLine.SETRANGE("Source No.", SalesLine."Document No.");
                                WhseShptLine.SETRANGE("Source Line No.", SalesLine."Line No.");
                                WhseShptLine.FINDFIRST;
                                WhseShptLine.TESTFIELD("Qty. to Ship", -ReturnRcptLine.Quantity);
                                SaveTempWhseSplitSpec(SalesLine);
                                WhsePostShpt.CreatePostedShptLine(
                                  WhseShptLine, PostedWhseShptHeader, PostedWhseShptLine, TempWhseSplitSpecification);
                            END;

                            ReturnRcptLine."Item Rcpt. Entry No." :=
                              InsertReturnEntryRelation(ReturnRcptLine); // ItemLedgShptEntryNo;
                            ReturnRcptLine."Item Charge Base Amount" :=
                              ROUND(CostBaseAmount / SalesLine.Quantity * ReturnRcptLine.Quantity);
                        END;
                        //eCom-CR-
                        ReturnRcptLine."eCom Original Sales Order No." := ReturnRcptHeader."eCom Original Sales Order No.";
                        ReturnRcptLine."eCom Original Sales Invoice No" := ReturnRcptHeader."eCom Original Sales Invoice No";
                        //eCom-CR+
                        ReturnRcptLine.INSERT;

                        //LS -
                        IF SalesHeader."Only Two Dimensions" THEN BEGIN
                            TempDocDim.SETRANGE(TempDocDim."Table ID", DATABASE::"Sales Line");
                            TempDocDim.SETRANGE(TempDocDim."Line No.", ReturnRcptLine."Line No.");
                            DimMgt.MoveDocDimToPostedDocDim(TempDocDim, DATABASE::"Return Receipt Line", ReturnRcptHeader."No.");
                        END ELSE BEGIN
                            //LS +
                            DimMgt.MoveOneDocDimToPostedDocDim(
                              TempDocDim, DATABASE::"Sales Line", "Document Type", "No.", ReturnRcptLine."Line No.",
                              DATABASE::"Return Receipt Line", ReturnRcptHeader."No.");
                        END;  //LS
                    END;

                    IF Invoice THEN BEGIN
                        // Insert invoice line or credit memo line
                        IF "Document Type" IN ["Document Type"::Order, "Document Type"::Invoice] THEN BEGIN
                            SalesInvLine.INIT;
                            SalesInvLine.TRANSFERFIELDS(TempSalesLine);
                            SalesInvLine."Posting Date" := "Posting Date";
                            SalesInvLine."Document No." := SalesInvHeader."No.";
                            SalesInvLine.Quantity := TempSalesLine."Qty. to Invoice";
                            SalesInvLine."Quantity (Base)" := TempSalesLine."Qty. to Invoice (Base)";
                            SalesInvLine.INSERT;

                            PremiseSetup.GET;   //APNT 15Jan18
                                                //DP6.01.01 START
                            IF TempSalesLine."Ref. Document Type" IN [TempSalesLine."Ref. Document Type"::Lease,
                              TempSalesLine."Ref. Document Type"::Sale] THEN
                                IF (TempSalesLine."Ref. Document No." <> '') THEN
                                    IF (Rec."Reason Code" <> PremiseSetup."Reason Code") AND (Rec."Reason Code" = PremiseSetup."Reason Code") THEN
                                        UpdateAgreement(TempSalesLine, SalesInvLine."Document No.");
                            //DP6.01.01 STOP

                            //LS -
                            IF (TempSalesLine."Retail Special Order") AND (TempSalesLine."Configuration ID" <> '') THEN BEGIN
                                PostSPOOptionTypeValues();
                                PostSPOPaymentLines();
                            END;
                            //LS +

                            //LS -
                            IF SalesHeader."Only Two Dimensions" THEN BEGIN
                                TempDocDim.SETRANGE(TempDocDim."Table ID", DATABASE::"Sales Line");
                                TempDocDim.SETRANGE(TempDocDim."Line No.", SalesInvLine."Line No.");
                                DimMgt.MoveDocDimToPostedDocDim(TempDocDim, DATABASE::"Sales Invoice Line", SalesInvHeader."No.");
                            END ELSE BEGIN
                                //LS +
                                DimMgt.MoveOneDocDimToPostedDocDim(
                                  TempDocDim, DATABASE::"Sales Line", "Document Type", "No.", SalesInvLine."Line No.",
                                  DATABASE::"Sales Invoice Line", SalesInvHeader."No.");
                            END;  //LS

                            ItemJnlPostLine.CollectValueEntryRelation(TempValueEntryRelation, SalesInvLine.RowID1);
                        END ELSE BEGIN // Credit Memo
                            SalesCrMemoLine.INIT;
                            SalesCrMemoLine.TRANSFERFIELDS(TempSalesLine);
                            SalesCrMemoLine."Posting Date" := "Posting Date";
                            SalesCrMemoLine."Document No." := SalesCrMemoHeader."No.";
                            SalesCrMemoLine.Quantity := TempSalesLine."Qty. to Invoice";
                            SalesCrMemoLine."Quantity (Base)" := TempSalesLine."Qty. to Invoice (Base)";
                            //eCom-CR -
                            SalesCrMemoLine."eCom Original Sales Order No." := SalesCrMemoHeader."eCom Original Sales Order No.";
                            SalesCrMemoLine."eCom Original Sales Invoice No" := SalesCrMemoHeader."eCom Original Sales Invoice No";
                            //eCom-CR -
                            SalesCrMemoLine.INSERT;

                            //DP6.01.01 START
                            IF TempSalesLine."Ref. Document Type" IN [TempSalesLine."Ref. Document Type"::Lease,
                              TempSalesLine."Ref. Document Type"::Sale] THEN
                                IF TempSalesLine."Ref. Document No." <> '' THEN
                                    UpdateAgreement(TempSalesLine, SalesCrMemoLine."Document No.");
                            //DP6.01.01 STOP

                            //LS -
                            IF SalesHeader."Only Two Dimensions" THEN BEGIN
                                TempDocDim.SETRANGE(TempDocDim."Table ID", DATABASE::"Sales Line");
                                TempDocDim.SETRANGE(TempDocDim."Line No.", SalesCrMemoLine."Line No.");
                                DimMgt.MoveDocDimToPostedDocDim(TempDocDim, DATABASE::"Sales Cr.Memo Line", SalesCrMemoHeader."No.");
                            END ELSE BEGIN
                                //LS +
                                DimMgt.MoveOneDocDimToPostedDocDim(
                                  TempDocDim, DATABASE::"Sales Line", "Document Type", "No.", SalesCrMemoLine."Line No.",
                                  DATABASE::"Sales Cr.Memo Line", SalesCrMemoHeader."No.");
                            END;  //LS

                            ItemJnlPostLine.CollectValueEntryRelation(TempValueEntryRelation, SalesCrMemoLine.RowID1);
                        END;
                    END;

                    IF RoundingLineInserted THEN
                        LastLineRetrieved := TRUE
                    ELSE BEGIN
                        LastLineRetrieved := GetNextSalesline(SalesLine);
                        IF LastLineRetrieved AND SalesSetup."Invoice Rounding" THEN
                            InvoiceRounding(FALSE);
                    END;
                UNTIL LastLineRetrieved;

            IF NOT ("Document Type" IN ["Document Type"::"Return Order", "Document Type"::"Credit Memo"]) THEN BEGIN
                ReverseAmount(TotalSalesLine);
                ReverseAmount(TotalSalesLineLCY);
                TotalSalesLineLCY."Unit Cost (LCY)" := -TotalSalesLineLCY."Unit Cost (LCY)";
            END;

            // Post drop shipment of purchase order
            PurchSetup.GET;
            IF DropShipPostBuffer.FIND('-') THEN
                REPEAT
                    PurchOrderHeader.GET(
                      PurchOrderHeader."Document Type"::Order,
                      DropShipPostBuffer."Order No.");
                    PurchRcptHeader.INIT;
                    PurchRcptHeader.TRANSFERFIELDS(PurchOrderHeader);
                    PurchRcptHeader."No." := PurchOrderHeader."Receiving No.";
                    PurchRcptHeader."Order No." := PurchOrderHeader."No.";
                    PurchRcptHeader."Posting Date" := "Posting Date";
                    PurchRcptHeader."Document Date" := "Document Date";
                    PurchRcptHeader."No. Printed" := 0;
                    PurchRcptHeader.INSERT;

                    //LS -
                    IF SalesHeader."Only Two Dimensions" THEN BEGIN
                        TempDocDim2.DELETEALL;
                        TempDocDim2.INIT;
                        TempDocDim2."Table ID" := DATABASE::"Purchase Header";
                        TempDocDim2."Document Type" := PurchOrderHeader."Document Type";
                        TempDocDim2."Document No." := PurchOrderHeader."No.";
                        TempDocDim2."Line No." := 0;
                        TempDocDim2."Dimension Code" := GLSetup."Global Dimension 1 Code";
                        TempDocDim2."Dimension Value Code" := PurchOrderHeader."Shortcut Dimension 1 Code";
                        IF TempDocDim2."Dimension Value Code" <> '' THEN
                            TempDocDim2.INSERT;
                        TempDocDim2."Dimension Code" := GLSetup."Global Dimension 2 Code";
                        TempDocDim2."Dimension Value Code" := PurchOrderHeader."Shortcut Dimension 2 Code";
                        IF TempDocDim2."Dimension Value Code" <> '' THEN
                            TempDocDim2.INSERT;
                        DimMgt.MoveDocDimToPostedDocDim(TempDocDim2, DATABASE::"Purch. Rcpt. Header", PurchRcptHeader."No.");
                    END ELSE BEGIN
                        //LS +
                        DocDim.RESET;
                        DimMgt.MoveOneDocDimToPostedDocDim(
                          DocDim, DATABASE::"Purchase Header", PurchOrderHeader."Document Type", PurchOrderHeader."No.",
                          0, DATABASE::"Purch. Rcpt. Header", PurchRcptHeader."No.");
                    END;  //LS

                    ApprovalMgt.MoveApprvalEntryToPosted(TempApprovalEntry, DATABASE::"Purch. Rcpt. Header", PurchRcptHeader."No.");

                    IF PurchSetup."Copy Comments Order to Receipt" THEN BEGIN
                        CopyPurchCommentLines(
                          PurchOrderHeader."Document Type", PurchCommentLine."Document Type"::Receipt,
                          PurchOrderHeader."No.", PurchRcptHeader."No.");
                        PurchRcptHeader.COPYLINKS(Rec);
                    END;
                    DropShipPostBuffer.SETRANGE("Order No.", DropShipPostBuffer."Order No.");
                    REPEAT
                        PurchOrderLine.GET(
                          PurchOrderLine."Document Type"::Order,
                          DropShipPostBuffer."Order No.", DropShipPostBuffer."Order Line No.");
                        PurchRcptLine.INIT;
                        PurchRcptLine.TRANSFERFIELDS(PurchOrderLine);
                        PurchRcptLine."Posting Date" := PurchRcptHeader."Posting Date";
                        PurchRcptLine."Document No." := PurchRcptHeader."No.";
                        PurchRcptLine.Quantity := DropShipPostBuffer.Quantity;
                        PurchRcptLine."Quantity (Base)" := DropShipPostBuffer."Quantity (Base)";
                        PurchRcptLine."Quantity Invoiced" := 0;
                        PurchRcptLine."Qty. Invoiced (Base)" := 0;
                        PurchRcptLine."Order No." := PurchOrderLine."Document No.";
                        PurchRcptLine."Order Line No." := PurchOrderLine."Line No.";
                        PurchRcptLine."Qty. Rcd. Not Invoiced" :=
                          PurchRcptLine.Quantity - PurchRcptLine."Quantity Invoiced";

                        IF PurchRcptLine.Quantity <> 0 THEN BEGIN
                            PurchRcptLine."Item Rcpt. Entry No." := DropShipPostBuffer."Item Shpt. Entry No.";
                            PurchRcptLine."Item Charge Base Amount" := PurchOrderLine."Line Amount"
                        END;
                        PurchRcptLine.INSERT;
                        PurchOrderLine."Qty. to Receive" := DropShipPostBuffer.Quantity;
                        PurchOrderLine."Qty. to Receive (Base)" := DropShipPostBuffer."Quantity (Base)";
                        PurchPost.UpdateBlanketOrderLine(PurchOrderLine, TRUE, FALSE, FALSE);

                        //LS -
                        IF SalesHeader."Only Two Dimensions" THEN BEGIN
                            TempDocDim2.DELETEALL;
                            TempDocDim2.INIT;
                            TempDocDim2."Table ID" := DATABASE::"Purchase Line";
                            TempDocDim2."Document Type" := PurchOrderHeader."Document Type";
                            TempDocDim2."Document No." := PurchOrderHeader."No.";
                            TempDocDim2."Line No." := PurchOrderLine."Line No.";
                            TempDocDim2."Dimension Code" := GLSetup."Global Dimension 1 Code";
                            TempDocDim2."Dimension Value Code" := PurchOrderLine."Shortcut Dimension 1 Code";
                            IF TempDocDim2."Dimension Value Code" <> '' THEN
                                TempDocDim2.INSERT;
                            TempDocDim2."Dimension Code" := GLSetup."Global Dimension 2 Code";
                            TempDocDim2."Dimension Value Code" := PurchOrderLine."Shortcut Dimension 2 Code";
                            IF TempDocDim2."Dimension Value Code" <> '' THEN
                                TempDocDim2.INSERT;
                            DimMgt.MoveDocDimToPostedDocDim(TempDocDim2, DATABASE::"Purch. Rcpt. Line", PurchRcptHeader."No.");
                        END ELSE BEGIN
                            //LS +
                            DimMgt.MoveOneDocDimToPostedDocDim(
                              DocDim, DATABASE::"Purchase Line", PurchOrderHeader."Document Type", PurchOrderHeader."No.",
                              PurchOrderLine."Line No.", DATABASE::"Purch. Rcpt. Line", PurchRcptHeader."No.");
                        END;  //LS
                    UNTIL DropShipPostBuffer.NEXT = 0;
                    DropShipPostBuffer.SETRANGE("Order No.");
                UNTIL DropShipPostBuffer.NEXT = 0;

            //APNT-IC1.0
            IF Invoice AND ("Bill-to IC Partner Code" <> '') THEN BEGIN
                IF ICPartner."Auto Post Outbox Transactions" THEN BEGIN
                    IF "Document Type" IN ["Document Type"::Order, "Document Type"::Invoice] THEN BEGIN
                        CLEAR(ICOutboxExport);
                        ICDirection := ICDirection::Outgoing;
                        ICTransactionNo := ICInOutBoxMgt.CreateandPostOutboxSalesInv(SalesInvHeader);
                        ICOutboxExport.AutoPostICOutbocTransaction(ICTransactionNo);
                    END ELSE BEGIN
                        CLEAR(ICOutboxExport);
                        ICDirection := ICDirection::Outgoing;
                        ICTransactionNo := ICInOutBoxMgt.CreateandPostOutboxSalesCrMemo(SalesCrMemoHeader);
                        ICOutboxExport.AutoPostICOutbocTransaction(ICTransactionNo);
                    END;
                END ELSE BEGIN
                    IF "Document Type" IN ["Document Type"::Order, "Document Type"::Invoice] THEN BEGIN
                        ICDirection := ICDirection::Outgoing;
                        ICTransactionNo := ICInOutBoxMgt.CreateandPostOutboxSalesInv(SalesInvHeader);
                    END ELSE BEGIN
                        ICDirection := ICDirection::Outgoing;
                        ICTransactionNo := ICInOutBoxMgt.CreateandPostOutboxSalesCrMemo(SalesCrMemoHeader);
                    END;
                END;
            END;
            //APNT-IC1.0

            IF Invoice THEN BEGIN
                // Post sales and VAT to G/L entries from posting buffer
                LineCount := 0;
                IF InvPostingBuffer[1].FIND('+') THEN
                    REPEAT
                        LineCount := LineCount + 1;
                        IF ShowDialog THEN  //LS
                            Window.UPDATE(3, LineCount);


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
                        GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::Sale;
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
                        GenJnlLine."EU 3-Party Trade" := "EU 3-Party Trade";
                        GenJnlLine."Sell-to/Buy-from No." := "Sell-to Customer No.";
                        GenJnlLine."Bill-to/Pay-to No." := "Bill-to Customer No.";
                        GenJnlLine."Country/Region Code" := "VAT Country/Region Code";
                        GenJnlLine."VAT Registration No." := "VAT Registration No.";
                        GenJnlLine."Source Type" := GenJnlLine."Source Type"::Customer;
                        GenJnlLine."Source No." := "Bill-to Customer No.";
                        GenJnlLine."Posting No. Series" := "Posting No. Series";
                        GenJnlLine."Ship-to/Order Address Code" := "Ship-to Code";
                        GenJnlLine."Batch No." := "Batch No.";  //LS
                        IF InvPostingBuffer[1].Type = InvPostingBuffer[1].Type::"Fixed Asset" THEN BEGIN
                            GenJnlLine."Account Type" := GenJnlLine."Account Type"::"Fixed Asset";
                            GenJnlLine."FA Posting Type" := GenJnlLine."FA Posting Type"::Disposal;
                            GenJnlLine."FA Posting Date" := InvPostingBuffer[1]."FA Posting Date";
                            GenJnlLine."Depreciation Book Code" := InvPostingBuffer[1]."Depreciation Book Code";
                            GenJnlLine."Depr. until FA Posting Date" := InvPostingBuffer[1]."Depr. until FA Posting Date";
                            GenJnlLine."Duplicate in Depreciation Book" := InvPostingBuffer[1]."Duplicate in Depreciation Book";
                            GenJnlLine."Use Duplication List" := InvPostingBuffer[1]."Use Duplication List";
                        END;
                        GenJnlLine."IC Partner Code" := "Sell-to IC Partner Code";
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

                        RunGenJnlPostLine(GenJnlLine, InvPostingBuffer[1]."Dimension Entry No.");
                        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
                        GenJnlLine.VALIDATE("FA Posting Type", GenJnlLine."FA Posting Type"::" ");

                    UNTIL InvPostingBuffer[1].NEXT(-1) = 0;

                InvPostingBuffer[1].DELETEALL;


                // Post customer entry
                IF ShowDialog THEN  //LS
                    Window.UPDATE(4, 1);
                GenJnlLine.INIT;
                GenJnlLine."Posting Date" := "Posting Date";
                GenJnlLine."Document Date" := "Document Date";
                //---APNT
                PremiseSetup.GET;
                //APNT 15Jan18
                //IF (Rec."Reason Code" = PremiseSetup."Reason Code") THEN
                IF (Rec."Reason Code" = PremiseSetup."Reason Code") AND ((COMPANYNAME = 'Arabian Center') OR (COMPANYNAME = 'Lamcy Plaza')) THEN
                    GenJnlLine.Description := 'VAT INVOICE'
                ELSE
                    GenJnlLine.Description := "Posting Description";
                //APNT 15Jan18
                GenJnlLine."Shortcut Dimension 1 Code" := "Shortcut Dimension 1 Code";
                GenJnlLine."Shortcut Dimension 2 Code" := "Shortcut Dimension 2 Code";
                GenJnlLine."Reason Code" := "Reason Code";
                GenJnlLine."Account Type" := GenJnlLine."Account Type"::Customer;
                GenJnlLine."Account No." := "Bill-to Customer No.";
                GenJnlLine."Document Type" := GenJnlLineDocType;
                GenJnlLine."Document No." := GenJnlLineDocNo;
                GenJnlLine."External Document No." := GenJnlLineExtDocNo;
                GenJnlLine."Currency Code" := "Currency Code";
                GenJnlLine.Amount := -TotalSalesLine."Amount Including VAT";
                GenJnlLine."Source Currency Code" := "Currency Code";
                GenJnlLine."Source Currency Amount" := -TotalSalesLine."Amount Including VAT";
                GenJnlLine."Amount (LCY)" := -TotalSalesLineLCY."Amount Including VAT";
                IF SalesHeader."Currency Code" = '' THEN
                    GenJnlLine."Currency Factor" := 1
                ELSE
                    GenJnlLine."Currency Factor" := SalesHeader."Currency Factor";
                GenJnlLine.Correction := Correction;
                GenJnlLine."Sales/Purch. (LCY)" := -TotalSalesLineLCY.Amount;
                GenJnlLine."Profit (LCY)" := -(TotalSalesLineLCY.Amount - TotalSalesLineLCY."Unit Cost (LCY)");
                GenJnlLine."Inv. Discount (LCY)" := -TotalSalesLineLCY."Inv. Discount Amount";
                GenJnlLine."Sell-to/Buy-from No." := "Sell-to Customer No.";
                GenJnlLine."Bill-to/Pay-to No." := "Bill-to Customer No.";
                GenJnlLine."Salespers./Purch. Code" := "Salesperson Code";
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
                GenJnlLine."Source Type" := GenJnlLine."Source Type"::Customer;
                GenJnlLine."Source No." := "Bill-to Customer No.";
                GenJnlLine."Source Code" := SrcCode;
                GenJnlLine."Posting No. Series" := "Posting No. Series";
                GenJnlLine."IC Partner Code" := "Sell-to IC Partner Code";
                //APNT-IC1.0
                IF "IC Transaction No." <> 0 THEN BEGIN
                    GenJnlLine."IC Transaction No." := "IC Transaction No.";
                    GenJnlLine."IC Partner Direction" := "IC Partner Direction";
                END ELSE BEGIN
                    GenJnlLine."IC Transaction No." := ICTransactionNo;
                    GenJnlLine."IC Partner Direction" := ICDirection;
                END;
                //APNT-IC1.0
                GenJnlLine."Batch No." := "Batch No.";  //LS

                //DP6.01.01 START
                IF "Ref. Document No." <> '' THEN BEGIN
                    GenJnlLine."Ref. Document Type" := "Ref. Document Type";
                    GenJnlLine."Ref. Document No." := "Ref. Document No.";
                END;
                //DP6.01.01 STOP

                TempJnlLineDim.DELETEALL;
                TempDocDim.RESET;
                TempDocDim.SETRANGE("Table ID", DATABASE::"Sales Header");
                DimMgt.CopyDocDimToJnlLineDim(TempDocDim, TempJnlLineDim);
                GenJnlPostLine.RunWithCheck(GenJnlLine, TempJnlLineDim);

                // Balancing account
                IF "Bal. Account No." <> '' THEN BEGIN
                    IF ShowDialog THEN  //LS
                        Window.UPDATE(5, 1);
                    CustLedgEntry.FINDLAST;
                    GenJnlLine.INIT;
                    GenJnlLine."Posting Date" := "Posting Date";
                    GenJnlLine."Document Date" := "Document Date";
                    GenJnlLine.Description := "Posting Description";
                    GenJnlLine."Shortcut Dimension 1 Code" := "Shortcut Dimension 1 Code";
                    GenJnlLine."Shortcut Dimension 2 Code" := "Shortcut Dimension 2 Code";
                    GenJnlLine."Reason Code" := "Reason Code";
                    GenJnlLine."Account Type" := GenJnlLine."Account Type"::Customer;
                    GenJnlLine."Account No." := "Bill-to Customer No.";
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
                    GenJnlLine.Amount :=
                      TotalSalesLine."Amount Including VAT" + CustLedgEntry."Remaining Pmt. Disc. Possible";
                    GenJnlLine."Source Currency Code" := "Currency Code";
                    GenJnlLine."Source Currency Amount" := GenJnlLine.Amount;
                    GenJnlLine.Correction := Correction;
                    CustLedgEntry.CALCFIELDS(Amount);
                    IF CustLedgEntry.Amount = 0 THEN
                        GenJnlLine."Amount (LCY)" := TotalSalesLineLCY."Amount Including VAT"
                    ELSE
                        GenJnlLine."Amount (LCY)" :=
                          TotalSalesLineLCY."Amount Including VAT" +
                          ROUND(
                            CustLedgEntry."Remaining Pmt. Disc. Possible" /
                            CustLedgEntry."Adjusted Currency Factor");
                    IF SalesHeader."Currency Code" = '' THEN
                        GenJnlLine."Currency Factor" := 1
                    ELSE
                        GenJnlLine."Currency Factor" := SalesHeader."Currency Factor";
                    GenJnlLine."Applies-to Doc. Type" := GenJnlLineDocType;
                    GenJnlLine."Applies-to Doc. No." := GenJnlLineDocNo;
                    GenJnlLine."Source Type" := GenJnlLine."Source Type"::Customer;
                    GenJnlLine."Source No." := "Bill-to Customer No.";
                    GenJnlLine."Source Code" := SrcCode;
                    GenJnlLine."Posting No. Series" := "Posting No. Series";
                    GenJnlLine."IC Partner Code" := "Sell-to IC Partner Code";
                    //APNT-IC1.0
                    IF "IC Transaction No." <> 0 THEN BEGIN
                        GenJnlLine."IC Transaction No." := "IC Transaction No.";
                        GenJnlLine."IC Partner Direction" := "IC Partner Direction";
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

            CreateVATSalesInvoiceEntries(SalesHeader); //APNT   9JAN18

            IF ICGenJnlLineNo > 0 THEN
                PostICGenJnl;

            InvtSetup.GET;
            IF InvtSetup."Automatic Cost Adjustment" <>
               InvtSetup."Automatic Cost Adjustment"::Never
            THEN BEGIN
                InvtAdjmt.SetProperties(TRUE, InvtSetup."Automatic Cost Posting");
                InvtAdjmt.MakeMultiLevelAdjmt;
            END;

            // Modify/delete sales header and sales lines
            IF NOT RECORDLEVELLOCKING THEN BEGIN
                IF WhseReceive THEN
                    WhseRcptLine.LOCKTABLE(TRUE, TRUE);
                IF WhseShip THEN
                    WhseShptLine.LOCKTABLE(TRUE, TRUE);
                IF DropShipOrder THEN BEGIN
                    PurchOrderLine.LOCKTABLE(TRUE, TRUE);
                    PurchOrderHeader.LOCKTABLE(TRUE, TRUE);
                END;
                DocDim.LOCKTABLE(TRUE, TRUE);
                IF InvtPickPutaway THEN
                    WhseRqst.LOCKTABLE(TRUE, TRUE);
                SalesLine.LOCKTABLE(TRUE, TRUE);
                ItemChargeAssgntSales.LOCKTABLE(TRUE, TRUE);
            END;

            IF Ship THEN BEGIN
                "Last Shipping No." := "Shipping No.";
                "Shipping No." := '';
            END;
            IF Invoice THEN BEGIN
                "Last Posting No." := "Posting No.";
                "Posting No." := '';
            END;
            IF Receive THEN BEGIN
                "Last Return Receipt No." := "Return Receipt No.";
                "Return Receipt No." := '';
            END;

            IF ("Document Type" IN ["Document Type"::Order, "Document Type"::"Return Order"]) AND
               (NOT EverythingInvoiced)
            THEN BEGIN
                MODIFY;
                // Insert T336 records
                InsertTrackingSpecification;

                IF SalesLine.FINDSET THEN
                    REPEAT
                        IF SalesLine.Quantity <> 0 THEN BEGIN
                            IF Ship THEN BEGIN
                                SalesLine."Quantity Shipped" :=
                                  SalesLine."Quantity Shipped" +
                                  SalesLine."Qty. to Ship";
                                SalesLine."Qty. Shipped (Base)" :=
                                  SalesLine."Qty. Shipped (Base)" +
                                  SalesLine."Qty. to Ship (Base)";
                            END;
                            IF Receive THEN BEGIN
                                SalesLine."Return Qty. Received" :=
                                  SalesLine."Return Qty. Received" + SalesLine."Return Qty. to Receive";
                                SalesLine."Return Qty. Received (Base)" :=
                                  SalesLine."Return Qty. Received (Base)" +
                                  SalesLine."Return Qty. to Receive (Base)";
                            END;
                            IF Invoice THEN BEGIN
                                TempPrePmtAmtToDeduct := SalesLine."Prepmt Amt to Deduct";
                                IF "Document Type" = "Document Type"::Order THEN BEGIN
                                    IF ABS(SalesLine."Quantity Invoiced" + SalesLine."Qty. to Invoice") >
                                       ABS(SalesLine."Quantity Shipped")
                                    THEN BEGIN
                                        SalesLine.VALIDATE("Qty. to Invoice",
                                          SalesLine."Quantity Shipped" - SalesLine."Quantity Invoiced");
                                        SalesLine."Qty. to Invoice (Base)" :=
                                          SalesLine."Qty. Shipped (Base)" - SalesLine."Qty. Invoiced (Base)";
                                    END;
                                END ELSE
                                    IF ABS(SalesLine."Quantity Invoiced" + SalesLine."Qty. to Invoice") >
                                       ABS(SalesLine."Return Qty. Received")
                                    THEN BEGIN
                                        SalesLine.VALIDATE("Qty. to Invoice",
                                          SalesLine."Return Qty. Received" - SalesLine."Quantity Invoiced");
                                        SalesLine."Qty. to Invoice (Base)" :=
                                          SalesLine."Return Qty. Received (Base)" - SalesLine."Qty. Invoiced (Base)";
                                    END;

                                SalesLine."Prepmt Amt to Deduct" := TempPrePmtAmtToDeduct;

                                SalesLine."Quantity Invoiced" := SalesLine."Quantity Invoiced" + SalesLine."Qty. to Invoice";
                                SalesLine."Qty. Invoiced (Base)" := SalesLine."Qty. Invoiced (Base)" + SalesLine."Qty. to Invoice (Base)";
                                IF SalesLine."Qty. to Invoice" <> 0 THEN BEGIN
                                    SalesLine."Prepmt Amt Deducted" :=
                                      SalesLine."Prepmt Amt Deducted" + SalesLine."Prepmt Amt to Deduct";
                                    SalesLine."Prepmt VAT Diff. Deducted" :=
                                      SalesLine."Prepmt VAT Diff. Deducted" + SalesLine."Prepmt VAT Diff. to Deduct";
                                    IF "Currency Code" <> '' THEN BEGIN
                                        TempPrePayDeductLCYSalesLine := SalesLine;
                                        IF TempPrePayDeductLCYSalesLine.FIND THEN
                                            SalesLine."Prepmt. Amount Inv. (LCY)" := SalesLine."Prepmt. Amount Inv. (LCY)" -
                                              TempPrePayDeductLCYSalesLine."Prepmt. Amount Inv. (LCY)";
                                    END ELSE
                                        SalesLine."Prepmt. Amount Inv. (LCY)" :=
                                          ROUND(
                                            ROUND(
                                              ROUND(SalesLine."Unit Price" * (SalesLine.Quantity - SalesLine."Quantity Shipped"),
                                                Currency."Amount Rounding Precision") *
                                              (1 - SalesLine."Line Discount %" / 100), Currency."Amount Rounding Precision") *
                                            SalesLine."Prepayment %" / 100, Currency."Amount Rounding Precision");
                                    SalesLine."Prepmt Amt to Deduct" :=
                                      SalesLine."Prepmt. Amt. Inv." - SalesLine."Prepmt Amt Deducted";
                                    SalesLine."Prepmt VAT Diff. to Deduct" := 0;
                                END;
                            END;

                            UpdateBlanketOrderLine(SalesLine, Ship, Receive, Invoice);
                            SalesLine.InitOutstanding;

                            IF WhseHandlingRequired OR (SalesSetup."Default Quantity to Ship" = SalesSetup."Default Quantity to Ship"::Blank)
                            THEN BEGIN
                                IF "Document Type" = "Document Type"::"Return Order" THEN BEGIN
                                    SalesLine."Return Qty. to Receive" := 0;
                                    SalesLine."Return Qty. to Receive (Base)" := 0;
                                END ELSE BEGIN
                                    SalesLine."Qty. to Ship" := 0;
                                    SalesLine."Qty. to Ship (Base)" := 0;
                                END;
                                SalesLine.InitQtyToInvoice;
                            END ELSE BEGIN
                                IF "Document Type" = "Document Type"::"Return Order" THEN
                                    SalesLine.InitQtyToReceive
                                ELSE
                                    SalesLine.InitQtyToShip2;
                            END;

                            IF (SalesLine."Purch. Order Line No." <> 0) AND
                               (SalesLine.Quantity = SalesLine."Quantity Invoiced")
                            THEN
                                UpdateAssocLines(SalesLine);
                            SalesLine.SetDefaultQuantity;
                            SalesLine.MODIFY;
                        END;
                    UNTIL SalesLine.NEXT = 0;

                UpdateAssocOrder;

                IF WhseReceive THEN BEGIN
                    WhsePostRcpt.PostUpdateWhseDocuments(WhseRcptHeader);
                    TempWhseRcptHeader.DELETE;
                END;
                IF WhseShip THEN BEGIN
                    WhsePostShpt.PostUpdateWhseDocuments(WhseShptHeader);
                    TempWhseShptHeader.DELETE;
                END;

                WhseSalesRelease.Release(SalesHeader);
                UpdateItemChargeAssgnt;

                IF RoundingLineInserted THEN BEGIN
                    DocDim.RESET;
                    DocDim.SETRANGE("Table ID", DATABASE::"Sales Line");
                    DocDim.SETRANGE("Document Type", "Document Type");
                    DocDim.SETRANGE("Document No.", "No.");
                    DocDim.SETRANGE("Line No.", RoundingLineNo);
                    DocDim.DELETEALL;
                END;

            END ELSE BEGIN

                CASE "Document Type" OF
                    "Document Type"::Invoice:
                        BEGIN
                            SalesLine.SETFILTER("Shipment No.", '<>%1', '');
                            IF SalesLine.FINDSET THEN
                                REPEAT
                                    IF SalesLine.Type <> SalesLine.Type::" " THEN BEGIN
                                        SalesShptLine.GET(SalesLine."Shipment No.", SalesLine."Shipment Line No.");
                                        TempSalesLine.GET(
                                          TempSalesLine."Document Type"::Order,
                                          SalesShptLine."Order No.", SalesShptLine."Order Line No.");
                                        IF SalesLine.Type = SalesLine.Type::"Charge (Item)" THEN
                                            UpdateSalesOrderChargeAssgnt(SalesLine, TempSalesLine);
                                        TempSalesLine."Quantity Invoiced" :=
                                          TempSalesLine."Quantity Invoiced" + SalesLine."Qty. to Invoice";
                                        TempSalesLine."Qty. Invoiced (Base)" :=
                                          TempSalesLine."Qty. Invoiced (Base)" + SalesLine."Qty. to Invoice (Base)";
                                        IF ABS(TempSalesLine."Quantity Invoiced") > ABS(TempSalesLine."Quantity Shipped") THEN
                                            ERROR(
                                              Text014,
                                              TempSalesLine."Document No.");
                                        TempSalesLine.InitQtyToInvoice;
                                        TempSalesLine."Prepmt Amt Deducted" := TempSalesLine."Prepmt Amt Deducted" + SalesLine."Prepmt Amt to Deduct";
                                        TempSalesLine."Prepmt VAT Diff. Deducted" :=
                                          TempSalesLine."Prepmt VAT Diff. Deducted" + SalesLine."Prepmt VAT Diff. to Deduct";
                                        IF "Currency Code" <> '' THEN BEGIN
                                            TempPrePayDeductLCYSalesLine := SalesLine;
                                            IF TempPrePayDeductLCYSalesLine.FIND THEN
                                                TempSalesLine."Prepmt. Amount Inv. (LCY)" := TempSalesLine."Prepmt. Amount Inv. (LCY)" -
                                                  TempPrePayDeductLCYSalesLine."Prepmt. Amount Inv. (LCY)";
                                        END ELSE
                                            TempSalesLine."Prepmt. Amount Inv. (LCY)" := TempSalesLine."Prepmt. Amount Inv. (LCY)" -
                                              SalesLine."Prepmt Amt to Deduct";
                                        IF (TempSalesLine."Quantity Invoiced" = TempSalesLine.Quantity) AND
                                          (TempSalesLine."Prepayment %" <> 0) THEN
                                            PrepayRealizeGainLoss(TempSalesLine);
                                        TempSalesLine."Prepmt Amt to Deduct" := TempSalesLine."Prepmt. Amt. Inv." - TempSalesLine."Prepmt Amt Deducted";
                                        TempSalesLine."Prepmt VAT Diff. to Deduct" := 0;
                                        TempSalesLine.InitOutstanding;
                                        IF (TempSalesLine."Purch. Order Line No." <> 0) AND
                                           (TempSalesLine.Quantity = TempSalesLine."Quantity Invoiced")
                                        THEN
                                            UpdateAssocLines(TempSalesLine);
                                        TempSalesLine.MODIFY;
                                    END;
                                UNTIL SalesLine.NEXT = 0;
                            InsertTrackingSpecification;

                            SalesLine.SETRANGE("Shipment No.");
                        END;
                    "Document Type"::"Credit Memo":
                        BEGIN
                            SalesLine.SETFILTER("Return Receipt No.", '<>%1', '');
                            IF SalesLine.FINDSET THEN
                                REPEAT
                                    IF SalesLine.Type <> SalesLine.Type::" " THEN BEGIN
                                        ReturnRcptLine.GET(SalesLine."Return Receipt No.", SalesLine."Return Receipt Line No.");
                                        TempSalesLine.GET(
                                          TempSalesLine."Document Type"::"Return Order",
                                          ReturnRcptLine."Return Order No.", ReturnRcptLine."Return Order Line No.");
                                        IF SalesLine.Type = SalesLine.Type::"Charge (Item)" THEN
                                            UpdateSalesOrderChargeAssgnt(SalesLine, TempSalesLine);
                                        TempSalesLine."Quantity Invoiced" :=
                                          TempSalesLine."Quantity Invoiced" + SalesLine."Qty. to Invoice";
                                        TempSalesLine."Qty. Invoiced (Base)" :=
                                          TempSalesLine."Qty. Invoiced (Base)" + SalesLine."Qty. to Invoice (Base)";
                                        IF ABS(TempSalesLine."Quantity Invoiced") > ABS(TempSalesLine."Return Qty. Received") THEN
                                            ERROR(
                                              Text036,
                                              TempSalesLine."Document No.");
                                        TempSalesLine.InitQtyToInvoice;
                                        TempSalesLine.InitOutstanding;
                                        TempSalesLine.MODIFY;
                                    END;
                                UNTIL SalesLine.NEXT = 0;
                            InsertTrackingSpecification;

                            SalesLine.SETRANGE("Return Receipt No.");
                        END;
                    ELSE BEGIN
                        UpdateAssocOrder;
                        IF DropShipOrder THEN
                            InsertTrackingSpecification;
                        IF SalesLine.FINDSET THEN
                            REPEAT
                                IF SalesLine."Purch. Order Line No." <> 0 THEN
                                    UpdateAssocLines(SalesLine);
                                IF (SalesLine."Prepayment %" <> 0) THEN BEGIN
                                    IF "Currency Code" <> '' THEN BEGIN
                                        TempPrePayDeductLCYSalesLine := SalesLine;
                                        IF TempPrePayDeductLCYSalesLine.FIND THEN
                                            SalesLine."Prepmt. Amount Inv. (LCY)" := SalesLine."Prepmt. Amount Inv. (LCY)" -
                                              TempPrePayDeductLCYSalesLine."Prepmt. Amount Inv. (LCY)";
                                    END ELSE
                                        SalesLine."Prepmt. Amount Inv. (LCY)" := SalesLine."Prepmt. Amount Inv. (LCY)" - SalesLine."Prepmt Amt to Deduct";
                                    PrepayRealizeGainLoss(SalesLine);
                                END;
                            UNTIL SalesLine.NEXT = 0;
                    END;
                END;

                SalesLine.SETFILTER("Blanket Order Line No.", '<>0');
                IF SalesLine.FINDSET THEN
                    REPEAT
                        UpdateBlanketOrderLine(SalesLine, Ship, Receive, Invoice);
                    UNTIL SalesLine.NEXT = 0;
                SalesLine.SETRANGE("Blanket Order Line No.");

                IF WhseReceive THEN BEGIN
                    WhsePostRcpt.PostUpdateWhseDocuments(WhseRcptHeader);
                    TempWhseRcptHeader.DELETE;
                END;
                IF WhseShip THEN BEGIN
                    WhsePostShpt.PostUpdateWhseDocuments(WhseShptHeader);
                    TempWhseShptHeader.DELETE;
                END;

                DocDim.RESET;
                DocDim.SETRANGE("Table ID", DATABASE::"Sales Header");
                DocDim.SETRANGE("Document Type", "Document Type");
                DocDim.SETRANGE("Document No.", "No.");
                DocDim.DELETEALL;
                DocDim.SETRANGE("Table ID", DATABASE::"Sales Line");
                DocDim.DELETEALL;

                ApprovalMgt.DeleteApprovalEntry(DATABASE::"Sales Header", "Document Type", "No.");

                IF HASLINKS THEN DELETELINKS;
                DELETE;

                DeleteSPOPaymentLines();  //LS
                ReserveSalesLine.DeleteInvoiceSpecFromHeader(SalesHeader);
                IF SalesLine.FINDFIRST THEN
                    REPEAT
                        IF SalesLine.HASLINKS THEN
                            SalesLine.DELETELINKS;
                        DeleteSPOOptionTypeValues(); //LS
                    UNTIL SalesLine.NEXT = 0;
                SalesLine.DELETEALL;
                DeleteItemChargeAssgnt;
                SalesCommentLine.SETRANGE("Document Type", "Document Type");
                SalesCommentLine.SETRANGE("No.", "No.");
                IF NOT SalesCommentLine.ISEMPTY THEN
                    SalesCommentLine.DELETEALL;
                WhseRqst.SETCURRENTKEY("Source Type", "Source Subtype", "Source No.");
                WhseRqst.SETRANGE("Source Type", DATABASE::"Sales Line");
                WhseRqst.SETRANGE("Source Subtype", "Document Type");
                WhseRqst.SETRANGE("Source No.", "No.");
                IF NOT WhseRqst.ISEMPTY THEN
                    WhseRqst.DELETEALL;
            END;

            InsertValueEntryRelation;

            BOUtils.ReplicateUsingRegEntry();  //LS

            //LS -
            //IF NOT InvtPickPutaway THEN
            IF (NOT InvtPickPutaway) AND (NOT FromStatement) AND (NOT "SPO-Created Entry") THEN
                //LS +
                COMMIT;
            CLEAR(WhsePostRcpt);
            CLEAR(WhsePostShpt);
            CLEAR(GenJnlPostLine);
            CLEAR(ResJnlPostLine);
            CLEAR(JobPostLine);
            CLEAR(ItemJnlPostLine);
            CLEAR(WhseJnlPostLine);
            CLEAR(InvtAdjmt);
            IF ShowDialog THEN  //LS
                Window.CLOSE;
            //APNT-IC1.0
            /*
            IF Invoice AND ("Bill-to IC Partner Code" <> '') THEN
              IF "Document Type" IN ["Document Type"::Order,"Document Type"::Invoice] THEN
                ICInOutBoxMgt.CreateOutboxSalesInvTrans(SalesInvHeader)
              ELSE
                ICInOutBoxMgt.CreateOutboxSalesCrMemoTrans(SalesCrMemoHeader);
            */
            //APNT-IC1.0

            //APNT-WMS1.0 +
            //300918  START MJ
            CLEAR(RecLocation);
            IF RecLocation.GET(SalesHeader."Location Code") THEN BEGIN
                IF RecLocation."WMS Active" THEN BEGIN
                    //ReleaseSalesDoc.PerformManualReopen(Rec);
                    RecSalesLine.RESET;
                    RecSalesLine.SETRANGE("Document Type", SalesHeader."Document Type");
                    RecSalesLine.SETRANGE("Document No.", SalesHeader."No.");
                    IF RecSalesLine.FINDFIRST THEN
                        REPEAT
                            RecSalesLine.VALIDATE("Qty. to Ship", 0);
                            RecSalesLine.MODIFY;
                        UNTIL RecSalesLine.NEXT = 0;
                    //ReleaseSalesDoc.PerformManualRelease(Rec);
                END ELSE BEGIN
                    IF (SalesHeader."HRU Document" = TRUE) AND (SalesHeader.Status = SalesHeader.Status::Released) AND
                      (SalesHeader."Transaction Posted" = TRUE) AND (SalesHeader."SO Lines Reversed" = TRUE) AND
                      (SalesHeader."Statement Posted" = TRUE) THEN BEGIN
                        RecSalesLine.RESET;
                        RecSalesLine.SETRANGE("Document Type", SalesHeader."Document Type");
                        RecSalesLine.SETRANGE("Document No.", SalesHeader."No.");
                        IF RecSalesLine.FINDFIRST THEN
                            REPEAT
                                CLEAR(RecLocation);
                                IF RecLocation.GET(RecSalesLine."Delivery By location") THEN BEGIN
                                    IF RecLocation."WMS Active" THEN BEGIN
                                        RecSalesLine.VALIDATE("Qty. to Ship", 0);
                                        RecSalesLine.MODIFY;
                                    END;
                                END;
                            UNTIL RecSalesLine.NEXT = 0;
                    END;
                END;
            END;
            //APNT-WMS1.0 -
            //300918  START MJ
        END;

        IF NOT FromStatement THEN BEGIN  //LS
            UpdateAnalysisView.UpdateAll(0, TRUE);
            UpdateItemAnalysisView.UpdateAll(0, TRUE);
        END;  //LS
        Rec := SalesHeader;
        SynchBOMSerialNo(ServiceItemTmp2, ServiceItemCmpTmp2);

    end;

    var
        Text001: Label 'There is nothing to post.';
        Text002: Label 'Posting lines              #2######\';
        Text003: Label 'Posting sales and VAT      #3######\';
        Text004: Label 'Posting to customers       #4######\';
        Text005: Label 'Posting to bal. account    #5######';
        Text006: Label 'Posting lines              #2######';
        Text007: Label '%1 %2 -> Invoice %3';
        Text008: Label '%1 %2 -> Credit Memo %3';
        Text009: Label 'You cannot ship sales order line %1. ';
        Text010: Label 'The line is marked as a drop shipment and is not yet associated with a purchase order.';
        Text011: Label 'must have the same sign as the shipment';
        Text013: Label 'The shipment lines have been deleted.';
        Text014: Label 'You cannot invoice more than you have shipped for order %1.';
        Text016: Label 'VAT Amount';
        Text017: Label '%1% VAT';
        Text018: Label 'in the associated blanket order must not be greater than %1';
        Text019: Label 'in the associated blanket order must not be reduced.';
        Text020: Label 'Please enter "Yes" in %1 and/or %2 and/or %3.';
        Text021: Label 'Warehouse handling is required for %1 = %2, %3 = %4, %5 = %6.';
        Text023: Label 'This order must be a complete Shipment.';
        Text024: Label 'must have the same sign as the return receipt';
        Text025: Label 'Line %1 of the return receipt %2, which you are attempting to invoice, has already been invoiced.';
        Text026: Label 'Line %1 of the shipment %2, which you are attempting to invoice, has already been invoiced.';
        Text027: Label 'The quantity you are attempting to invoice is greater than the quantity in shipment %1.';
        Text028: Label 'The combination of dimensions used in %1 %2 is blocked. %3';
        Text029: Label 'The combination of dimensions used in %1 %2, line no. %3 is blocked. %4';
        Text030: Label 'The dimensions used in %1 %2 are invalid. %3';
        Text031: Label 'The dimensions used in %1 %2, line no. %3 are invalid. %4';
        Text032: Label 'You cannot assign more than %1 units in %2 = %3, %4 = %5,%6 = %7.';
        Text033: Label 'You must assign all item charges, if you invoice everything.';
        Item: Record Item;
        CurrExchRate: Record "Currency Exchange Rate";
        SalesSetup: Record "Sales & Receivables Setup";
        GLSetup: Record "General Ledger Setup";
        InvtSetup: Record "Inventory Setup";
        GLEntry: Record "G/L Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempSalesLine: Record "Sales Line";
        SalesLineACY: Record "Sales Line";
        TotalSalesLine: Record "Sales Line";
        TotalSalesLineLCY: Record "Sales Line";
        TempPrepaymentSalesLine: Record "Sales Line" temporary;
        CombinedSalesLineTemp: Record "Sales Line" temporary;
        SalesShptHeader: Record "Sales Shipment Header";
        SalesShptLine: Record "Sales Shipment Line";
        SalesInvHeader: Record "Sales Invoice Header";
        SalesInvLine: Record "Sales Invoice Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        ReturnRcptHeader: Record "Return Receipt Header";
        ReturnRcptLine: Record "Return Receipt Line";
        PurchOrderHeader: Record "Purchase Header";
        PurchOrderLine: Record "Purchase Line";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
        TempItemChargeAssgntSales: Record "Item Charge Assignment (Sales)" temporary;
        GenJnlLine: Record "Gen. Journal Line";
        ItemJnlLine: Record "Item Journal Line";
        ResJnlLine: Record "Resource Journal Line";
        CustPostingGr: Record "Customer Posting Group";
        SourceCodeSetup: Record "Source Code Setup";
        SourceCode: Record "Source Code";
        SalesCommentLine: Record "Sales Comment Line";
        SalesCommentLine2: Record "Sales Comment Line";
        GenPostingSetup: Record "General Posting Setup";
        CustLedgEntry: Record "Cust. Ledger Entry";
        Currency: Record Currency;
        InvPostingBuffer: array[2] of Record "Invt. Posting Buffer" temporary;
        DropShipPostBuffer: Record "Drop Shpt. Post. Buffer" temporary;
        GLAcc: Record "G/L Account";
        DocDim: Record "Document Dimension";
        TempDocDim: Record "Document Dimension" temporary;
        ApprovalEntry: Record "Approval Entry";
        TempApprovalEntry: Record "Approval Entry" temporary;
        PrepmtDocDim: Record "Document Dimension" temporary;
        FA: Record "Fixed Asset";
        DeprBook: Record "Depreciation Book";
        WhseRqst: Record "Warehouse Request";
        WhseRcptHeader: Record "Warehouse Receipt Header";
        TempWhseRcptHeader: Record "Warehouse Receipt Header" temporary;
        WhseRcptLine: Record "Warehouse Receipt Line";
        WhseShptHeader: Record "Warehouse Shipment Header";
        TempWhseShptHeader: Record "Warehouse Shipment Header" temporary;
        WhseShptLine: Record "Warehouse Shipment Line";
        PostedWhseRcptHeader: Record "Posted Whse. Receipt Header";
        PostedWhseRcptLine: Record "Posted Whse. Receipt Line";
        PostedWhseShptHeader: Record "Posted Whse. Shipment Header";
        PostedWhseShptLine: Record "Posted Whse. Shipment Line";
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        TempVATAmountLineRemainder: Record "VAT Amount Line" temporary;
        Location: Record Location;
        TempHandlingSpecification: Record "Tracking Specification" temporary;
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        TempTrackingSpecificationInv: Record "Tracking Specification" temporary;
        TempWhseSplitSpecification: Record "Tracking Specification" temporary;
        TempValueEntryRelation: Record "Value Entry Relation" temporary;
        JobTaskSalesLine: Record "Sales Line";
        TempICGenJnlLine: Record "Gen. Journal Line" temporary;
        TempICJnlLineDim: Record "Gen. Journal Line Dimension" temporary;
        TempPrePayDeductLCYSalesLine: Record "Sales Line" temporary;
        ServiceItemTmp1: Record "Service Item" temporary;
        ServiceItemTmp2: Record "Service Item" temporary;
        ServiceItemCmpTmp1: Record "Service Item Component" temporary;
        ServiceItemCmpTmp2: Record "Service Item Component" temporary;
        NoSeriesMgt: Codeunit "396";
        GenJnlCheckLine: Codeunit "11";
        GenJnlPostLine: Codeunit "12";
        ResJnlPostLine: Codeunit "212";
        ItemJnlPostLine: Codeunit "22";
        InvtAdjmt: Codeunit "5895";
        ReserveSalesLine: Codeunit "99000832";
        SalesCalcDisc: Codeunit "60";
        DimMgt: Codeunit "408";
        DimBufMgt: Codeunit "411";
        ApprovalMgt: Codeunit "439";
        WhseSalesRelease: Codeunit "5771";
        ItemTrackingMgt: Codeunit "6500";
        WMSMgmt: Codeunit "7302";
        WhseJnlPostLine: Codeunit "7301";
        WhsePostRcpt: Codeunit "5760";
        WhsePostShpt: Codeunit "5763";
        PurchPost: Codeunit "90";
        CostCalcMgt: Codeunit "5836";
        JobPostLine: Codeunit "1001";
        ServItemMgt: Codeunit "5920";
        Window: Dialog;
        PostingDate: Date;
        UseDate: Date;
        GenJnlLineDocNo: Code[20];
        GenJnlLineExtDocNo: Code[20];
        SrcCode: Code[10];
        GenJnlLineDocType: Integer;
        ItemLedgShptEntryNo: Integer;
        LineCount: Integer;
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
        ModifyHeader: Boolean;
        DropShipOrder: Boolean;
        PostingDateExists: Boolean;
        ReplacePostingDate: Boolean;
        ReplaceDocumentDate: Boolean;
        TempInvoice: Boolean;
        TempShpt: Boolean;
        TempReturn: Boolean;
        Text034: Label 'You cannot assign item charges to the %1 %2 = %3,%4 = %5, %6 = %7, because it has been invoiced.';
        Text036: Label 'You cannot invoice more than you have received for return order %1.';
        Text037: Label 'The return receipt lines have been deleted.';
        Text038: Label 'The quantity you are attempting to invoice is greater than the quantity in return receipt %1.';
        ItemChargeAssgntOnly: Boolean;
        ItemJnlRollRndg: Boolean;
        Text040: Label 'Related item ledger entries cannot be found.';
        Text043: Label 'Item Tracking is signed wrongly.';
        Text044: Label 'Item Tracking does not match.';
        WhseShip: Boolean;
        WhseReceive: Boolean;
        InvtPickPutaway: Boolean;
        Text045: Label 'is not within your range of allowed posting dates.';
        Text046: Label 'The %1 does not match the quantity defined in item tracking.';
        Text047: Label 'cannot be more than %1.';
        Text048: Label 'must be at least %1.';
        JobContractLine: Boolean;
        ICGenJnlLineNo: Integer;
        ItemTrkgAlreadyOverruled: Boolean;
        Text050: Label 'The total %1 cannot be more than %2.';
        Text051: Label 'The total %1 must be at least %2.';
        TotalChargeAmt: Decimal;
        TotalChargeAmtLCY: Decimal;
        TotalChargeAmt2: Decimal;
        TotalChargeAmtLCY2: Decimal;
        Text052: Label 'You must assign item charge %1 if you want to invoice it.';
        Text053: Label 'You can not invoice item charge %1 because there is no item ledger entry to assign it to.';
        FromStatement: Boolean;
        tempStatement: Record "99001487" temporary;
        gNotShowDialog: Boolean;
        BOUtils: Codeunit "99001452";
        InStoreMgt: Codeunit "10001320";
        Text054: Label 'Configuration ID ''%1'' not found.';
        Text055: Label 'Configuration ID ''%1'' is not correctly formatted.';
        ICDirection: Option " ",Outgoing,Incoming;
        ICTransactionNo: Integer;
        PremiseSetup: Record "Premise Management Setup";
        eComProcessCustomerOrders: Codeunit "50153";
        Txt10001: Label 'Sales order no %1 cannot be invoiced unitl all lines are shipped, because the order is related to eCom order. ';
        Txt10002: Label 'Sales order no %1 cannot be invoiced unitl all lines are shipped completely, because the order is related to eCom order. ';
        eComCustomerOrderStatus: Record "eCom Customer Order Status L";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CheckLines: Boolean;
        gintMAGLastEntryNo: Integer;
        gtxtMAGLastStatus: Text[100];

    procedure SetPostingDate(NewReplacePostingDate: Boolean; NewReplaceDocumentDate: Boolean; NewPostingDate: Date)
    begin
        PostingDateExists := TRUE;
        ReplacePostingDate := NewReplacePostingDate;
        ReplaceDocumentDate := NewReplaceDocumentDate;
        PostingDate := NewPostingDate;
    end;

    local procedure PostItemJnlLine(SalesLine: Record "Sales Line"; QtyToBeShipped: Decimal; QtyToBeShippedBase: Decimal; QtyToBeInvoiced: Decimal; QtyToBeInvoicedBase: Decimal; ItemLedgShptEntryNo: Integer; ItemChargeNo: Code[20]; TrackingSpecification: Record "Tracking Specification"): Integer
    var
        TempJnlLineDim: Record "Gen. Journal Line Dimension" temporary;
        ItemChargeSalesLine: Record "Sales Line";
        TempWhseJnlLine: Record "Warehouse Journal Line" temporary;
        TempWhseJnlLine2: Record "Warehouse Journal Line" temporary;
        OriginalItemJnlLine: Record "Item Journal Line";
        ShipToAddress: Record "Ship-to Address";
        TempWhseTrackingSpecification: Record "Tracking Specification" temporary;
        PostWhseJnlLine: Boolean;
        CheckApplFromItemEntry: Boolean;
        TempItemUnblocking: Boolean;
        StatementHeader: Record "99001487";
        PstdStatementHeader: Record "99001485";
        StoreRec: Record "99001470";
    begin
        //LS -
        Item.GET(SalesLine."No.");
        IF Item.Blocked AND FromStatement THEN BEGIN // temporarily unblocked
            Item.Blocked := FALSE;
            Item.MODIFY;
            TempItemUnblocking := TRUE;
        END;
        //LS +

        IF NOT ItemJnlRollRndg THEN BEGIN
            RemAmt := 0;
            RemDiscAmt := 0;
        END;
        WITH SalesLine DO BEGIN
            ItemJnlLine.INIT;
            ItemJnlLine."Posting Date" := SalesHeader."Posting Date";
            ItemJnlLine."Document Date" := SalesHeader."Document Date";
            ItemJnlLine."Source Posting Group" := SalesHeader."Customer Posting Group";
            ItemJnlLine."Salespers./Purch. Code" := SalesHeader."Salesperson Code";
            IF SalesHeader."Ship-to Code" <> '' THEN BEGIN
                ShipToAddress.GET("Sell-to Customer No.", SalesHeader."Ship-to Code");
                ItemJnlLine."Country/Region Code" := ShipToAddress."Country/Region Code";
            END ELSE
                ItemJnlLine."Country/Region Code" := SalesHeader."Sell-to Country/Region Code";
            ItemJnlLine."Reason Code" := SalesHeader."Reason Code";
            ItemJnlLine."Item No." := "No.";
            ItemJnlLine.Description := Description;
            ItemJnlLine."Shortcut Dimension 1 Code" := "Shortcut Dimension 1 Code";
            ItemJnlLine."Shortcut Dimension 2 Code" := "Shortcut Dimension 2 Code";
            ItemJnlLine."Location Code" := "Location Code";
            ItemJnlLine."Bin Code" := "Bin Code";
            ItemJnlLine."Variant Code" := "Variant Code";
            ItemJnlLine."Inventory Posting Group" := "Posting Group";
            ItemJnlLine."Gen. Bus. Posting Group" := "Gen. Bus. Posting Group";
            ItemJnlLine."Gen. Prod. Posting Group" := "Gen. Prod. Posting Group";
            ItemJnlLine."Applies-to Entry" := "Appl.-to Item Entry";
            ItemJnlLine."Transaction Type" := "Transaction Type";
            ItemJnlLine."Transport Method" := "Transport Method";
            ItemJnlLine."Entry/Exit Point" := "Exit Point";
            ItemJnlLine.Area := Area;
            ItemJnlLine."Transaction Specification" := "Transaction Specification";
            ItemJnlLine."Drop Shipment" := "Drop Shipment";
            ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::Sale;
            //LS -
            ItemJnlLine."Batch No." := SalesHeader."Batch No.";
            ItemJnlLine."Offer No." := SalesLine."Offer No.";
            //LS +
            ItemJnlLine."Unit of Measure Code" := "Unit of Measure Code";
            ItemJnlLine."Qty. per Unit of Measure" := "Qty. per Unit of Measure";
            ItemJnlLine."Derived from Blanket Order" := "Blanket Order No." <> '';
            ItemJnlLine."Cross-Reference No." := "Cross-Reference No.";
            ItemJnlLine."Originally Ordered No." := "Originally Ordered No.";
            ItemJnlLine."Originally Ordered Var. Code" := "Originally Ordered Var. Code";
            ItemJnlLine."Out-of-Stock Substitution" := "Out-of-Stock Substitution";
            ItemJnlLine."Item Category Code" := "Item Category Code";
            ItemJnlLine.Nonstock := Nonstock;
            ItemJnlLine."Purchasing Code" := "Purchasing Code";
            ItemJnlLine."Product Group Code" := "Product Group Code";
            ItemJnlLine."Return Reason Code" := "Return Reason Code";
            //LS -
            ItemJnlLine.Division := Division;

            IF FromStatement THEN
                ItemJnlLine."BO Doc. No." := SalesHeader."Statement No.";
            //LS +

            ItemJnlLine."Planned Delivery Date" := "Planned Delivery Date";
            ItemJnlLine."Order Date" := SalesHeader."Order Date";

            ItemJnlLine."Serial No." := TrackingSpecification."Serial No.";
            ItemJnlLine."Lot No." := TrackingSpecification."Lot No.";
            //T004720 -
            IF SalesHeader."HRU Document" THEN BEGIN
                IF SalesHeader."Open Statement No." <> '' THEN BEGIN
                    IF StatementHeader.GET(SalesHeader."Open Statement No.") THEN BEGIN
                        IF StoreRec.GET(StatementHeader."Store No.") THEN
                            ItemJnlLine."Sales Location Code" := StoreRec."Location Code";
                    END ELSE BEGIN
                        IF PstdStatementHeader.GET(SalesHeader."Open Statement No.") THEN BEGIN
                            IF StoreRec.GET(PstdStatementHeader."Store No.") THEN
                                ItemJnlLine."Sales Location Code" := StoreRec."Location Code";
                        END;
                    END;
                END;
            END;
            //T004720 +
            //APNT-T004576 -
            IF ItemJnlLine."Line No." <> 0 THEN BEGIN
                IF SalesHeader."HRU Document" THEN BEGIN
                    IF ItemJnlLine."Gen. Prod. Posting Group" <> InvtSetup."Rev. Gen. Prod. Posting Group" THEN
                        ItemJnlLine.TESTFIELD("Gen. Prod. Posting Group", InvtSetup."Rev. Gen. Prod. Posting Group");
                END;
            END;
            //APNT-T004576 +
            IF QtyToBeShipped = 0 THEN BEGIN
                IF "Document Type" IN ["Document Type"::"Return Order", "Document Type"::"Credit Memo"] THEN
                    ItemJnlLine."Document Type" := ItemJnlLine."Document Type"::"Sales Credit Memo"
                ELSE
                    ItemJnlLine."Document Type" := ItemJnlLine."Document Type"::"Sales Invoice";
                ItemJnlLine."Document No." := GenJnlLineDocNo;
                ItemJnlLine."External Document No." := GenJnlLineExtDocNo;
                ItemJnlLine."Posting No. Series" := SalesHeader."Posting No. Series";
                IF QtyToBeInvoiced <> 0 THEN
                    ItemJnlLine."Invoice No." := GenJnlLineDocNo;
            END ELSE BEGIN
                IF "Document Type" IN ["Document Type"::"Return Order", "Document Type"::"Credit Memo"] THEN BEGIN
                    ItemJnlLine."Document Type" := ItemJnlLine."Document Type"::"Sales Return Receipt";
                    ItemJnlLine."Document No." := ReturnRcptHeader."No.";
                    ItemJnlLine."External Document No." := ReturnRcptHeader."External Document No.";
                    ItemJnlLine."Posting No. Series" := ReturnRcptHeader."No. Series";
                END ELSE BEGIN
                    ItemJnlLine."Document Type" := ItemJnlLine."Document Type"::"Sales Shipment";
                    ItemJnlLine."Document No." := SalesShptHeader."No.";
                    ItemJnlLine."External Document No." := SalesShptHeader."External Document No.";
                    ItemJnlLine."Posting No. Series" := SalesShptHeader."No. Series";
                END;
                IF QtyToBeInvoiced <> 0 THEN BEGIN
                    ItemJnlLine."Invoice No." := GenJnlLineDocNo;
                    ItemJnlLine."External Document No." := GenJnlLineExtDocNo;
                    IF ItemJnlLine."Document No." = '' THEN BEGIN
                        IF "Document Type" = "Document Type"::"Credit Memo" THEN
                            ItemJnlLine."Document Type" := ItemJnlLine."Document Type"::"Sales Credit Memo"
                        ELSE
                            ItemJnlLine."Document Type" := ItemJnlLine."Document Type"::"Sales Invoice";
                        ItemJnlLine."Document No." := GenJnlLineDocNo;
                    END;
                    ItemJnlLine."Posting No. Series" := SalesHeader."Posting No. Series";
                END;
            END;

            ItemJnlLine."Document Line No." := "Line No.";
            ItemJnlLine.Quantity := -QtyToBeShipped;
            ItemJnlLine."Quantity (Base)" := -QtyToBeShippedBase;
            ItemJnlLine."Invoiced Quantity" := -QtyToBeInvoiced;
            ItemJnlLine."Invoiced Qty. (Base)" := -QtyToBeInvoicedBase;
            ItemJnlLine."Unit Cost" := "Unit Cost (LCY)";
            ItemJnlLine."Source Currency Code" := SalesHeader."Currency Code";
            ItemJnlLine."Unit Cost (ACY)" := "Unit Cost";
            ItemJnlLine."Value Entry Type" := ItemJnlLine."Value Entry Type"::"Direct Cost";

            IF ItemChargeNo <> '' THEN BEGIN
                ItemJnlLine."Item Charge No." := ItemChargeNo;
                "Qty. to Invoice" := QtyToBeInvoiced;
            END ELSE
                ItemJnlLine."Applies-from Entry" := "Appl.-from Item Entry";

            IF QtyToBeInvoiced <> 0 THEN BEGIN
                ItemJnlLine.Amount := -(Amount * (QtyToBeInvoiced / "Qty. to Invoice") - RemAmt);
                IF SalesHeader."Prices Including VAT" THEN
                    ItemJnlLine."Discount Amount" :=
                      -(("Line Discount Amount" + "Inv. Discount Amount") / (1 + "VAT %" / 100) *
                        (QtyToBeInvoiced / "Qty. to Invoice") - RemDiscAmt)
                ELSE
                    ItemJnlLine."Discount Amount" :=
                      -(("Line Discount Amount" + "Inv. Discount Amount") * (QtyToBeInvoiced / "Qty. to Invoice") - RemDiscAmt);
                RemAmt := ItemJnlLine.Amount - ROUND(ItemJnlLine.Amount);
                RemDiscAmt := ItemJnlLine."Discount Amount" - ROUND(ItemJnlLine."Discount Amount");
                ItemJnlLine.Amount := ROUND(ItemJnlLine.Amount);
                ItemJnlLine."Discount Amount" := ROUND(ItemJnlLine."Discount Amount");
            END ELSE BEGIN
                IF SalesHeader."Prices Including VAT" THEN
                    ItemJnlLine.Amount :=
                      -((QtyToBeShipped * "Unit Price" * (1 - SalesLine."Line Discount %" / 100) / (1 + "VAT %" / 100)) - RemAmt)
                ELSE
                    ItemJnlLine.Amount :=
                      -((QtyToBeShipped * "Unit Price" * (1 - SalesLine."Line Discount %" / 100)) - RemAmt);
                RemAmt := ItemJnlLine.Amount - ROUND(ItemJnlLine.Amount);
                IF SalesHeader."Currency Code" <> '' THEN
                    ItemJnlLine.Amount :=
                      ROUND(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                          SalesHeader."Posting Date", SalesHeader."Currency Code",
                          ItemJnlLine.Amount, SalesHeader."Currency Factor"))
                ELSE
                    ItemJnlLine.Amount := ROUND(ItemJnlLine.Amount);
            END;

            ItemJnlLine."Source Type" := ItemJnlLine."Source Type"::Customer;
            ItemJnlLine."Source No." := "Sell-to Customer No.";
            ItemJnlLine."Invoice-to Source No." := "Bill-to Customer No.";
            ItemJnlLine."Source Code" := SrcCode;
            ItemJnlLine."Item Shpt. Entry No." := ItemLedgShptEntryNo;

            IF NOT JobContractLine THEN BEGIN
                IF SalesSetup."Exact Cost Reversing Mandatory" AND (Type = Type::Item) THEN
                    IF "Document Type" IN ["Document Type"::"Return Order", "Document Type"::"Credit Memo"] THEN
                        CheckApplFromItemEntry := Quantity > 0
                    ELSE
                        CheckApplFromItemEntry := Quantity < 0;

                IF ("Location Code" <> '') AND (Type = Type::Item) AND (ItemJnlLine.Quantity <> 0) THEN BEGIN
                    GetLocation("Location Code");
                    IF (("Document Type" IN ["Document Type"::Invoice, "Document Type"::"Credit Memo"]) AND
                        (Location."Directed Put-away and Pick")) OR
                       (Location."Bin Mandatory" AND NOT (WhseShip OR WhseReceive OR InvtPickPutaway OR "Drop Shipment"))
                    THEN BEGIN
                        CreateWhseJnlLine(ItemJnlLine, SalesLine, TempWhseJnlLine);
                        PostWhseJnlLine := TRUE;
                    END;
                END;

                IF QtyToBeShippedBase <> 0 THEN BEGIN
                    IF "Document Type" IN ["Document Type"::"Return Order", "Document Type"::"Credit Memo"] THEN
                        ReserveSalesLine.TransferSalesLineToItemJnlLine(SalesLine, ItemJnlLine, QtyToBeShippedBase, CheckApplFromItemEntry)
                    ELSE
                        TransferReservToItemJnlLine(
                          SalesLine, ItemJnlLine, -QtyToBeShippedBase, TempTrackingSpecification, CheckApplFromItemEntry);

                    IF CheckApplFromItemEntry THEN
                        TESTFIELD("Appl.-from Item Entry");
                END;

                TempJnlLineDim.DELETEALL;
                TempDocDim.RESET;
                TempDocDim.SETRANGE("Table ID", DATABASE::"Sales Line");
                TempDocDim.SETRANGE("Line No.", SalesLine."Line No.");
                DimMgt.CopyDocDimToJnlLineDim(TempDocDim, TempJnlLineDim);

                OriginalItemJnlLine := ItemJnlLine;
                ItemJnlPostLine.RunWithCheck(ItemJnlLine, TempJnlLineDim);

                IF ItemJnlPostLine.CollectTrackingSpecification(TempHandlingSpecification) THEN
                    IF TempHandlingSpecification.FINDSET THEN
                        REPEAT
                            TempTrackingSpecification := TempHandlingSpecification;
                            TempTrackingSpecification."Source Type" := DATABASE::"Sales Line";
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
                IF PostWhseJnlLine THEN BEGIN
                    ItemTrackingMgt.SplitWhseJnlLine(TempWhseJnlLine, TempWhseJnlLine2, TempWhseTrackingSpecification, FALSE);
                    IF TempWhseJnlLine2.FINDSET THEN
                        REPEAT
                            WhseJnlPostLine.RUN(TempWhseJnlLine2);
                        UNTIL TempWhseJnlLine2.NEXT = 0;
                    TempWhseTrackingSpecification.DELETEALL;
                END;

                IF (Type = Type::Item) AND SalesHeader.Invoice THEN BEGIN
                    ClearItemChargeAssgntFilter;
                    TempItemChargeAssgntSales.SETCURRENTKEY(
                      "Applies-to Doc. Type", "Applies-to Doc. No.", "Applies-to Doc. Line No.");
                    TempItemChargeAssgntSales.SETRANGE("Applies-to Doc. Type", "Document Type");
                    TempItemChargeAssgntSales.SETRANGE("Applies-to Doc. No.", "Document No.");
                    TempItemChargeAssgntSales.SETRANGE("Applies-to Doc. Line No.", "Line No.");
                    IF TempItemChargeAssgntSales.FINDSET THEN
                        REPEAT
                            SalesLine.TESTFIELD("Allow Item Charge Assignment");
                            GetItemChargeLine(ItemChargeSalesLine);
                            ItemChargeSalesLine.CALCFIELDS("Qty. Assigned");
                            IF (ItemChargeSalesLine."Qty. to Invoice" <> 0) OR
                               (ABS(ItemChargeSalesLine."Qty. Assigned") < ABS(ItemChargeSalesLine."Quantity Invoiced"))
                            THEN BEGIN
                                OriginalItemJnlLine."Item Shpt. Entry No." := ItemJnlLine."Item Shpt. Entry No.";
                                PostItemChargePerOrder(OriginalItemJnlLine, ItemChargeSalesLine);
                                TempItemChargeAssgntSales.MARK(TRUE);
                            END;
                        UNTIL TempItemChargeAssgntSales.NEXT = 0;
                END;
            END;
        END;
        //LS -
        IF TempItemUnblocking THEN BEGIN
            Item.GET(Item."No.");
            Item.Blocked := TRUE;
            Item.MODIFY;
            TempItemUnblocking := FALSE;
        END;
        //LS +

        EXIT(ItemJnlLine."Item Shpt. Entry No.");
    end;

    local procedure PostItemChargePerOrder(ItemJnlLine2: Record "Item Journal Line"; ItemChargeSalesLine: Record "Sales Line")
    var
        NonDistrItemJnlLine: Record "Item Journal Line";
        TempJnlLineDim: Record "Gen. Journal Line Dimension" temporary;
        QtyToInvoice: Decimal;
        Factor: Decimal;
        OriginalAmt: Decimal;
        OriginalDiscountAmt: Decimal;
        OriginalQty: Decimal;
        SignFactor: Integer;
    begin
        WITH TempItemChargeAssgntSales DO BEGIN
            SalesLine.TESTFIELD("Job No.", '');
            SalesLine.TESTFIELD("Allow Item Charge Assignment", TRUE);
            ItemJnlLine2."Document No." := GenJnlLineDocNo;
            ItemJnlLine2."External Document No." := GenJnlLineExtDocNo;
            ItemJnlLine2."Item Charge No." := "Item Charge No.";
            ItemJnlLine2.Description := ItemChargeSalesLine.Description;
            ItemJnlLine2."Unit of Measure Code" := '';
            ItemJnlLine2."Qty. per Unit of Measure" := 1;
            ItemJnlLine2."Applies-from Entry" := 0;
            IF "Document Type" IN ["Document Type"::"Return Order", "Document Type"::"Credit Memo"] THEN
                QtyToInvoice :=
                  CalcQtyToInvoice(SalesLine."Return Qty. to Receive (Base)", SalesLine."Qty. to Invoice (Base)")
            ELSE
                QtyToInvoice :=
                  CalcQtyToInvoice(SalesLine."Qty. to Ship (Base)", SalesLine."Qty. to Invoice (Base)");
            IF ItemJnlLine2."Invoiced Quantity" = 0 THEN BEGIN
                ItemJnlLine2."Invoiced Quantity" := ItemJnlLine2.Quantity;
                ItemJnlLine2."Invoiced Qty. (Base)" := ItemJnlLine2."Quantity (Base)";
            END;
            ItemJnlLine2."Document Line No." := ItemChargeSalesLine."Line No.";

            ItemJnlLine2.Amount := "Amount to Assign" * ItemJnlLine2."Invoiced Qty. (Base)" / QtyToInvoice;
            IF "Document Type" IN ["Document Type"::"Return Order", "Document Type"::"Credit Memo"] THEN
                ItemJnlLine2.Amount := -ItemJnlLine2.Amount;
            ItemJnlLine2."Unit Cost (ACY)" :=
              ROUND(ItemJnlLine2.Amount / ItemJnlLine2."Invoiced Qty. (Base)",
                Currency."Unit-Amount Rounding Precision");

            TotalChargeAmt2 := TotalChargeAmt2 + ItemJnlLine2.Amount;
            IF SalesHeader."Currency Code" <> '' THEN BEGIN
                ItemJnlLine2.Amount :=
                  CurrExchRate.ExchangeAmtFCYToLCY(
                    UseDate, SalesHeader."Currency Code", TotalChargeAmt2 + TotalSalesLine.Amount, SalesHeader."Currency Factor") -
                  TotalChargeAmtLCY2 - TotalSalesLineLCY.Amount;
            END ELSE
                ItemJnlLine2.Amount := TotalChargeAmt2 - TotalChargeAmtLCY2;

            ItemJnlLine2.Amount := ROUND(ItemJnlLine2.Amount);
            TotalChargeAmtLCY2 := TotalChargeAmtLCY2 + ItemJnlLine2.Amount;
            ItemJnlLine2."Unit Cost" := ROUND(
              ItemJnlLine2.Amount / ItemJnlLine2."Invoiced Qty. (Base)", GLSetup."Unit-Amount Rounding Precision");
            ItemJnlLine2."Applies-to Entry" := ItemJnlLine2."Item Shpt. Entry No.";

            IF SalesHeader."Currency Code" <> '' THEN
                ItemJnlLine2."Discount Amount" := ROUND(
                  CurrExchRate.ExchangeAmtFCYToLCY(
                    UseDate, SalesHeader."Currency Code",
                    ItemChargeSalesLine."Inv. Discount Amount" * ItemJnlLine2."Invoiced Qty. (Base)" /
                    ItemChargeSalesLine."Quantity (Base)" * "Qty. to Assign" / QtyToInvoice,
                    SalesHeader."Currency Factor"), GLSetup."Amount Rounding Precision")
            ELSE
                ItemJnlLine2."Discount Amount" := ROUND(
                  ItemChargeSalesLine."Inv. Discount Amount" * ItemJnlLine2."Invoiced Qty. (Base)" /
                  ItemChargeSalesLine."Quantity (Base)" * "Qty. to Assign" / QtyToInvoice,
                  GLSetup."Amount Rounding Precision");

            IF "Document Type" IN ["Document Type"::"Return Order", "Document Type"::"Credit Memo"] THEN
                ItemJnlLine2."Discount Amount" := -ItemJnlLine2."Discount Amount";
            ItemJnlLine2."Shortcut Dimension 1 Code" := ItemChargeSalesLine."Shortcut Dimension 1 Code";
            ItemJnlLine2."Shortcut Dimension 2 Code" := ItemChargeSalesLine."Shortcut Dimension 2 Code";
            ItemJnlLine2."Gen. Prod. Posting Group" := ItemChargeSalesLine."Gen. Prod. Posting Group";
            TempJnlLineDim.DELETEALL;
            TempDocDim.RESET;
            TempDocDim.SETRANGE("Table ID", DATABASE::"Sales Line");
            TempDocDim.SETRANGE("Line No.", "Document Line No.");
            DimMgt.CopyDocDimToJnlLineDim(TempDocDim, TempJnlLineDim);
        END;

        WITH TempTrackingSpecificationInv DO BEGIN
            RESET;
            SETRANGE("Source Type", DATABASE::"Sales Line");
            SETRANGE("Source ID", TempItemChargeAssgntSales."Applies-to Doc. No.");
            SETRANGE("Source Ref. No.", TempItemChargeAssgntSales."Applies-to Doc. Line No.");
            IF ISEMPTY THEN
                ItemJnlPostLine.RunWithCheck(ItemJnlLine2, TempJnlLineDim)
            ELSE BEGIN
                FINDSET;
                NonDistrItemJnlLine := ItemJnlLine2;
                OriginalAmt := NonDistrItemJnlLine.Amount;
                OriginalDiscountAmt := NonDistrItemJnlLine."Discount Amount";
                OriginalQty := NonDistrItemJnlLine."Quantity (Base)";
                IF ("Quantity (Base)" / OriginalQty) > 0 THEN
                    SignFactor := 1
                ELSE
                    SignFactor := -1;
                REPEAT
                    Factor := "Quantity (Base)" / OriginalQty * SignFactor;
                    IF (ABS("Quantity (Base)") < ABS(NonDistrItemJnlLine."Quantity (Base)")) THEN BEGIN
                        ItemJnlLine2."Quantity (Base)" := -"Quantity (Base)";
                        ItemJnlLine2."Invoiced Qty. (Base)" := ItemJnlLine2."Quantity (Base)";
                        ItemJnlLine2.Amount :=
                          ROUND(OriginalAmt * Factor, GLSetup."Amount Rounding Precision");
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
                        NonDistrItemJnlLine."Quantity (Base)" -= ItemJnlLine2."Quantity (Base)";
                        NonDistrItemJnlLine.Amount -= ItemJnlLine2.Amount;
                        NonDistrItemJnlLine."Discount Amount" -= ItemJnlLine2."Discount Amount";
                    END ELSE BEGIN // the last time
                        NonDistrItemJnlLine."Quantity (Base)" := -"Quantity (Base)";
                        NonDistrItemJnlLine."Invoiced Qty. (Base)" := -"Quantity (Base)";
                        NonDistrItemJnlLine."Unit Cost" :=
                          ROUND(NonDistrItemJnlLine.Amount / NonDistrItemJnlLine."Invoiced Qty. (Base)",
                           GLSetup."Unit-Amount Rounding Precision");
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

    local procedure PostItemChargePerShpt(SalesLine: Record "Sales Line")
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
        DistributeCharge: Boolean;
    begin
        IF NOT SalesShptLine.GET(
          TempItemChargeAssgntSales."Applies-to Doc. No.", TempItemChargeAssgntSales."Applies-to Doc. Line No.")
        THEN
            ERROR(Text013);
        SalesShptLine.TESTFIELD("Job No.", '');

        IF SalesShptLine."Item Shpt. Entry No." <> 0 THEN
            DistributeCharge :=
              CostCalcMgt.SplitItemLedgerEntriesExist(
                            TempItemLedgEntry, -SalesShptLine."Quantity (Base)", SalesShptLine."Item Shpt. Entry No.")
        ELSE BEGIN
            DistributeCharge := TRUE;
            IF NOT ItemTrackingMgt.CollectItemEntryRelation(TempItemLedgEntry,
              DATABASE::"Sales Shipment Line", 0, SalesShptLine."Document No.",
              '', 0, SalesShptLine."Line No.", -SalesShptLine."Quantity (Base)")
            THEN
                ERROR(Text040);
        END;

        IF DistributeCharge THEN BEGIN
            TempItemLedgEntry.FINDSET;
            NonDistrQuantity := SalesShptLine."Quantity (Base)";
            NonDistrQtyToAssign := TempItemChargeAssgntSales."Qty. to Assign";
            NonDistrAmountToAssign := TempItemChargeAssgntSales."Amount to Assign";
            REPEAT
                Factor := ABS(TempItemLedgEntry.Quantity) / NonDistrQuantity;
                QtyToAssign := NonDistrQtyToAssign * Factor;
                AmountToAssign := ROUND(NonDistrAmountToAssign * Factor, GLSetup."Amount Rounding Precision");
                IF Factor < 1 THEN BEGIN
                    PostItemCharge(SalesLine,
                      TempItemLedgEntry."Entry No.", ABS(TempItemLedgEntry.Quantity),
                      AmountToAssign, QtyToAssign);
                    NonDistrQuantity := NonDistrQuantity - ABS(TempItemLedgEntry.Quantity);
                    NonDistrQtyToAssign := NonDistrQtyToAssign - QtyToAssign;
                    NonDistrAmountToAssign := NonDistrAmountToAssign - AmountToAssign;
                END ELSE // the last time
                    PostItemCharge(SalesLine,
                      TempItemLedgEntry."Entry No.", ABS(TempItemLedgEntry.Quantity),
                      NonDistrAmountToAssign, NonDistrQtyToAssign);
            UNTIL TempItemLedgEntry.NEXT = 0;
        END ELSE
            PostItemCharge(SalesLine,
              SalesShptLine."Item Shpt. Entry No.", SalesShptLine."Quantity (Base)",
              TempItemChargeAssgntSales."Amount to Assign",
              TempItemChargeAssgntSales."Qty. to Assign");
    end;

    local procedure PostItemChargePerRetRcpt(SalesLine: Record "Sales Line")
    var
        ReturnRcptLine: Record "Return Receipt Line";
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        ItemTrackingMgt: Codeunit "6500";
        Factor: Decimal;
        NonDistrQuantity: Decimal;
        NonDistrQtyToAssign: Decimal;
        NonDistrAmountToAssign: Decimal;
        QtyToAssign: Decimal;
        AmountToAssign: Decimal;
        DistributeCharge: Boolean;
    begin
        IF NOT ReturnRcptLine.GET(
          TempItemChargeAssgntSales."Applies-to Doc. No.", TempItemChargeAssgntSales."Applies-to Doc. Line No.")
        THEN
            ERROR(Text013);
        ReturnRcptLine.TESTFIELD("Job No.", '');

        IF ReturnRcptLine."Item Rcpt. Entry No." <> 0 THEN
            DistributeCharge :=
              CostCalcMgt.SplitItemLedgerEntriesExist(
                            TempItemLedgEntry, ReturnRcptLine."Quantity (Base)", ReturnRcptLine."Item Rcpt. Entry No.")
        ELSE BEGIN
            DistributeCharge := TRUE;
            IF NOT ItemTrackingMgt.CollectItemEntryRelation(TempItemLedgEntry,
              DATABASE::"Return Receipt Line", 0, ReturnRcptLine."Document No.",
              '', 0, ReturnRcptLine."Line No.", ReturnRcptLine."Quantity (Base)")
            THEN
                ERROR(Text040);
        END;

        IF DistributeCharge THEN BEGIN
            TempItemLedgEntry.FINDSET;
            NonDistrQuantity := ReturnRcptLine."Quantity (Base)";
            NonDistrQtyToAssign := TempItemChargeAssgntSales."Qty. to Assign";
            NonDistrAmountToAssign := TempItemChargeAssgntSales."Amount to Assign";
            REPEAT
                Factor := ABS(TempItemLedgEntry.Quantity) / NonDistrQuantity;
                QtyToAssign := NonDistrQtyToAssign * Factor;
                AmountToAssign := ROUND(NonDistrAmountToAssign * Factor, GLSetup."Amount Rounding Precision");
                IF Factor < 1 THEN BEGIN
                    PostItemCharge(SalesLine,
                      TempItemLedgEntry."Entry No.", ABS(TempItemLedgEntry.Quantity),
                      AmountToAssign, QtyToAssign);
                    NonDistrQuantity := NonDistrQuantity - ABS(TempItemLedgEntry.Quantity);
                    NonDistrQtyToAssign := NonDistrQtyToAssign - QtyToAssign;
                    NonDistrAmountToAssign := NonDistrAmountToAssign - AmountToAssign;
                END ELSE // the last time
                    PostItemCharge(SalesLine,
                      TempItemLedgEntry."Entry No.", ABS(TempItemLedgEntry.Quantity),
                      NonDistrAmountToAssign, NonDistrQtyToAssign);
            UNTIL TempItemLedgEntry.NEXT = 0;
        END ELSE
            PostItemCharge(SalesLine,
              ReturnRcptLine."Item Rcpt. Entry No.", ReturnRcptLine."Quantity (Base)",
              TempItemChargeAssgntSales."Amount to Assign",
              TempItemChargeAssgntSales."Qty. to Assign")
    end;

    local procedure PostAssocItemJnlLine(QtyToBeShipped: Decimal; QtyToBeShippedBase: Decimal): Integer
    var
        TempDocDim2: Record "Document Dimension" temporary;
        TempJnlLineDim: Record "Gen. Journal Line Dimension" temporary;
        TempHandlingSpecification2: Record "Tracking Specification" temporary;
        ItemEntryRelation: Record "Item Entry Relation";
    begin
        PurchOrderHeader.GET(
          PurchOrderHeader."Document Type"::Order,
          SalesLine."Purchase Order No.");
        PurchOrderLine.GET(
          PurchOrderLine."Document Type"::Order,
          SalesLine."Purchase Order No.", SalesLine."Purch. Order Line No.");

        ItemJnlLine.INIT;
        ItemJnlLine."Source Posting Group" := PurchOrderHeader."Vendor Posting Group";
        ItemJnlLine."Salespers./Purch. Code" := PurchOrderHeader."Purchaser Code";
        ItemJnlLine."Country/Region Code" := PurchOrderHeader."VAT Country/Region Code";
        ItemJnlLine."Reason Code" := PurchOrderHeader."Reason Code";
        ItemJnlLine."Posting No. Series" := PurchOrderHeader."Posting No. Series";
        ItemJnlLine."Item No." := PurchOrderLine."No.";
        ItemJnlLine.Description := PurchOrderLine.Description;
        ItemJnlLine."Shortcut Dimension 1 Code" := PurchOrderLine."Shortcut Dimension 1 Code";
        ItemJnlLine."Shortcut Dimension 2 Code" := PurchOrderLine."Shortcut Dimension 2 Code";
        ItemJnlLine."Location Code" := PurchOrderLine."Location Code";
        ItemJnlLine."Inventory Posting Group" := PurchOrderLine."Posting Group";
        ItemJnlLine."Gen. Bus. Posting Group" := PurchOrderLine."Gen. Bus. Posting Group";
        ItemJnlLine."Gen. Prod. Posting Group" := PurchOrderLine."Gen. Prod. Posting Group";
        ItemJnlLine."Applies-to Entry" := PurchOrderLine."Appl.-to Item Entry";
        ItemJnlLine."Transaction Type" := PurchOrderLine."Transaction Type";
        ItemJnlLine."Transport Method" := PurchOrderLine."Transport Method";
        ItemJnlLine."Entry/Exit Point" := PurchOrderLine."Entry Point";
        ItemJnlLine.Area := PurchOrderLine.Area;
        ItemJnlLine."Transaction Specification" := PurchOrderLine."Transaction Specification";
        ItemJnlLine."Drop Shipment" := PurchOrderLine."Drop Shipment";
        ItemJnlLine."Posting Date" := SalesHeader."Posting Date";
        ItemJnlLine."Document Date" := SalesHeader."Document Date";
        ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::Purchase;
        ItemJnlLine."Document No." := PurchOrderHeader."Receiving No.";
        ItemJnlLine."External Document No." := PurchOrderHeader."No.";
        ItemJnlLine."Document Type" := ItemJnlLine."Document Type"::"Purchase Receipt";
        ItemJnlLine."Document Line No." := PurchOrderLine."Line No.";
        ItemJnlLine.Quantity := QtyToBeShipped;
        ItemJnlLine."Quantity (Base)" := QtyToBeShippedBase;
        ItemJnlLine."Invoiced Quantity" := 0;
        ItemJnlLine."Invoiced Qty. (Base)" := 0;
        ItemJnlLine."Unit Cost" := PurchOrderLine."Unit Cost (LCY)";
        ItemJnlLine."Source Currency Code" := SalesHeader."Currency Code";
        ItemJnlLine."Unit Cost (ACY)" := PurchOrderLine."Unit Cost";
        ItemJnlLine."Source Type" := ItemJnlLine."Source Type"::Vendor;
        ItemJnlLine."Source No." := PurchOrderLine."Buy-from Vendor No.";
        ItemJnlLine."Invoice-to Source No." := PurchOrderLine."Pay-to Vendor No.";
        ItemJnlLine."Source Code" := SrcCode;
        ItemJnlLine."Variant Code" := PurchOrderLine."Variant Code";
        ItemJnlLine."Item Category Code" := PurchOrderLine."Item Category Code";
        ItemJnlLine."Product Group Code" := PurchOrderLine."Product Group Code";
        ItemJnlLine."Bin Code" := PurchOrderLine."Bin Code";
        ItemJnlLine."Purchasing Code" := PurchOrderLine."Purchasing Code";
        ItemJnlLine."Prod. Order No." := PurchOrderLine."Prod. Order No.";
        ItemJnlLine."Unit of Measure Code" := PurchOrderLine."Unit of Measure Code";
        ItemJnlLine."Qty. per Unit of Measure" := PurchOrderLine."Qty. per Unit of Measure";
        ItemJnlLine."Applies-to Entry" := 0;
        ItemJnlLine.Division := PurchOrderLine.Division;  //LS

        IF PurchOrderLine."Job No." = '' THEN BEGIN
            TransferReservFromPurchLine(PurchOrderLine, ItemJnlLine, QtyToBeShippedBase);
            //LS -
            IF SalesHeader."Only Two Dimensions" THEN BEGIN
                TempDocDim2.DELETEALL;
                TempDocDim2.INIT;
                TempDocDim2."Table ID" := DATABASE::"Purchase Line";
                TempDocDim2."Document Type" := PurchOrderLine."Document Type";
                TempDocDim2."Document No." := PurchOrderLine."Document No.";
                TempDocDim2."Line No." := PurchOrderLine."Line No.";
                TempDocDim2."Dimension Code" := GLSetup."Global Dimension 1 Code";
                TempDocDim2."Dimension Value Code" := PurchOrderLine."Shortcut Dimension 1 Code";
                IF TempDocDim2."Dimension Value Code" <> '' THEN
                    TempDocDim2.INSERT;
                TempDocDim2."Dimension Code" := GLSetup."Global Dimension 2 Code";
                TempDocDim2."Dimension Value Code" := PurchOrderLine."Shortcut Dimension 2 Code";
                IF TempDocDim2."Dimension Value Code" <> '' THEN
                    TempDocDim2.INSERT;
            END ELSE BEGIN
                //LS +
                DocDim.RESET;
                DocDim.SETRANGE("Table ID", DATABASE::"Purchase Line");
                DocDim.SETRANGE("Document Type", PurchOrderLine."Document Type");
                DocDim.SETRANGE("Document No.", PurchOrderLine."Document No.");
                DocDim.SETRANGE("Line No.", PurchOrderLine."Line No.");
                IF DocDim.FINDSET THEN
                    REPEAT
                        TempDocDim2.INIT;
                        TempDocDim2 := DocDim;
                        TempDocDim2.INSERT;
                    UNTIL DocDim.NEXT = 0;
            END;  //LS
            TempJnlLineDim.DELETEALL;
            DimMgt.CopyDocDimToJnlLineDim(TempDocDim2, TempJnlLineDim);
            ItemJnlPostLine.RunWithCheck(ItemJnlLine, TempJnlLineDim);
            // Handle Item Tracking
            IF ItemJnlPostLine.CollectTrackingSpecification(TempHandlingSpecification2) THEN BEGIN
                IF TempHandlingSpecification2.FINDSET THEN
                    REPEAT
                        TempTrackingSpecification := TempHandlingSpecification2;
                        TempTrackingSpecification."Source Type" := DATABASE::"Purchase Line";
                        TempTrackingSpecification."Source Subtype" := PurchOrderLine."Document Type";
                        TempTrackingSpecification."Source ID" := PurchOrderLine."Document No.";
                        TempTrackingSpecification."Source Batch Name" := '';
                        TempTrackingSpecification."Source Prod. Order Line" := 0;
                        TempTrackingSpecification."Source Ref. No." := PurchOrderLine."Line No.";
                        IF TempTrackingSpecification.INSERT THEN;
                        ItemEntryRelation.INIT;
                        ItemEntryRelation."Item Entry No." := TempHandlingSpecification2."Entry No.";
                        ItemEntryRelation."Serial No." := TempHandlingSpecification2."Serial No.";
                        ItemEntryRelation."Lot No." := TempHandlingSpecification2."Lot No.";
                        ItemEntryRelation."Source Type" := DATABASE::"Purch. Rcpt. Line";
                        ItemEntryRelation."Source ID" := PurchOrderHeader."Receiving No.";
                        ItemEntryRelation."Source Ref. No." := PurchOrderLine."Line No.";
                        ItemEntryRelation."Order No." := PurchOrderLine."Document No.";
                        ItemEntryRelation."Order Line No." := PurchOrderLine."Line No.";
                        ItemEntryRelation.INSERT;
                    UNTIL TempHandlingSpecification2.NEXT = 0;
                EXIT(0);
            END;
        END;

        EXIT(ItemJnlLine."Item Shpt. Entry No.");
    end;

    local procedure UpdateAssocOrder()
    var
        ReservePurchLine: Codeunit "99000834";
    begin
        DropShipPostBuffer.RESET;
        IF DropShipPostBuffer.ISEMPTY THEN
            EXIT;
        CLEAR(PurchOrderHeader);
        DropShipPostBuffer.FINDSET;
        REPEAT
            IF PurchOrderHeader."No." <> DropShipPostBuffer."Order No." THEN BEGIN
                PurchOrderHeader.GET(
                  PurchOrderHeader."Document Type"::Order,
                  DropShipPostBuffer."Order No.");
                PurchOrderHeader."Last Receiving No." := PurchOrderHeader."Receiving No.";
                PurchOrderHeader."Receiving No." := '';
                PurchOrderHeader.MODIFY;
                ReservePurchLine.UpdateItemTrackingAfterPosting(PurchOrderHeader);
            END;
            PurchOrderLine.GET(
              PurchOrderLine."Document Type"::Order,
              DropShipPostBuffer."Order No.", DropShipPostBuffer."Order Line No.");
            PurchOrderLine."Quantity Received" := PurchOrderLine."Quantity Received" + DropShipPostBuffer.Quantity;
            PurchOrderLine."Qty. Received (Base)" := PurchOrderLine."Qty. Received (Base)" + DropShipPostBuffer."Quantity (Base)";
            PurchOrderLine.InitOutstanding;
            PurchOrderLine.InitQtyToReceive;
            PurchOrderLine.MODIFY;
        UNTIL DropShipPostBuffer.NEXT = 0;
        DropShipPostBuffer.DELETEALL;
    end;

    local procedure UpdateAssocLines(var SalesOrderLine: Record "Sales Line")
    begin
        PurchOrderLine.GET(
          PurchOrderLine."Document Type"::Order,
          SalesOrderLine."Purchase Order No.", SalesOrderLine."Purch. Order Line No.");
        PurchOrderLine."Sales Order No." := '';
        PurchOrderLine."Sales Order Line No." := 0;
        PurchOrderLine.MODIFY;
        SalesOrderLine."Purchase Order No." := '';
        SalesOrderLine."Purch. Order Line No." := 0;
    end;

    local procedure FillInvPostingBuffer(SalesLine: Record "Sales Line"; SalesLineACY: Record "Sales Line")
    var
        TotalVAT: Decimal;
        TotalVATACY: Decimal;
        TotalAmount: Decimal;
        TotalAmountACY: Decimal;
    begin
        IF (SalesLine."Gen. Bus. Posting Group" <> GenPostingSetup."Gen. Bus. Posting Group") OR
           (SalesLine."Gen. Prod. Posting Group" <> GenPostingSetup."Gen. Prod. Posting Group")
        THEN
            GenPostingSetup.GET(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");

        InvPostingBuffer[1].PrepareSales(SalesLine);

        TempDocDim.SETRANGE("Table ID", DATABASE::"Sales Line");
        TempDocDim.SETRANGE("Line No.", SalesLine."Line No.");
        TotalVAT := SalesLine."Amount Including VAT" - SalesLine.Amount;
        TotalVATACY := SalesLineACY."Amount Including VAT" - SalesLineACY.Amount;
        TotalAmount := SalesLine.Amount;
        TotalAmountACY := SalesLineACY.Amount;

        IF SalesSetup."Discount Posting" IN
          [SalesSetup."Discount Posting"::"Invoice Discounts", SalesSetup."Discount Posting"::"All Discounts"] THEN BEGIN
            IF SalesLine."VAT Calculation Type" = SalesLine."VAT Calculation Type"::"Reverse Charge VAT" THEN
                InvPostingBuffer[1].CalcDiscountNoVAT(
                  -SalesLine."Inv. Discount Amount",
                  -SalesLineACY."Inv. Discount Amount")
            ELSE
                InvPostingBuffer[1].CalcDiscount(
                  SalesHeader."Prices Including VAT",
                  -SalesLine."Inv. Discount Amount",
                  -SalesLineACY."Inv. Discount Amount");
            IF (InvPostingBuffer[1].Amount <> 0) OR
               (InvPostingBuffer[1]."Amount (ACY)" <> 0)
            THEN BEGIN
                GenPostingSetup.TESTFIELD("Sales Inv. Disc. Account");
                InvPostingBuffer[1].SetAccount(
                  GenPostingSetup."Sales Inv. Disc. Account",
                  TotalVAT,
                  TotalVATACY,
                  TotalAmount,
                  TotalAmountACY);
                UpdInvPostingBuffer;
            END;
        END;

        IF SalesSetup."Discount Posting" IN
          [SalesSetup."Discount Posting"::"Line Discounts", SalesSetup."Discount Posting"::"All Discounts"] THEN BEGIN
            IF SalesLine."VAT Calculation Type" = SalesLine."VAT Calculation Type"::"Reverse Charge VAT" THEN
                InvPostingBuffer[1].CalcDiscountNoVAT(
                  -SalesLine."Line Discount Amount",
                  -SalesLineACY."Line Discount Amount")
            ELSE
                InvPostingBuffer[1].CalcDiscount(
                  SalesHeader."Prices Including VAT",
                  -SalesLine."Line Discount Amount",
                  -SalesLineACY."Line Discount Amount");
            IF (InvPostingBuffer[1].Amount <> 0) OR
               (InvPostingBuffer[1]."Amount (ACY)" <> 0)
            THEN BEGIN
                GenPostingSetup.TESTFIELD("Sales Line Disc. Account");
                InvPostingBuffer[1].SetAccount(
                  GenPostingSetup."Sales Line Disc. Account",
                  TotalVAT,
                  TotalVATACY,
                  TotalAmount,
                  TotalAmountACY);
                UpdInvPostingBuffer;
            END;
        END;

        InvPostingBuffer[1].SetAmounts(
          TotalVAT,
          TotalVATACY,
          TotalAmount,
          TotalAmountACY,
          SalesLine."VAT Difference");

        IF (SalesLine.Type = SalesLine.Type::"G/L Account") OR (SalesLine.Type = SalesLine.Type::"Fixed Asset") THEN
            InvPostingBuffer[1].SetAccount(
              SalesLine."No.",
              TotalVAT,
              TotalVATACY,
              TotalAmount,
              TotalAmountACY)
        ELSE
            IF SalesLine."Document Type" IN [SalesLine."Document Type"::"Return Order", SalesLine."Document Type"::"Credit Memo"] THEN BEGIN
                GenPostingSetup.TESTFIELD("Sales Credit Memo Account");
                InvPostingBuffer[1].SetAccount(
                  GenPostingSetup."Sales Credit Memo Account",
                  TotalVAT,
                  TotalVATACY,
                  TotalAmount,
                  TotalAmountACY);
            END ELSE BEGIN
                GenPostingSetup.TESTFIELD("Sales Account");
                InvPostingBuffer[1].SetAccount(
                  GenPostingSetup."Sales Account",
                  TotalVAT,
                  TotalVATACY,
                  TotalAmount,
                  TotalAmountACY);
            END;
        UpdInvPostingBuffer;
    end;

    local procedure UpdInvPostingBuffer()
    var
        TempDimBuf: Record "Dimension Buffer" temporary;
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
            InvPostingBuffer[2].Amount := InvPostingBuffer[2].Amount + InvPostingBuffer[1].Amount;
            InvPostingBuffer[2]."VAT Amount" :=
              InvPostingBuffer[2]."VAT Amount" + InvPostingBuffer[1]."VAT Amount";
            InvPostingBuffer[2]."VAT Base Amount" :=
              InvPostingBuffer[2]."VAT Base Amount" + InvPostingBuffer[1]."VAT Base Amount";
            InvPostingBuffer[2]."Amount (ACY)" :=
              InvPostingBuffer[2]."Amount (ACY)" + InvPostingBuffer[1]."Amount (ACY)";
            InvPostingBuffer[2]."VAT Amount (ACY)" :=
              InvPostingBuffer[2]."VAT Amount (ACY)" + InvPostingBuffer[1]."VAT Amount (ACY)";
            InvPostingBuffer[2]."VAT Difference" :=
              InvPostingBuffer[2]."VAT Difference" + InvPostingBuffer[1]."VAT Difference";
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
        WITH SalesHeader DO
            IF "Currency Code" = '' THEN
                Currency.InitRoundingPrecision
            ELSE BEGIN
                Currency.GET("Currency Code");
                Currency.TESTFIELD("Amount Rounding Precision");
            END;
    end;

    local procedure DivideAmount(QtyType: Option General,Invoicing,Shipping; SalesLineQty: Decimal)
    begin
        IF RoundingLineInserted AND (RoundingLineNo = SalesLine."Line No.") THEN
            EXIT;
        WITH SalesLine DO
            IF (SalesLineQty = 0) OR ("Unit Price" = 0) OR ("Line Discount %" = 100) THEN BEGIN
                "Line Amount" := 0;
                "Line Discount Amount" := 0;
                "Inv. Discount Amount" := 0;
                "VAT Base Amount" := 0;
                Amount := 0;
                "Amount Including VAT" := 0;
            END ELSE BEGIN
                TempVATAmountLine.GET("VAT Identifier", "VAT Calculation Type", "Tax Group Code", FALSE, "Line Amount" >= 0);
                IF "VAT Calculation Type" = "VAT Calculation Type"::"Sales Tax" THEN
                    "VAT %" := TempVATAmountLine."VAT %";
                TempVATAmountLineRemainder := TempVATAmountLine;
                IF NOT TempVATAmountLineRemainder.FIND THEN BEGIN
                    TempVATAmountLineRemainder.INIT;
                    TempVATAmountLineRemainder.INSERT;
                END;
                "Line Amount" := ROUND(SalesLineQty * "Unit Price", Currency."Amount Rounding Precision");
                IF SalesLineQty <> Quantity THEN
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

                IF SalesHeader."Prices Including VAT" THEN BEGIN
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
                        Amount * (1 - SalesHeader."VAT Base Discount %" / 100), Currency."Amount Rounding Precision");
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
                            Amount * (1 - SalesHeader."VAT Base Discount %" / 100), Currency."Amount Rounding Precision");
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

    local procedure RoundAmount(SalesLineQty: Decimal)
    var
        NoVAT: Boolean;
    begin
        WITH SalesLine DO BEGIN
            IncrAmount(TotalSalesLine);
            Increment(TotalSalesLine."Net Weight", ROUND(SalesLineQty * "Net Weight", 0.00001));
            Increment(TotalSalesLine."Gross Weight", ROUND(SalesLineQty * "Gross Weight", 0.00001));
            Increment(TotalSalesLine."Unit Volume", ROUND(SalesLineQty * "Unit Volume", 0.00001));
            Increment(TotalSalesLine.Quantity, SalesLineQty);
            IF "Units per Parcel" > 0 THEN
                Increment(
                  TotalSalesLine."Units per Parcel",
                  ROUND(SalesLineQty / "Units per Parcel", 1, '>'));

            TempSalesLine := SalesLine;
            SalesLineACY := SalesLine;

            IF SalesHeader."Currency Code" <> '' THEN BEGIN
                IF ("Document Type" IN ["Document Type"::"Blanket Order", "Document Type"::Quote]) AND
                   (SalesHeader."Posting Date" = 0D)
                THEN
                    UseDate := WORKDATE
                ELSE
                    UseDate := SalesHeader."Posting Date";

                NoVAT := Amount = "Amount Including VAT";
                "Amount Including VAT" :=
                  ROUND(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      UseDate, SalesHeader."Currency Code",
                      TotalSalesLine."Amount Including VAT", SalesHeader."Currency Factor")) -
                        TotalSalesLineLCY."Amount Including VAT";
                IF NoVAT THEN
                    Amount := "Amount Including VAT"
                ELSE
                    Amount :=
                      ROUND(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                          UseDate, SalesHeader."Currency Code",
                          TotalSalesLine.Amount, SalesHeader."Currency Factor")) -
                            TotalSalesLineLCY.Amount;
                "Line Amount" :=
                  ROUND(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      UseDate, SalesHeader."Currency Code",
                      TotalSalesLine."Line Amount", SalesHeader."Currency Factor")) -
                        TotalSalesLineLCY."Line Amount";
                "Line Discount Amount" :=
                  ROUND(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      UseDate, SalesHeader."Currency Code",
                      TotalSalesLine."Line Discount Amount", SalesHeader."Currency Factor")) -
                        TotalSalesLineLCY."Line Discount Amount";
                "Inv. Discount Amount" :=
                  ROUND(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      UseDate, SalesHeader."Currency Code",
                      TotalSalesLine."Inv. Discount Amount", SalesHeader."Currency Factor")) -
                        TotalSalesLineLCY."Inv. Discount Amount";
                "VAT Difference" :=
                  ROUND(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      UseDate, SalesHeader."Currency Code",
                      TotalSalesLine."VAT Difference", SalesHeader."Currency Factor")) -
                        TotalSalesLineLCY."VAT Difference";
            END;

            IncrAmount(TotalSalesLineLCY);
            Increment(TotalSalesLineLCY."Unit Cost (LCY)", ROUND(SalesLineQty * "Unit Cost (LCY)"));
        END;
    end;

    local procedure ReverseAmount(var SalesLine: Record "Sales Line")
    begin
        WITH SalesLine DO BEGIN
            "Qty. to Ship" := -"Qty. to Ship";
            "Qty. to Ship (Base)" := -"Qty. to Ship (Base)";
            "Return Qty. to Receive" := -"Return Qty. to Receive";
            "Return Qty. to Receive (Base)" := -"Return Qty. to Receive (Base)";
            "Qty. to Invoice" := -"Qty. to Invoice";
            "Qty. to Invoice (Base)" := -"Qty. to Invoice (Base)";
            "Line Amount" := -"Line Amount";
            Amount := -Amount;
            "VAT Base Amount" := -"VAT Base Amount";
            "VAT Difference" := -"VAT Difference";
            "Amount Including VAT" := -"Amount Including VAT";
            "Line Discount Amount" := -"Line Discount Amount";
            "Inv. Discount Amount" := -"Inv. Discount Amount";
        END;
    end;

    local procedure InvoiceRounding(UseTempData: Boolean)
    var
        DocDim2: Record "Document Dimension";
        InvoiceRoundingAmount: Decimal;
        NextLineNo: Integer;
        TempDocDim2: Record "Document Dimension" temporary;
    begin
        Currency.TESTFIELD("Invoice Rounding Precision");
        InvoiceRoundingAmount :=
          -ROUND(
            TotalSalesLine."Amount Including VAT" -
            ROUND(
              TotalSalesLine."Amount Including VAT",
              Currency."Invoice Rounding Precision",
              Currency.InvoiceRoundingDirection),
            Currency."Amount Rounding Precision");
        IF InvoiceRoundingAmount <> 0 THEN BEGIN
            CustPostingGr.GET(SalesHeader."Customer Posting Group");
            CustPostingGr.TESTFIELD("Invoice Rounding Account");
            WITH SalesLine DO BEGIN
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
                VALIDATE("No.", CustPostingGr."Invoice Rounding Account");
                VALIDATE(Quantity, 1);
                IF "Document Type" IN ["Document Type"::"Return Order", SalesLine."Document Type"::"Credit Memo"] THEN
                    VALIDATE(SalesLine."Return Qty. to Receive", Quantity)
                ELSE
                    VALIDATE("Qty. to Ship", Quantity);
                IF SalesHeader."Prices Including VAT" THEN
                    VALIDATE("Unit Price", InvoiceRoundingAmount)
                ELSE
                    VALIDATE(
                      "Unit Price",
                      ROUND(
                        InvoiceRoundingAmount /
                        (1 + (1 - SalesHeader."VAT Base Discount %" / 100) * "VAT %" / 100),
                        Currency."Amount Rounding Precision"));
                VALIDATE("Amount Including VAT", InvoiceRoundingAmount);
                "Line No." := NextLineNo;
                IF NOT UseTempData THEN BEGIN
                    //LS -
                    IF SalesHeader."Only Two Dimensions" THEN BEGIN
                        TempDocDim2.RESET;
                        TempDocDim2.DELETEALL;
                        TempDocDim.SETRANGE(TempDocDim."Table ID", DATABASE::"Sales Header");
                        TempDocDim.SETRANGE(TempDocDim."Line No.", 0);
                        IF TempDocDim.FIND('-') THEN
                            REPEAT
                                TempDocDim2 := TempDocDim;
                                TempDocDim2.INSERT;
                            UNTIL TempDocDim.NEXT = 0;
                        IF TempDocDim2.FIND('-') THEN
                            REPEAT
                                TempDocDim := TempDocDim2;
                                TempDocDim."Table ID" := DATABASE::"Sales Line";
                                TempDocDim."Line No." := "Line No.";
                                TempDocDim.INSERT;
                            UNTIL TempDocDim2.NEXT = 0;
                    END ELSE BEGIN
                        //LS+
                        DocDim2.SETRANGE("Table ID", DATABASE::"Sales Line");
                        DocDim2.SETRANGE("Document Type", SalesHeader."Document Type");
                        DocDim2.SETRANGE("Document No.", SalesHeader."No.");
                        DocDim2.SETRANGE("Line No.", "Line No.");
                        IF DocDim2.FINDSET THEN
                            REPEAT
                                TempDocDim := DocDim2;
                                TempDocDim.INSERT;
                            UNTIL DocDim2.NEXT = 0;
                    END;  //LS
                END;
                LastLineRetrieved := FALSE;
                RoundingLineInserted := TRUE;
                RoundingLineNo := "Line No.";
            END;
        END;
    end;

    local procedure IncrAmount(var TotalSalesLine: Record "Sales Line")
    begin
        WITH SalesLine DO BEGIN
            IF SalesHeader."Prices Including VAT" OR
               ("VAT Calculation Type" <> "VAT Calculation Type"::"Full VAT")
            THEN
                Increment(TotalSalesLine."Line Amount", "Line Amount");
            Increment(TotalSalesLine.Amount, Amount);
            Increment(TotalSalesLine."VAT Base Amount", "VAT Base Amount");
            Increment(TotalSalesLine."VAT Difference", "VAT Difference");
            Increment(TotalSalesLine."Amount Including VAT", "Amount Including VAT");
            Increment(TotalSalesLine."Line Discount Amount", "Line Discount Amount");
            Increment(TotalSalesLine."Inv. Discount Amount", "Inv. Discount Amount");
            Increment(TotalSalesLine."Inv. Disc. Amount to Invoice", "Inv. Disc. Amount to Invoice");
            Increment(TotalSalesLine."Prepmt. Line Amount", "Prepmt. Line Amount");
            Increment(TotalSalesLine."Prepmt. Amt. Inv.", "Prepmt. Amt. Inv.");
            Increment(TotalSalesLine."Prepmt Amt to Deduct", "Prepmt Amt to Deduct");
            Increment(TotalSalesLine."Prepmt Amt Deducted", "Prepmt Amt Deducted");
            Increment(TotalSalesLine."Prepayment VAT Difference", "Prepayment VAT Difference");
            Increment(TotalSalesLine."Prepmt VAT Diff. to Deduct", "Prepmt VAT Diff. to Deduct");
            Increment(TotalSalesLine."Prepmt VAT Diff. Deducted", "Prepmt VAT Diff. Deducted");
        END;
    end;

    local procedure Increment(var Number: Decimal; Number2: Decimal)
    begin
        Number := Number + Number2;
    end;

    procedure GetSalesLines(var NewSalesHeader: Record "Sales Header"; var NewSalesLine: Record "Sales Line"; QtyType: Option General,Invoicing,Shipping)
    var
        OldSalesLine: Record "Sales Line";
        MergedSalesLines: Record "Sales Line" temporary;
        TotalAdjCostLCY: Decimal;
    begin
        SalesHeader := NewSalesHeader;
        IF QtyType = QtyType::Invoicing THEN BEGIN
            CreatePrepaymentLines(SalesHeader, TempPrepaymentSalesLine, PrepmtDocDim, FALSE);
            MergeSaleslines(SalesHeader, OldSalesLine, TempPrepaymentSalesLine, MergedSalesLines);
            SumSalesLines2(NewSalesLine, MergedSalesLines, QtyType, TRUE, FALSE, TotalAdjCostLCY);
        END ELSE
            SumSalesLines2(NewSalesLine, OldSalesLine, QtyType, TRUE, FALSE, TotalAdjCostLCY);
    end;

    procedure GetSalesLinesTemp(var NewSalesHeader: Record "Sales Header"; var NewSalesLine: Record "Sales Line"; var OldSalesLine: Record "Sales Line"; QtyType: Option General,Invoicing,Shipping)
    var
        TotalAdjCostLCY: Decimal;
    begin
        SalesHeader := NewSalesHeader;
        OldSalesLine.SetSalesHeader(NewSalesHeader);
        SumSalesLines2(NewSalesLine, OldSalesLine, QtyType, TRUE, FALSE, TotalAdjCostLCY);
    end;

    procedure SumSalesLines(var NewSalesHeader: Record "Sales Header"; QtyType: Option General,Invoicing,Shipping; var NewTotalSalesLine: Record "Sales Line"; var NewTotalSalesLineLCY: Record "Sales Line"; var VATAmount: Decimal; var VATAmountText: Text[30]; var ProfitLCY: Decimal; var ProfitPct: Decimal; var TotalAdjCostLCY: Decimal)
    var
        OldSalesLine: Record "Sales Line";
    begin
        SumSalesLinesTemp(
          NewSalesHeader, OldSalesLine, QtyType, NewTotalSalesLine, NewTotalSalesLineLCY,
          VATAmount, VATAmountText, ProfitLCY, ProfitPct, TotalAdjCostLCY);
    end;

    procedure SumSalesLinesTemp(var NewSalesHeader: Record "Sales Header"; var OldSalesLine: Record "Sales Line"; QtyType: Option General,Invoicing,Shipping; var NewTotalSalesLine: Record "Sales Line"; var NewTotalSalesLineLCY: Record "Sales Line"; var VATAmount: Decimal; var VATAmountText: Text[30]; var ProfitLCY: Decimal; var ProfitPct: Decimal; var TotalAdjCostLCY: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        WITH SalesHeader DO BEGIN
            SalesHeader := NewSalesHeader;
            SumSalesLines2(SalesLine, OldSalesLine, QtyType, FALSE, TRUE, TotalAdjCostLCY);
            ProfitLCY := TotalSalesLineLCY.Amount - TotalSalesLineLCY."Unit Cost (LCY)";
            IF TotalSalesLineLCY.Amount = 0 THEN
                ProfitPct := 0
            ELSE
                ProfitPct := ROUND(ProfitLCY / TotalSalesLineLCY.Amount * 100, 0.1);
            VATAmount := TotalSalesLine."Amount Including VAT" - TotalSalesLine.Amount;
            IF TotalSalesLine."VAT %" = 0 THEN
                VATAmountText := Text016
            ELSE
                VATAmountText := STRSUBSTNO(Text017, TotalSalesLine."VAT %");
            NewTotalSalesLine := TotalSalesLine;
            NewTotalSalesLineLCY := TotalSalesLineLCY;
        END;
    end;

    local procedure SumSalesLines2(var NewSalesLine: Record "Sales Line"; var OldSalesLine: Record "Sales Line"; QtyType: Option General,Invoicing,Shipping; InsertSalesLine: Boolean; CalcAdCostLCY: Boolean; var TotalAdjCostLCY: Decimal)
    var
        SalesLineQty: Decimal;
        AdjCostLCY: Decimal;
    begin
        TotalAdjCostLCY := 0;
        TempVATAmountLineRemainder.DELETEALL;
        OldSalesLine.CalcVATAmountLines(QtyType, SalesHeader, OldSalesLine, TempVATAmountLine);
        WITH SalesHeader DO BEGIN
            GLSetup.GET;
            SalesSetup.GET;
            GetCurrency;
            OldSalesLine.SETRANGE("Document Type", "Document Type");
            OldSalesLine.SETRANGE("Document No.", "No.");
            RoundingLineInserted := FALSE;
            IF OldSalesLine.FINDSET THEN
                REPEAT
                    IF NOT RoundingLineInserted THEN
                        SalesLine := OldSalesLine;
                    CASE QtyType OF
                        QtyType::General:
                            SalesLineQty := SalesLine.Quantity;
                        QtyType::Invoicing:
                            SalesLineQty := SalesLine."Qty. to Invoice";
                        QtyType::Shipping:
                            BEGIN
                                IF "Document Type" IN ["Document Type"::"Return Order", "Document Type"::"Credit Memo"] THEN
                                    SalesLineQty := SalesLine."Return Qty. to Receive"
                                ELSE
                                    SalesLineQty := SalesLine."Qty. to Ship";
                            END;
                    END;
                    DivideAmount(QtyType, SalesLineQty);
                    SalesLine.Quantity := SalesLineQty;
                    IF SalesLineQty <> 0 THEN BEGIN
                        IF (SalesLine.Amount <> 0) AND NOT RoundingLineInserted THEN
                            IF TotalSalesLine.Amount = 0 THEN
                                TotalSalesLine."VAT %" := SalesLine."VAT %"
                            ELSE
                                IF TotalSalesLine."VAT %" <> SalesLine."VAT %" THEN
                                    TotalSalesLine."VAT %" := 0;
                        RoundAmount(SalesLineQty);

                        IF (QtyType IN [QtyType::General, QtyType::Invoicing]) AND
                           NOT InsertSalesLine AND CalcAdCostLCY
                        THEN BEGIN
                            AdjCostLCY := CostCalcMgt.CalcSalesLineCostLCY(SalesLine, QtyType);
                            TotalAdjCostLCY := TotalAdjCostLCY + GetSalesLineAdjCostLCY(SalesLine, QtyType, AdjCostLCY);
                        END;

                        SalesLine := TempSalesLine;
                    END;
                    IF InsertSalesLine THEN BEGIN
                        NewSalesLine := SalesLine;
                        NewSalesLine.INSERT;
                    END;
                    IF RoundingLineInserted THEN
                        LastLineRetrieved := TRUE
                    ELSE BEGIN
                        LastLineRetrieved := OldSalesLine.NEXT = 0;
                        IF LastLineRetrieved AND SalesSetup."Invoice Rounding" THEN
                            InvoiceRounding(TRUE);
                    END;
                UNTIL LastLineRetrieved;
        END;
    end;

    local procedure GetSalesLineAdjCostLCY(SalesLine2: Record "Sales Line"; QtyType: Option General,Invoicing,Shipping; AdjCostLCY: Decimal): Decimal
    begin
        WITH SalesLine2 DO BEGIN
            IF "Document Type" IN ["Document Type"::Order, "Document Type"::Invoice] THEN
                AdjCostLCY := -AdjCostLCY;

            CASE TRUE OF
                "Shipment No." <> '', "Return Receipt No." <> '':
                    EXIT(AdjCostLCY);
                QtyType = QtyType::General:
                    EXIT(ROUND("Outstanding Quantity" * "Unit Cost (LCY)") + AdjCostLCY);
                "Document Type" IN ["Document Type"::Order, "Document Type"::Invoice]:
                    BEGIN
                        IF "Qty. to Invoice" > "Qty. to Ship" THEN
                            EXIT(ROUND("Qty. to Ship" * "Unit Cost (LCY)") + AdjCostLCY);
                        EXIT(ROUND("Qty. to Invoice" * "Unit Cost (LCY)"));
                    END;
                "Document Type" IN ["Document Type"::"Return Order", "Document Type"::"Credit Memo"]:
                    BEGIN
                        IF "Qty. to Invoice" > "Return Qty. to Receive" THEN
                            EXIT(ROUND("Return Qty. to Receive" * "Unit Cost (LCY)") + AdjCostLCY);
                        EXIT(ROUND("Qty. to Invoice" * "Unit Cost (LCY)"));
                    END;
            END;
        END;
    end;

    procedure TestDeleteHeader(SalesHeader: Record "Sales Header"; var SalesShptHeader: Record "Sales Shipment Header"; var SalesInvHeader: Record "Sales Invoice Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var ReturnRcptHeader: Record "Return Receipt Header"; var SalesInvHeaderPrePmt: Record "Sales Invoice Header"; var SalesCrMemoHeaderPrePmt: Record "Sales Cr.Memo Header")
    begin
        WITH SalesHeader DO BEGIN
            CLEAR(SalesShptHeader);
            CLEAR(SalesInvHeader);
            CLEAR(SalesCrMemoHeader);
            CLEAR(ReturnRcptHeader);
            SalesSetup.GET;

            SourceCodeSetup.GET;
            SourceCodeSetup.TESTFIELD("Deleted Document");
            SourceCode.GET(SourceCodeSetup."Deleted Document");

            IF ("Shipping No. Series" <> '') AND ("Shipping No." <> '') THEN BEGIN
                SalesShptHeader.TRANSFERFIELDS(SalesHeader);
                SalesShptHeader."No." := "Shipping No.";
                SalesShptHeader."Posting Date" := TODAY;
                SalesShptHeader."User ID" := USERID;
                SalesShptHeader."Source Code" := SourceCode.Code;
            END;

            IF ("Return Receipt No. Series" <> '') AND ("Return Receipt No." <> '') THEN BEGIN
                ReturnRcptHeader.TRANSFERFIELDS(SalesHeader);
                ReturnRcptHeader."No." := "Return Receipt No.";
                ReturnRcptHeader."Posting Date" := TODAY;
                ReturnRcptHeader."User ID" := USERID;
                ReturnRcptHeader."Source Code" := SourceCode.Code;
            END;

            IF ("Posting No. Series" <> '') AND
               (("Document Type" IN ["Document Type"::Order, "Document Type"::Invoice]) AND
                ("Posting No." <> '') OR
                ("Document Type" = "Document Type"::Invoice) AND
                ("No. Series" = "Posting No. Series"))
            THEN BEGIN
                SalesInvHeader.TRANSFERFIELDS(SalesHeader);
                IF "Posting No." <> '' THEN
                    SalesInvHeader."No." := "Posting No.";
                IF "Document Type" = "Document Type"::Invoice THEN BEGIN
                    SalesInvHeader."Pre-Assigned No. Series" := "No. Series";
                    SalesInvHeader."Pre-Assigned No." := "No.";
                END ELSE BEGIN
                    SalesInvHeader."Pre-Assigned No. Series" := '';
                    SalesInvHeader."Pre-Assigned No." := '';
                    SalesInvHeader."Order No. Series" := "No. Series";
                    SalesInvHeader."Order No." := "No.";
                END;
                SalesInvHeader."Posting Date" := TODAY;
                SalesInvHeader."User ID" := USERID;
                SalesInvHeader."Source Code" := SourceCode.Code;
            END;

            IF ("Posting No. Series" <> '') AND
               (("Document Type" IN ["Document Type"::"Return Order", "Document Type"::"Credit Memo"]) AND
                ("Posting No." <> '') OR
                ("Document Type" = "Document Type"::"Credit Memo") AND
                ("No. Series" = "Posting No. Series"))
            THEN BEGIN
                SalesCrMemoHeader.TRANSFERFIELDS(SalesHeader);
                IF "Posting No." <> '' THEN
                    SalesCrMemoHeader."No." := "Posting No.";
                SalesCrMemoHeader."Pre-Assigned No. Series" := "No. Series";
                SalesCrMemoHeader."Pre-Assigned No." := "No.";
                SalesCrMemoHeader."Posting Date" := TODAY;
                SalesCrMemoHeader."User ID" := USERID;
                SalesCrMemoHeader."Source Code" := SourceCode.Code;
            END;
            IF ("Prepayment No. Series" <> '') AND ("Prepayment No." <> '') THEN BEGIN
                TESTFIELD("Document Type", "Document Type"::Order);
                SalesInvHeaderPrePmt.TRANSFERFIELDS(SalesHeader);
                SalesInvHeaderPrePmt."No." := "Prepayment No.";
                SalesInvHeaderPrePmt."Order No. Series" := "No. Series";
                SalesInvHeaderPrePmt."Prepayment Order No." := "No.";
                SalesInvHeaderPrePmt."Posting Date" := TODAY;
                SalesInvHeaderPrePmt."Pre-Assigned No. Series" := '';
                SalesInvHeaderPrePmt."Pre-Assigned No." := '';
                SalesInvHeaderPrePmt."User ID" := USERID;
                SalesInvHeaderPrePmt."Source Code" := SourceCode.Code;
                SalesInvHeaderPrePmt."Prepayment Invoice" := TRUE;
            END;

            IF ("Prepmt. Cr. Memo No. Series" <> '') AND ("Prepmt. Cr. Memo No." <> '') THEN BEGIN
                TESTFIELD("Document Type", "Document Type"::Order);
                SalesCrMemoHeaderPrePmt.TRANSFERFIELDS(SalesHeader);
                SalesCrMemoHeaderPrePmt."No." := "Prepmt. Cr. Memo No.";
                SalesCrMemoHeaderPrePmt."Prepayment Order No." := "No.";
                SalesCrMemoHeaderPrePmt."Posting Date" := TODAY;
                SalesCrMemoHeaderPrePmt."Pre-Assigned No. Series" := '';
                SalesCrMemoHeaderPrePmt."Pre-Assigned No." := '';
                SalesCrMemoHeaderPrePmt."User ID" := USERID;
                SalesCrMemoHeaderPrePmt."Source Code" := SourceCode.Code;
                SalesCrMemoHeaderPrePmt."Prepayment Credit Memo" := TRUE;
            END;
        END;
    end;

    procedure DeleteHeader(SalesHeader: Record "Sales Header"; var SalesShptHeader: Record "Sales Shipment Header"; var SalesInvHeader: Record "Sales Invoice Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var ReturnRcptHeader: Record "Return Receipt Header"; var SalesInvHeaderPrePmt: Record "Sales Invoice Header"; var SalesCrMemoHeaderPrePmt: Record "Sales Cr.Memo Header")
    begin
        WITH SalesHeader DO BEGIN
            TestDeleteHeader(
              SalesHeader, SalesShptHeader, SalesInvHeader, SalesCrMemoHeader,
              ReturnRcptHeader, SalesInvHeaderPrePmt, SalesCrMemoHeaderPrePmt);
            IF SalesShptHeader."No." <> '' THEN BEGIN
                SalesShptHeader.INSERT;
                SalesShptLine.INIT;
                SalesShptLine."Document No." := SalesShptHeader."No.";
                SalesShptLine."Line No." := 10000;
                SalesShptLine.Description := SourceCode.Description;
                SalesShptLine.INSERT;
            END;

            IF ReturnRcptHeader."No." <> '' THEN BEGIN
                ReturnRcptHeader.INSERT;
                ReturnRcptLine.INIT;
                ReturnRcptLine."Document No." := ReturnRcptHeader."No.";
                ReturnRcptLine."Line No." := 10000;
                ReturnRcptLine.Description := SourceCode.Description;
                ReturnRcptLine.INSERT;
            END;

            IF SalesInvHeader."No." <> '' THEN BEGIN
                SalesInvHeader.INSERT;
                SalesInvLine.INIT;
                SalesInvLine."Document No." := SalesInvHeader."No.";
                SalesInvLine."Line No." := 10000;
                SalesInvLine.Description := SourceCode.Description;
                SalesInvLine.INSERT;
            END;

            IF SalesCrMemoHeader."No." <> '' THEN BEGIN
                SalesCrMemoHeader.INSERT;
                SalesCrMemoLine.INIT;
                SalesCrMemoLine."Document No." := SalesCrMemoHeader."No.";
                SalesCrMemoLine."Line No." := 10000;
                SalesCrMemoLine.Description := SourceCode.Description;
                SalesCrMemoLine.INSERT;
            END;

            IF SalesInvHeaderPrePmt."No." <> '' THEN BEGIN
                SalesInvHeaderPrePmt.INSERT;
                SalesInvLine."Document No." := SalesInvHeaderPrePmt."No.";
                SalesInvLine."Line No." := 10000;
                SalesInvLine.Description := SourceCode.Description;
                SalesInvLine.INSERT;
            END;

            IF SalesCrMemoHeaderPrePmt."No." <> '' THEN BEGIN
                SalesCrMemoHeaderPrePmt.INSERT;
                SalesCrMemoLine.INIT;
                SalesCrMemoLine."Document No." := SalesCrMemoHeaderPrePmt."No.";
                SalesCrMemoLine."Line No." := 10000;
                SalesCrMemoLine.Description := SourceCode.Description;
                SalesCrMemoLine.INSERT;
            END;
        END;
    end;

    procedure UpdateBlanketOrderLine(SalesLine: Record "Sales Line"; Ship: Boolean; Receive: Boolean; Invoice: Boolean)
    var
        BlanketOrderSalesLine: Record "Sales Line";
        ModifyLine: Boolean;
        Sign: Decimal;
    begin
        IF (SalesLine."Blanket Order No." <> '') AND (SalesLine."Blanket Order Line No." <> 0) AND
           ((Ship AND (SalesLine."Qty. to Ship" <> 0)) OR
            (Receive AND (SalesLine."Return Qty. to Receive" <> 0)) OR
            (Invoice AND (SalesLine."Qty. to Invoice" <> 0)))
        THEN
            IF BlanketOrderSalesLine.GET(
                 BlanketOrderSalesLine."Document Type"::"Blanket Order", SalesLine."Blanket Order No.",
                 SalesLine."Blanket Order Line No.")
            THEN BEGIN
                BlanketOrderSalesLine.TESTFIELD(Type, SalesLine.Type);
                BlanketOrderSalesLine.TESTFIELD("No.", SalesLine."No.");
                BlanketOrderSalesLine.TESTFIELD("Sell-to Customer No.", SalesLine."Sell-to Customer No.");

                ModifyLine := FALSE;
                CASE SalesLine."Document Type" OF
                    SalesLine."Document Type"::Order,
                  SalesLine."Document Type"::Invoice:
                        Sign := 1;
                    SalesLine."Document Type"::"Return Order",
                  SalesLine."Document Type"::"Credit Memo":
                        Sign := -1;
                END;
                IF Ship AND (SalesLine."Shipment No." = '') THEN BEGIN
                    IF BlanketOrderSalesLine."Qty. per Unit of Measure" =
                       SalesLine."Qty. per Unit of Measure"
                    THEN
                        BlanketOrderSalesLine."Quantity Shipped" :=
                          BlanketOrderSalesLine."Quantity Shipped" + Sign * SalesLine."Qty. to Ship"
                    ELSE
                        BlanketOrderSalesLine."Quantity Shipped" :=
                          BlanketOrderSalesLine."Quantity Shipped" +
                          Sign *
                          ROUND(
                            (SalesLine."Qty. per Unit of Measure" /
                             BlanketOrderSalesLine."Qty. per Unit of Measure") *
                            SalesLine."Qty. to Ship", 0.00001);
                    BlanketOrderSalesLine."Qty. Shipped (Base)" :=
                      BlanketOrderSalesLine."Qty. Shipped (Base)" + Sign * SalesLine."Qty. to Ship (Base)";
                    ModifyLine := TRUE;
                END;
                IF Receive AND (SalesLine."Return Receipt No." = '') THEN BEGIN
                    IF BlanketOrderSalesLine."Qty. per Unit of Measure" =
                       SalesLine."Qty. per Unit of Measure"
                    THEN
                        BlanketOrderSalesLine."Quantity Shipped" :=
                          BlanketOrderSalesLine."Quantity Shipped" + Sign * SalesLine."Return Qty. to Receive"
                    ELSE
                        BlanketOrderSalesLine."Quantity Shipped" :=
                          BlanketOrderSalesLine."Quantity Shipped" +
                          Sign *
                          ROUND(
                            (SalesLine."Qty. per Unit of Measure" /
                             BlanketOrderSalesLine."Qty. per Unit of Measure") *
                            SalesLine."Return Qty. to Receive", 0.00001);
                    BlanketOrderSalesLine."Qty. Shipped (Base)" :=
                      BlanketOrderSalesLine."Qty. Shipped (Base)" + Sign * SalesLine."Return Qty. to Receive (Base)";
                    ModifyLine := TRUE;
                END;
                IF Invoice THEN BEGIN
                    IF BlanketOrderSalesLine."Qty. per Unit of Measure" =
                       SalesLine."Qty. per Unit of Measure"
                    THEN
                        BlanketOrderSalesLine."Quantity Invoiced" :=
                          BlanketOrderSalesLine."Quantity Invoiced" + Sign * SalesLine."Qty. to Invoice"
                    ELSE
                        BlanketOrderSalesLine."Quantity Invoiced" :=
                          BlanketOrderSalesLine."Quantity Invoiced" +
                          Sign *
                          ROUND(
                            (SalesLine."Qty. per Unit of Measure" /
                             BlanketOrderSalesLine."Qty. per Unit of Measure") *
                            SalesLine."Qty. to Invoice", 0.00001);
                    BlanketOrderSalesLine."Qty. Invoiced (Base)" :=
                      BlanketOrderSalesLine."Qty. Invoiced (Base)" + Sign * SalesLine."Qty. to Invoice (Base)";
                    ModifyLine := TRUE;
                END;

                IF ModifyLine THEN BEGIN
                    BlanketOrderSalesLine.InitOutstanding;
                    IF (BlanketOrderSalesLine.Quantity * BlanketOrderSalesLine."Quantity Shipped" < 0) OR
                       (ABS(BlanketOrderSalesLine.Quantity) < ABS(BlanketOrderSalesLine."Quantity Shipped"))
                    THEN
                        BlanketOrderSalesLine.FIELDERROR(
                          "Quantity Shipped", STRSUBSTNO(
                            Text018,
                            BlanketOrderSalesLine.FIELDCAPTION(Quantity)));

                    IF (BlanketOrderSalesLine."Quantity (Base)" *
                       BlanketOrderSalesLine."Qty. Shipped (Base)" < 0) OR
                       (ABS(BlanketOrderSalesLine."Quantity (Base)") <
                       ABS(BlanketOrderSalesLine."Qty. Shipped (Base)"))
                    THEN
                        BlanketOrderSalesLine.FIELDERROR(
                          "Qty. Shipped (Base)",
                          STRSUBSTNO(
                            Text018,
                            BlanketOrderSalesLine.FIELDCAPTION("Quantity (Base)")));

                    BlanketOrderSalesLine.CALCFIELDS("Reserved Qty. (Base)");
                    IF ABS(BlanketOrderSalesLine."Outstanding Qty. (Base)") <
                       ABS(BlanketOrderSalesLine."Reserved Qty. (Base)")
                    THEN
                        BlanketOrderSalesLine.FIELDERROR(
                          "Reserved Qty. (Base)",
                          Text019);

                    BlanketOrderSalesLine."Qty. to Invoice" :=
                      BlanketOrderSalesLine.Quantity - BlanketOrderSalesLine."Quantity Invoiced";
                    BlanketOrderSalesLine."Qty. to Ship" :=
                      BlanketOrderSalesLine.Quantity - BlanketOrderSalesLine."Quantity Shipped";
                    BlanketOrderSalesLine."Qty. to Invoice (Base)" :=
                      BlanketOrderSalesLine."Quantity (Base)" - BlanketOrderSalesLine."Qty. Invoiced (Base)";
                    BlanketOrderSalesLine."Qty. to Ship (Base)" :=
                      BlanketOrderSalesLine."Quantity (Base)" - BlanketOrderSalesLine."Qty. Shipped (Base)";

                    BlanketOrderSalesLine.MODIFY;
                END;
            END;
    end;

    local procedure CopyCommentLines(FromDocumentType: Integer; ToDocumentType: Integer; FromNumber: Code[20]; ToNumber: Code[20])
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

    local procedure RunGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line"; DimEntryNo: Integer)
    var
        TempDimBuf: Record "Dimension Buffer" temporary;
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
        SalesLine2: Record "Sales Line";
        DimExist: Boolean;
    begin
        TempDocDim.RESET;
        TempDocDim.DELETEALL;

        //LS -
        IF SalesHeader."Only Two Dimensions" THEN BEGIN
            TempDocDim.INIT;
            TempDocDim."Table ID" := DATABASE::"Sales Header";
            TempDocDim."Document Type" := SalesHeader."Document Type";
            TempDocDim."Document No." := SalesHeader."No.";
            TempDocDim."Line No." := 0;
            TempDocDim."Dimension Code" := GLSetup."Global Dimension 1 Code";
            TempDocDim."Dimension Value Code" := SalesHeader."Shortcut Dimension 1 Code";
            IF TempDocDim."Dimension Value Code" <> '' THEN
                TempDocDim.INSERT;
            TempDocDim."Dimension Code" := GLSetup."Global Dimension 2 Code";
            TempDocDim."Dimension Value Code" := SalesHeader."Shortcut Dimension 2 Code";
            IF TempDocDim."Dimension Value Code" <> '' THEN
                TempDocDim.INSERT;
            TempDocDim.SETRANGE("Line No.", 0);
            CheckDimComb(0);
            SalesLine2.SETRANGE("Document Type", SalesHeader."Document Type");
            SalesLine2.SETRANGE("Document No.", SalesHeader."No.");
            SalesLine2.SETFILTER(Type, '<>%1', SalesLine2.Type::" ");
            IF SalesLine2.FIND('-') THEN
                REPEAT
                    TempDocDim.INIT;
                    TempDocDim."Table ID" := DATABASE::"Sales Line";
                    TempDocDim."Document Type" := SalesHeader."Document Type";
                    TempDocDim."Document No." := SalesHeader."No.";
                    TempDocDim."Line No." := SalesLine2."Line No.";
                    TempDocDim."Dimension Code" := GLSetup."Global Dimension 1 Code";
                    TempDocDim."Dimension Value Code" := SalesLine2."Shortcut Dimension 1 Code";
                    IF TempDocDim."Dimension Value Code" <> '' THEN
                        TempDocDim.INSERT;
                    TempDocDim."Dimension Code" := GLSetup."Global Dimension 2 Code";
                    TempDocDim."Dimension Value Code" := SalesLine2."Shortcut Dimension 2 Code";
                    IF TempDocDim."Dimension Value Code" <> '' THEN
                        TempDocDim.INSERT;
                UNTIL SalesLine2.NEXT = 0;
        END ELSE BEGIN
            //LS +
            DocDim.SETRANGE("Table ID", DATABASE::"Sales Header");
            DocDim.SETRANGE("Document Type", SalesHeader."Document Type");
            DocDim.SETRANGE("Document No.", SalesHeader."No.");
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
            DocDim.SETRANGE("Table ID", DATABASE::"Sales Line");
            DocDim.SETRANGE("Document Type", SalesHeader."Document Type");
            DocDim.SETRANGE("Document No.", SalesHeader."No.");
            IF DocDim.FINDSET THEN BEGIN
                REPEAT
                    TempDocDim.INIT;
                    TempDocDim := DocDim;
                    TempDocDim.INSERT;
                UNTIL DocDim.NEXT = 0;
                TempDocDim.SETRANGE("Line No.", 0);
                CheckDimComb(0);
            END;
        END;  //LS
        SalesLine2."Line No." := 0;
        CheckDimValuePosting(SalesLine2);

        SalesLine2.SETRANGE("Document Type", SalesHeader."Document Type");
        SalesLine2.SETRANGE("Document No.", SalesHeader."No.");
        SalesLine2.SETFILTER(Type, '<>%1', SalesLine2.Type::" ");
        IF SalesLine2.FINDSET THEN
            REPEAT
                IF (SalesHeader.Invoice AND (SalesLine2."Qty. to Invoice" <> 0)) OR
                   (SalesHeader.Ship AND (SalesLine2."Qty. to Ship" <> 0)) OR
                   (SalesHeader.Receive AND (SalesLine2."Return Qty. to Receive" <> 0))
                THEN BEGIN
                    TempDocDim.SETRANGE("Line No.", SalesLine2."Line No.");
                    CheckDimComb(SalesLine2."Line No.");
                    CheckDimValuePosting(SalesLine2);
                END
            UNTIL SalesLine2.NEXT = 0;
        TempDocDim.RESET;
    end;

    local procedure CheckDimComb(LineNo: Integer)
    begin
        IF NOT DimMgt.CheckDocDimComb(TempDocDim) THEN
            IF LineNo = 0 THEN
                ERROR(
                  Text028,
                  SalesHeader."Document Type", SalesHeader."No.", DimMgt.GetDimCombErr)
            ELSE
                ERROR(
                  Text029,
                  SalesHeader."Document Type", SalesHeader."No.", LineNo, DimMgt.GetDimCombErr);
    end;

    local procedure CheckDimValuePosting(var SalesLine2: Record "Sales Line")
    var
        TableIDArr: array[10] of Integer;
        NumberArr: array[10] of Code[20];
    begin
        IF SalesLine2."Line No." = 0 THEN BEGIN
            TableIDArr[1] := DATABASE::Customer;
            NumberArr[1] := SalesHeader."Bill-to Customer No.";
            TableIDArr[2] := DATABASE::"Salesperson/Purchaser";
            NumberArr[2] := SalesHeader."Salesperson Code";
            TableIDArr[3] := DATABASE::Campaign;
            NumberArr[3] := SalesHeader."Campaign No.";
            TableIDArr[4] := DATABASE::"Responsibility Center";
            NumberArr[4] := SalesHeader."Responsibility Center";
            IF NOT DimMgt.CheckDocDimValuePosting(TempDocDim, TableIDArr, NumberArr) THEN
                ERROR(
                  Text030,
                  SalesHeader."Document Type", SalesHeader."No.", DimMgt.GetDimValuePostingErr);
        END ELSE BEGIN
            TableIDArr[1] := DimMgt.TypeToTableID3(SalesLine2.Type);
            NumberArr[1] := SalesLine2."No.";
            TableIDArr[2] := DATABASE::Job;
            NumberArr[2] := SalesLine2."Job No.";
            IF NOT DimMgt.CheckDocDimValuePosting(TempDocDim, TableIDArr, NumberArr) THEN
                ERROR(
                  Text031,
                  SalesHeader."Document Type", SalesHeader."No.", SalesLine2."Line No.", DimMgt.GetDimValuePostingErr);
        END;
    end;

    procedure CopyAprvlToTempApprvl()
    begin
        TempApprovalEntry.RESET;
        TempApprovalEntry.DELETEALL;
        ApprovalEntry.SETRANGE("Table ID", DATABASE::"Sales Header");
        ApprovalEntry.SETRANGE("Document Type", SalesHeader."Document Type");
        ApprovalEntry.SETRANGE("Document No.", SalesHeader."No.");
        IF ApprovalEntry.FINDSET THEN BEGIN
            REPEAT
                TempApprovalEntry.INIT;
                TempApprovalEntry := ApprovalEntry;
                TempApprovalEntry.INSERT;
            UNTIL ApprovalEntry.NEXT = 0;
        END;
    end;

    local procedure DeleteItemChargeAssgnt()
    var
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
    begin
        ItemChargeAssgntSales.SETRANGE("Document Type", SalesLine."Document Type");
        ItemChargeAssgntSales.SETRANGE("Document No.", SalesLine."Document No.");
        IF NOT ItemChargeAssgntSales.ISEMPTY THEN
            ItemChargeAssgntSales.DELETEALL;
    end;

    local procedure UpdateItemChargeAssgnt()
    var
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
    begin
        WITH TempItemChargeAssgntSales DO BEGIN
            ClearItemChargeAssgntFilter;
            MARKEDONLY(TRUE);
            IF FINDSET THEN
                REPEAT
                    ItemChargeAssgntSales.GET("Document Type", "Document No.", "Document Line No.", "Line No.");
                    ItemChargeAssgntSales."Qty. Assigned" :=
                      ItemChargeAssgntSales."Qty. Assigned" + TempItemChargeAssgntSales."Qty. to Assign";
                    ItemChargeAssgntSales."Qty. to Assign" := 0;
                    ItemChargeAssgntSales."Amount to Assign" := 0;
                    ItemChargeAssgntSales.MODIFY;
                UNTIL TempItemChargeAssgntSales.NEXT = 0;
        END;
    end;

    local procedure UpdateSalesOrderChargeAssgnt(SalesOrderInvLine: Record "Sales Line"; SalesOrderLine: Record "Sales Line")
    var
        SalesOrderLine2: Record "Sales Line";
        SalesOrderInvLine2: Record "Sales Line";
        SalesShptLine: Record "Sales Shipment Line";
    begin
        WITH SalesOrderInvLine DO BEGIN
            ClearItemChargeAssgntFilter;
            TempItemChargeAssgntSales.SETRANGE("Document Type", "Document Type");
            TempItemChargeAssgntSales.SETRANGE("Document No.", "Document No.");
            TempItemChargeAssgntSales.SETRANGE("Document Line No.", "Line No.");
            TempItemChargeAssgntSales.MARKEDONLY(TRUE);
            IF TempItemChargeAssgntSales.FINDSET THEN
                REPEAT
                    IF TempItemChargeAssgntSales."Applies-to Doc. Type" = "Document Type" THEN BEGIN
                        SalesOrderInvLine2.GET(
                          TempItemChargeAssgntSales."Applies-to Doc. Type",
                          TempItemChargeAssgntSales."Applies-to Doc. No.",
                          TempItemChargeAssgntSales."Applies-to Doc. Line No.");
                        IF ((SalesOrderLine."Document Type" = SalesOrderLine."Document Type"::Order) AND
                            (SalesOrderInvLine2."Shipment No." = "Shipment No.")) OR
                           ((SalesOrderLine."Document Type" = SalesOrderLine."Document Type"::"Return Order") AND
                            (SalesOrderInvLine2."Return Receipt No." = "Return Receipt No."))
                        THEN BEGIN
                            IF SalesOrderLine."Document Type" = SalesOrderLine."Document Type"::Order THEN BEGIN
                                IF NOT
                                   SalesShptLine.GET(SalesOrderInvLine2."Shipment No.", SalesOrderInvLine2."Shipment Line No.")
                                THEN
                                    ERROR(Text013);
                                SalesOrderLine2.GET(
                                  SalesOrderLine2."Document Type"::Order,
                                  SalesShptLine."Order No.", SalesShptLine."Order Line No.");
                            END ELSE BEGIN
                                IF NOT
                                   ReturnRcptLine.GET(SalesOrderInvLine2."Return Receipt No.", SalesOrderInvLine2."Return Receipt Line No.")
                                THEN
                                    ERROR(Text037);
                                SalesOrderLine2.GET(
                                  SalesOrderLine2."Document Type"::"Return Order",
                                  ReturnRcptLine."Return Order No.", ReturnRcptLine."Return Order Line No.");
                            END;
                            UpdateSalesChargeAssgntLines(
                              SalesOrderLine,
                              SalesOrderLine2."Document Type",
                              SalesOrderLine2."Document No.",
                              SalesOrderLine2."Line No.",
                              TempItemChargeAssgntSales."Qty. to Assign");
                        END;
                    END ELSE
                        UpdateSalesChargeAssgntLines(
                          SalesOrderLine,
                          TempItemChargeAssgntSales."Applies-to Doc. Type",
                          TempItemChargeAssgntSales."Applies-to Doc. No.",
                          TempItemChargeAssgntSales."Applies-to Doc. Line No.",
                          TempItemChargeAssgntSales."Qty. to Assign");
                UNTIL TempItemChargeAssgntSales.NEXT = 0;
        END;
    end;

    local procedure UpdateSalesChargeAssgntLines(SalesOrderLine: Record "Sales Line"; ApplToDocType: Option; ApplToDocNo: Code[20]; ApplToDocLineNo: Integer; QtyToAssign: Decimal)
    var
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
        TempItemChargeAssgntSales2: Record "Item Charge Assignment (Sales)";
        LastLineNo: Integer;
        TotalToAssign: Decimal;
    begin
        ItemChargeAssgntSales.SETRANGE("Document Type", SalesOrderLine."Document Type");
        ItemChargeAssgntSales.SETRANGE("Document No.", SalesOrderLine."Document No.");
        ItemChargeAssgntSales.SETRANGE("Document Line No.", SalesOrderLine."Line No.");
        ItemChargeAssgntSales.SETRANGE("Applies-to Doc. Type", ApplToDocType);
        ItemChargeAssgntSales.SETRANGE("Applies-to Doc. No.", ApplToDocNo);
        ItemChargeAssgntSales.SETRANGE("Applies-to Doc. Line No.", ApplToDocLineNo);
        IF ItemChargeAssgntSales.FINDFIRST THEN BEGIN
            ItemChargeAssgntSales."Qty. Assigned" := ItemChargeAssgntSales."Qty. Assigned" + QtyToAssign;
            ItemChargeAssgntSales."Qty. to Assign" := 0;
            ItemChargeAssgntSales."Amount to Assign" := 0;
            ItemChargeAssgntSales.MODIFY;
        END ELSE BEGIN
            ItemChargeAssgntSales.SETRANGE("Applies-to Doc. Type");
            ItemChargeAssgntSales.SETRANGE("Applies-to Doc. No.");
            ItemChargeAssgntSales.SETRANGE("Applies-to Doc. Line No.");
            ItemChargeAssgntSales.CALCSUMS("Qty. to Assign");

            //calculate total qty. to assign of the invoice charge line
            TempItemChargeAssgntSales2.SETRANGE("Document Type", TempItemChargeAssgntSales."Document Type");
            TempItemChargeAssgntSales2.SETRANGE("Document No.", TempItemChargeAssgntSales."Document No.");
            TempItemChargeAssgntSales2.SETRANGE("Document Line No.", TempItemChargeAssgntSales."Document Line No.");
            TempItemChargeAssgntSales2.CALCSUMS("Qty. to Assign");

            TotalToAssign := ItemChargeAssgntSales."Qty. to Assign" +
              TempItemChargeAssgntSales2."Qty. to Assign";

            IF ItemChargeAssgntSales.FINDLAST THEN
                LastLineNo := ItemChargeAssgntSales."Line No.";

            IF SalesOrderLine.Quantity < TotalToAssign THEN
                REPEAT
                    TotalToAssign := TotalToAssign - ItemChargeAssgntSales."Qty. to Assign";
                    ItemChargeAssgntSales."Qty. to Assign" := 0;
                    ItemChargeAssgntSales."Amount to Assign" := 0;
                    ItemChargeAssgntSales.MODIFY;
                UNTIL (ItemChargeAssgntSales.NEXT(-1) = 0) OR
                      (TotalToAssign = SalesOrderLine.Quantity);

            InsertAssocOrderCharge(
              SalesOrderLine,
              ApplToDocType,
              ApplToDocNo,
              ApplToDocLineNo,
              LastLineNo,
              TempItemChargeAssgntSales."Applies-to Doc. Line Amount");

        END;
    end;

    local procedure InsertAssocOrderCharge(SalesOrderLine: Record "Sales Line"; ApplToDocType: Option; ApplToDocNo: Code[20]; ApplToDocLineNo: Integer; LastLineNo: Integer; ApplToDocLineAmt: Decimal)
    var
        NewItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
    begin
        WITH NewItemChargeAssgntSales DO BEGIN
            INIT;
            "Document Type" := SalesOrderLine."Document Type";
            "Document No." := SalesOrderLine."Document No.";
            "Document Line No." := SalesOrderLine."Line No.";
            "Line No." := LastLineNo + 10000;
            "Item Charge No." := TempItemChargeAssgntSales."Item Charge No.";
            "Item No." := TempItemChargeAssgntSales."Item No.";
            "Qty. Assigned" := TempItemChargeAssgntSales."Qty. to Assign";
            "Qty. to Assign" := 0;
            "Amount to Assign" := 0;
            Description := TempItemChargeAssgntSales.Description;
            "Unit Cost" := TempItemChargeAssgntSales."Unit Cost";
            "Applies-to Doc. Type" := ApplToDocType;
            "Applies-to Doc. No." := ApplToDocNo;
            "Applies-to Doc. Line No." := ApplToDocLineNo;
            "Applies-to Doc. Line Amount" := ApplToDocLineAmt;
            INSERT;
        END;
    end;

    local procedure CopyAndCheckItemCharge(SalesHeader: Record "Sales Header")
    var
        SalesLine2: Record "Sales Line";
        SalesLine3: Record "Sales Line";
        InvoiceEverything: Boolean;
        AssignError: Boolean;
        QtyNeeded: Decimal;
    begin
        TempItemChargeAssgntSales.RESET;
        TempItemChargeAssgntSales.DELETEALL;

        // Check for max qty posting
        SalesLine2.RESET;
        SalesLine2.SETRANGE("Document Type", SalesHeader."Document Type");
        SalesLine2.SETRANGE("Document No.", SalesHeader."No.");
        SalesLine2.SETRANGE(Type, SalesLine2.Type::"Charge (Item)");
        SalesLine2.SETFILTER("Qty. to Invoice", '<>0');
        IF SalesLine2.ISEMPTY THEN
            EXIT;

        SalesLine2.FINDSET;
        REPEAT
            ItemChargeAssgntSales.RESET;
            ItemChargeAssgntSales.SETRANGE("Document Type", SalesLine2."Document Type");
            ItemChargeAssgntSales.SETRANGE("Document No.", SalesLine2."Document No.");
            ItemChargeAssgntSales.SETRANGE("Document Line No.", SalesLine2."Line No.");
            ItemChargeAssgntSales.SETFILTER("Qty. to Assign", '<>0');
            IF ItemChargeAssgntSales.FINDSET THEN
                REPEAT
                    TempItemChargeAssgntSales.INIT;
                    TempItemChargeAssgntSales := ItemChargeAssgntSales;
                    TempItemChargeAssgntSales.INSERT;
                UNTIL ItemChargeAssgntSales.NEXT = 0;

            SalesLine.TESTFIELD("Job No.", '');
            SalesLine2.TESTFIELD("Job Contract Entry No.", 0);
            IF (SalesLine2."Qty. to Ship" + SalesLine2."Return Qty. to Receive" <> 0) AND
               ((SalesHeader.Ship OR SalesHeader.Receive) OR
                (ABS(SalesLine2."Qty. to Invoice") >
                 ABS(SalesLine2."Qty. Shipped Not Invoiced" + SalesLine2."Qty. to Ship") +
                 ABS(SalesLine2."Ret. Qty. Rcd. Not Invd.(Base)" + SalesLine2."Return Qty. to Receive")))
            THEN
                SalesLine2.TESTFIELD("Line Amount");

            IF NOT SalesHeader.Ship THEN
                SalesLine2."Qty. to Ship" := 0;
            IF NOT SalesHeader.Receive THEN
                SalesLine2."Return Qty. to Receive" := 0;
            IF ABS(SalesLine2."Qty. to Invoice") >
               ABS(SalesLine2."Quantity Shipped" + SalesLine2."Qty. to Ship" +
                 SalesLine2."Return Qty. Received" + SalesLine2."Return Qty. to Receive" -
                 SalesLine2."Quantity Invoiced")
            THEN
                SalesLine2."Qty. to Invoice" :=
                  SalesLine2."Quantity Shipped" + SalesLine2."Qty. to Ship" +
                  SalesLine2."Return Qty. Received" + SalesLine2."Return Qty. to Receive" -
                  SalesLine2."Quantity Invoiced";

            SalesLine2.CALCFIELDS("Qty. to Assign", "Qty. Assigned");
            IF ABS(SalesLine2."Qty. to Assign" + SalesLine2."Qty. Assigned") >
               ABS(SalesLine2."Qty. to Invoice" + SalesLine2."Quantity Invoiced")
            THEN
                ERROR(Text032,
                  SalesLine2."Qty. to Invoice" + SalesLine2."Quantity Invoiced" -
                  SalesLine2."Qty. Assigned", SalesLine2.FIELDCAPTION("Document Type"),
                  SalesLine2."Document Type", SalesLine2.FIELDCAPTION("Document No."),
                  SalesLine2."Document No.", SalesLine2.FIELDCAPTION("Line No."),
                  SalesLine2."Line No.");
            IF SalesLine2.Quantity =
               SalesLine2."Qty. to Invoice" + SalesLine2."Quantity Invoiced"
            THEN BEGIN
                IF SalesLine2."Qty. to Assign" <> 0 THEN BEGIN
                    IF SalesLine2.Quantity = SalesLine2."Quantity Invoiced" THEN BEGIN
                        TempItemChargeAssgntSales.SETRANGE("Document Line No.", SalesLine2."Line No.");
                        TempItemChargeAssgntSales.SETRANGE("Applies-to Doc. Type", SalesLine2."Document Type");
                        IF TempItemChargeAssgntSales.FINDSET THEN
                            REPEAT
                                SalesLine3.GET(
                                  TempItemChargeAssgntSales."Applies-to Doc. Type",
                                  TempItemChargeAssgntSales."Applies-to Doc. No.",
                                  TempItemChargeAssgntSales."Applies-to Doc. Line No.");
                                IF SalesLine3.Quantity = SalesLine3."Quantity Invoiced" THEN
                                    ERROR(Text034, SalesLine3.TABLECAPTION,
                                      SalesLine3.FIELDCAPTION("Document Type"), SalesLine3."Document Type",
                                      SalesLine3.FIELDCAPTION("Document No."), SalesLine3."Document No.",
                                      SalesLine3.FIELDCAPTION("Line No."), SalesLine3."Line No.");
                            UNTIL TempItemChargeAssgntSales.NEXT = 0;
                    END;
                END;
                IF SalesLine2.Quantity <> SalesLine2."Qty. to Assign" + SalesLine2."Qty. Assigned" THEN
                    AssignError := TRUE;
            END;

            IF (SalesLine2."Qty. to Assign" + SalesLine2."Qty. Assigned") < (SalesLine2."Qty. to Invoice" + SalesLine2."Quantity Invoiced")
            THEN
                ERROR(Text052, SalesLine2."No.");

            // check if all ILEs exist
            QtyNeeded := SalesLine2."Qty. to Assign";
            TempItemChargeAssgntSales.SETRANGE("Document Line No.", SalesLine2."Line No.");
            IF TempItemChargeAssgntSales.FINDSET THEN
                REPEAT
                    IF (TempItemChargeAssgntSales."Applies-to Doc. Type" <> SalesLine2."Document Type") AND
                       (TempItemChargeAssgntSales."Applies-to Doc. No." <> SalesLine2."Document No.")
                    THEN
                        QtyNeeded := QtyNeeded - TempItemChargeAssgntSales."Qty. to Assign"
                    ELSE BEGIN
                        SalesLine3.GET(
                          TempItemChargeAssgntSales."Applies-to Doc. Type",
                          TempItemChargeAssgntSales."Applies-to Doc. No.",
                          TempItemChargeAssgntSales."Applies-to Doc. Line No.");
                        IF ItemLedgerEntryExist(SalesLine3) THEN
                            QtyNeeded := QtyNeeded - TempItemChargeAssgntSales."Qty. to Assign";
                    END;
                UNTIL TempItemChargeAssgntSales.NEXT = 0;

            IF QtyNeeded > 0 THEN
                ERROR(Text053, SalesLine2."No.");

        UNTIL SalesLine2.NEXT = 0;

        // Check saleslines
        IF AssignError THEN
            IF SalesHeader."Document Type" IN
               [SalesHeader."Document Type"::Invoice, SalesHeader."Document Type"::"Credit Memo"]
            THEN
                InvoiceEverything := TRUE
            ELSE BEGIN
                SalesLine2.RESET;
                SalesLine2.SETRANGE("Document Type", SalesHeader."Document Type");
                SalesLine2.SETRANGE("Document No.", SalesHeader."No.");
                SalesLine2.SETFILTER(Type, '%1|%2', SalesLine2.Type::Item, SalesLine2.Type::"Charge (Item)");
                IF SalesLine2.FINDSET THEN
                    REPEAT
                        IF SalesHeader.Ship OR SalesHeader.Receive THEN
                            InvoiceEverything :=
                              SalesLine2.Quantity = SalesLine2."Qty. to Invoice" + SalesLine2."Quantity Invoiced"
                        ELSE
                            InvoiceEverything :=
                              (SalesLine2.Quantity = SalesLine2."Qty. to Invoice" + SalesLine2."Quantity Invoiced") AND
                              (SalesLine2."Qty. to Invoice" =
                               SalesLine2."Qty. Shipped Not Invoiced" + SalesLine2."Ret. Qty. Rcd. Not Invd.(Base)");
                    UNTIL (SalesLine2.NEXT = 0) OR (NOT InvoiceEverything);
            END;

        IF InvoiceEverything AND AssignError THEN
            ERROR(Text033);
    end;

    local procedure ClearItemChargeAssgntFilter()
    begin
        TempItemChargeAssgntSales.SETRANGE("Document Line No.");
        TempItemChargeAssgntSales.SETRANGE("Applies-to Doc. Type");
        TempItemChargeAssgntSales.SETRANGE("Applies-to Doc. No.");
        TempItemChargeAssgntSales.SETRANGE("Applies-to Doc. Line No.");
        TempItemChargeAssgntSales.MARKEDONLY(FALSE);
    end;

    local procedure GetItemChargeLine(var ItemChargeSalesLine: Record "Sales Line")
    var
        SalesShptLine: Record "Sales Shipment Line";
        QtyShippedNotInvd: Decimal;
    begin
        WITH TempItemChargeAssgntSales DO BEGIN
            IF (ItemChargeSalesLine."Document Type" <> "Document Type") OR
               (ItemChargeSalesLine."Document No." <> "Document No.") OR
               (ItemChargeSalesLine."Line No." <> "Document Line No.")
            THEN BEGIN
                ItemChargeSalesLine.GET("Document Type", "Document No.", "Document Line No.");
                IF NOT SalesHeader.Ship THEN
                    ItemChargeSalesLine."Qty. to Ship" := 0;
                IF NOT SalesHeader.Receive THEN
                    ItemChargeSalesLine."Return Qty. to Receive" := 0;
                IF ItemChargeSalesLine."Shipment No." <> '' THEN BEGIN
                    SalesShptLine.GET(ItemChargeSalesLine."Shipment No.", ItemChargeSalesLine."Shipment Line No.");
                    QtyShippedNotInvd := TempItemChargeAssgntSales."Qty. to Assign" - TempItemChargeAssgntSales."Qty. Assigned";
                END ELSE
                    QtyShippedNotInvd := ItemChargeSalesLine."Quantity Shipped";
                IF ABS(ItemChargeSalesLine."Qty. to Invoice") >
                   ABS(QtyShippedNotInvd + ItemChargeSalesLine."Qty. to Ship" +
                       ItemChargeSalesLine."Return Qty. Received" + ItemChargeSalesLine."Return Qty. to Receive" -
                       ItemChargeSalesLine."Quantity Invoiced")
                THEN
                    ItemChargeSalesLine."Qty. to Invoice" :=
                      QtyShippedNotInvd + ItemChargeSalesLine."Qty. to Ship" +
                      ItemChargeSalesLine."Return Qty. Received" + ItemChargeSalesLine."Return Qty. to Receive" -
                      ItemChargeSalesLine."Quantity Invoiced";
            END;
        END;
    end;

    local procedure OnlyAssgntPosting(): Boolean
    var
        SalesLine: Record "Sales Line";
        QtyLeftToAssign: Boolean;
    begin
        WITH SalesHeader DO BEGIN
            ItemChargeAssgntOnly := FALSE;
            QtyLeftToAssign := FALSE;
            SalesLine.SETRANGE("Document Type", "Document Type");
            SalesLine.SETRANGE("Document No.", "No.");
            SalesLine.SETRANGE(Type, SalesLine.Type::"Charge (Item)");
            IF SalesLine.FINDSET THEN BEGIN
                REPEAT
                    SalesLine.CALCFIELDS("Qty. Assigned");
                    IF (SalesLine."Quantity Invoiced" > SalesLine."Qty. Assigned") THEN
                        QtyLeftToAssign := TRUE;
                UNTIL SalesLine.NEXT = 0;
            END;

            IF QtyLeftToAssign THEN
                CopyAndCheckItemCharge(SalesHeader);
            ClearItemChargeAssgntFilter;
            TempItemChargeAssgntSales.SETCURRENTKEY("Applies-to Doc. Type");
            TempItemChargeAssgntSales.SETFILTER("Applies-to Doc. Type", '<>%1', "Document Type");
            SalesLine.SETRANGE(Type);
            SalesLine.SETRANGE("Quantity Invoiced");
            SalesLine.SETFILTER("Qty. to Assign", '<>0');
            IF SalesLine.FINDSET THEN
                REPEAT
                    TempItemChargeAssgntSales.SETRANGE("Document Line No.", SalesLine."Line No.");
                    ItemChargeAssgntOnly := NOT TempItemChargeAssgntSales.ISEMPTY;
                UNTIL (SalesLine.NEXT = 0) OR ItemChargeAssgntOnly
            ELSE
                ItemChargeAssgntOnly := FALSE;
        END;
        EXIT(ItemChargeAssgntOnly);
    end;

    procedure CalcQtyToInvoice(QtyToHandle: Decimal; QtyToInvoice: Decimal): Decimal
    begin
        IF ABS(QtyToHandle) > ABS(QtyToInvoice) THEN
            EXIT(-QtyToHandle)
        ELSE
            EXIT(-QtyToInvoice);
    end;

    procedure GetShippingAdvice(): Boolean
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SETRANGE("Document Type", SalesHeader."Document Type");
        SalesLine.SETRANGE("Document No.", SalesHeader."No.");
        SalesLine.SETRANGE("Drop Shipment", FALSE);
        IF SalesLine.FINDSET THEN
            REPEAT
                IF SalesLine.IsShipment THEN BEGIN
                    IF SalesLine."Document Type" IN
                       [SalesLine."Document Type"::"Credit Memo",
                        SalesLine."Document Type"::"Return Order"]
                    THEN BEGIN
                        IF SalesLine."Quantity (Base)" <>
                           SalesLine."Return Qty. to Receive (Base)" + SalesLine."Return Qty. Received (Base)"
                        THEN
                            EXIT(FALSE)
                    END ELSE
                        IF SalesLine."Quantity (Base)" <>
                           SalesLine."Qty. to Ship (Base)" + SalesLine."Qty. Shipped (Base)"
                        THEN
                            EXIT(FALSE);
                END;
            UNTIL SalesLine.NEXT = 0;
        EXIT(TRUE);
    end;

    local procedure CheckWarehouse(var SalesLine: Record "Sales Line")
    var
        SalesLine2: Record "Sales Line";
        WhseValidateSourceLine: Codeunit "5777";
        ShowError: Boolean;
    begin
        SalesLine2.COPY(SalesLine);
        SalesLine2.SETRANGE(Type, SalesLine2.Type::Item);
        SalesLine2.SETRANGE("Drop Shipment", FALSE);
        IF SalesLine2.FINDSET THEN
            REPEAT
                GetLocation(SalesLine2."Location Code");
                CASE SalesLine2."Document Type" OF
                    SalesLine2."Document Type"::Order:
                        IF ((Location."Require Receive" OR Location."Require Put-away") AND
                            (SalesLine2.Quantity < 0)) OR
                           ((Location."Require Shipment" OR Location."Require Pick") AND
                            (SalesLine2.Quantity >= 0))
                        THEN BEGIN
                            IF Location."Directed Put-away and Pick" THEN
                                ShowError := TRUE
                            ELSE
                                IF WhseValidateSourceLine.WhseLinesExist(
                                     DATABASE::"Sales Line",
                                     SalesLine2."Document Type",
                                     SalesLine2."Document No.",
                                     SalesLine2."Line No.",
                                     0,
                                     SalesLine2.Quantity)
                                THEN
                                    ShowError := TRUE;
                        END;
                    SalesLine2."Document Type"::"Return Order":
                        IF ((Location."Require Receive" OR Location."Require Put-away") AND
                            (SalesLine2.Quantity >= 0)) OR
                           ((Location."Require Shipment" OR Location."Require Pick") AND
                            (SalesLine2.Quantity < 0))
                        THEN BEGIN
                            IF Location."Directed Put-away and Pick" THEN
                                ShowError := TRUE
                            ELSE
                                IF WhseValidateSourceLine.WhseLinesExist(
                                     DATABASE::"Sales Line",
                                     SalesLine2."Document Type",
                                     SalesLine2."Document No.",
                                     SalesLine2."Line No.",
                                     0,
                                     SalesLine2.Quantity)
                                THEN
                                    ShowError := TRUE;
                        END;
                    SalesLine2."Document Type"::Invoice, SalesLine2."Document Type"::"Credit Memo":
                        IF Location."Directed Put-away and Pick" THEN
                            Location.TESTFIELD("Adjustment Bin Code");
                END;
                IF ShowError THEN
                    ERROR(
                      Text021,
                      SalesLine2.FIELDCAPTION("Document Type"),
                      SalesLine2."Document Type",
                      SalesLine2.FIELDCAPTION("Document No."),
                      SalesLine2."Document No.",
                      SalesLine2.FIELDCAPTION("Line No."),
                      SalesLine2."Line No.");
            UNTIL SalesLine2.NEXT = 0;
    end;

    local procedure CreateWhseJnlLine(ItemJnlLine: Record "Item Journal Line"; SalesLine: Record "Sales Line"; var TempWhseJnlLine: Record "Warehouse Journal Line" temporary)
    var
        WhseMgt: Codeunit "5775";
    begin
        WITH SalesLine DO BEGIN
            WMSMgmt.CheckAdjmtBin(Location, ItemJnlLine.Quantity, TRUE);
            WMSMgmt.CreateWhseJnlLine(ItemJnlLine, 0, TempWhseJnlLine, FALSE, FALSE);
            TempWhseJnlLine."Source Type" := DATABASE::"Sales Line";
            TempWhseJnlLine."Source Subtype" := "Document Type";
            TempWhseJnlLine."Source Code" := SrcCode;
            WhseMgt.GetSourceDocument(
              TempWhseJnlLine."Source Document", TempWhseJnlLine."Source Type", TempWhseJnlLine."Source Subtype");
            TempWhseJnlLine."Source No." := "Document No.";
            TempWhseJnlLine."Source Line No." := "Line No.";
            CASE "Document Type" OF
                "Document Type"::Order:
                    TempWhseJnlLine."Reference Document" :=
                      TempWhseJnlLine."Reference Document"::"Posted Shipment";
                "Document Type"::Invoice:
                    TempWhseJnlLine."Reference Document" :=
                      TempWhseJnlLine."Reference Document"::"Posted S. Inv.";
                "Document Type"::"Credit Memo":
                    TempWhseJnlLine."Reference Document" :=
                      TempWhseJnlLine."Reference Document"::"Posted S. Cr. Memo";
                "Document Type"::"Return Order":
                    TempWhseJnlLine."Reference Document" :=
                      TempWhseJnlLine."Reference Document"::"Posted Rtrn. Shipment";
            END;
            TempWhseJnlLine."Reference No." := ItemJnlLine."Document No.";
        END;
    end;

    local procedure WhseHandlingRequired(): Boolean
    var
        WhseSetup: Record "Warehouse Setup";
    begin
        IF (SalesLine.Type = SalesLine.Type::Item) AND
           (NOT SalesLine."Drop Shipment")
        THEN BEGIN
            IF SalesLine."Location Code" = '' THEN BEGIN
                WhseSetup.GET;
                IF SalesLine."Document Type" = SalesLine."Document Type"::"Return Order" THEN
                    EXIT(WhseSetup."Require Receive")
                ELSE
                    EXIT(WhseSetup."Require Pick");
            END ELSE BEGIN
                GetLocation(SalesLine."Location Code");
                IF SalesLine."Document Type" = SalesLine."Document Type"::"Return Order" THEN
                    EXIT(Location."Require Receive")
                ELSE
                    EXIT(Location."Require Pick");
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

    local procedure InsertShptEntryRelation(var SalesShptLine: Record "Sales Shipment Line"): Integer
    var
        ItemEntryRelation: Record "Item Entry Relation";
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
                ItemEntryRelation.TransferFieldsSalesShptLine(SalesShptLine);
                ItemEntryRelation.INSERT;
            UNTIL TempHandlingSpecification.NEXT = 0;
            TempHandlingSpecification.DELETEALL;
            EXIT(0);
        END ELSE
            EXIT(ItemLedgShptEntryNo);
    end;

    local procedure InsertReturnEntryRelation(var ReturnRcptLine: Record "Return Receipt Line"): Integer
    var
        ItemEntryRelation: Record "Item Entry Relation";
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
                ItemEntryRelation.TransferFieldsReturnRcptLine(ReturnRcptLine);
                ItemEntryRelation.INSERT;
            UNTIL TempHandlingSpecification.NEXT = 0;
            TempHandlingSpecification.DELETEALL;
            EXIT(0);
        END ELSE
            EXIT(ItemLedgShptEntryNo);
    end;

    local procedure CheckTrackingSpecification(var SalesLine: Record "Sales Line")
    var
        SalesLineToCheck: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        ItemTrackingCode: Record "Item Tracking Code";
        CreateReservEntry: Codeunit "99000830";
        ItemTrackingManagement: Codeunit "6500";
        ErrorFieldCaption: Text[250];
        SignFactor: Integer;
        SalesLineQtyHandled: Decimal;
        SalesLineQtyToHandle: Decimal;
        TrackingQtyHandled: Decimal;
        TrackingQtyToHandle: Decimal;
        Inbound: Boolean;
        SNRequired: Boolean;
        LotRequired: Boolean;
        SNInfoRequired: Boolean;
        LotInfoReguired: Boolean;
        CheckSalesLine: Boolean;
    begin
        // if a SalesLine is posted with ItemTracking then the whole quantity of
        // the regarding SalesLine has to be post with Item-Tracking

        IF SalesHeader."Document Type" IN
          [SalesHeader."Document Type"::Order, SalesHeader."Document Type"::"Return Order"] = FALSE
        THEN
            EXIT;

        TrackingQtyToHandle := 0;
        TrackingQtyHandled := 0;

        SalesLineToCheck.COPY(SalesLine);
        SalesLineToCheck.SETRANGE(Type, SalesLineToCheck.Type::Item);
        IF SalesHeader.Ship THEN BEGIN
            SalesLineToCheck.SETFILTER("Quantity Shipped", '<>%1', 0);
            ErrorFieldCaption := SalesLineToCheck.FIELDCAPTION("Qty. to Ship");
        END ELSE BEGIN
            SalesLineToCheck.SETFILTER("Return Qty. Received", '<>%1', 0);
            ErrorFieldCaption := SalesLineToCheck.FIELDCAPTION("Return Qty. to Receive");
        END;

        IF SalesLineToCheck.FINDSET THEN BEGIN
            ReservationEntry."Source Type" := DATABASE::"Sales Line";
            ReservationEntry."Source Subtype" := SalesHeader."Document Type";
            SignFactor := CreateReservEntry.SignFactor(ReservationEntry);
            REPEAT
                // Only Item where no SerialNo or LotNo is required
                GetItem(SalesLineToCheck);
                IF Item."Item Tracking Code" <> '' THEN BEGIN
                    Inbound := (SalesLineToCheck.Quantity * SignFactor) > 0;
                    ItemTrackingCode.Code := Item."Item Tracking Code";
                    ItemTrackingManagement.GetItemTrackingSettings(ItemTrackingCode,
                      ItemJnlLine."Entry Type"::Sale,
                      Inbound,
                      SNRequired,
                      LotRequired,
                      SNInfoRequired,
                      LotInfoReguired);
                    CheckSalesLine := (SNRequired = FALSE) AND (LotRequired = FALSE);
                    IF CheckSalesLine THEN
                        CheckSalesLine := GetTrackingQuantities(SalesLineToCheck, 0, TrackingQtyToHandle, TrackingQtyHandled);
                END ELSE
                    CheckSalesLine := FALSE;

                TrackingQtyToHandle := 0;
                TrackingQtyHandled := 0;

                IF CheckSalesLine THEN BEGIN
                    GetTrackingQuantities(SalesLineToCheck, 1, TrackingQtyToHandle, TrackingQtyHandled);
                    TrackingQtyToHandle := TrackingQtyToHandle * SignFactor;
                    TrackingQtyHandled := TrackingQtyHandled * SignFactor;
                    IF SalesHeader.Ship THEN BEGIN
                        SalesLineQtyToHandle := SalesLineToCheck."Qty. to Ship (Base)";
                        SalesLineQtyHandled := SalesLineToCheck."Qty. Shipped (Base)";
                    END ELSE BEGIN
                        SalesLineQtyToHandle := SalesLineToCheck."Return Qty. to Receive (Base)";
                        SalesLineQtyHandled := SalesLineToCheck."Return Qty. Received (Base)";
                    END;
                    IF ((TrackingQtyHandled + TrackingQtyToHandle) <> (SalesLineQtyHandled + SalesLineQtyToHandle)) OR
                       (TrackingQtyToHandle <> SalesLineQtyToHandle)
                    THEN
                        ERROR(STRSUBSTNO(Text046, ErrorFieldCaption));
                END;
            UNTIL SalesLineToCheck.NEXT = 0;
        END;
    end;

    local procedure GetTrackingQuantities(SalesLine: Record "Sales Line"; FunctionType: Option CheckTrackingExists,GetQty; var TrackingQtyToHandle: Decimal; var TrackingQtyHandled: Decimal): Boolean
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservEntry: Record "Reservation Entry";
    begin
        WITH TrackingSpecification DO BEGIN
            SETCURRENTKEY("Source ID", "Source Type", "Source Subtype", "Source Batch Name",
              "Source Prod. Order Line", "Source Ref. No.");
            SETRANGE("Source Type", DATABASE::"Sales Line");
            SETRANGE("Source Subtype", SalesLine."Document Type");
            SETRANGE("Source ID", SalesLine."Document No.");
            SETRANGE("Source Batch Name", '');
            SETRANGE("Source Prod. Order Line", 0);
            SETRANGE("Source Ref. No.", SalesLine."Line No.");
        END;
        WITH ReservEntry DO BEGIN
            SETCURRENTKEY(
              "Source ID", "Source Ref. No.", "Source Type", "Source Subtype",
              "Source Batch Name", "Source Prod. Order Line");
            SETRANGE("Source ID", SalesLine."Document No.");
            SETRANGE("Source Ref. No.", SalesLine."Line No.");
            SETRANGE("Source Type", DATABASE::"Sales Line");
            SETRANGE("Source Subtype", SalesLine."Document Type");
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
                TempTrackingSpecification.INSERT;
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
                TrackingSpecification.Correction := FALSE;
                TrackingSpecification.InitQtyToShip;
                TrackingSpecification."Quantity actual Handled (Base)" := 0;
                IF TempTrackingSpecification."Buffer Status" = TempTrackingSpecification."Buffer Status"::MODIFY THEN
                    TrackingSpecification.MODIFY
                ELSE
                    TrackingSpecification.INSERT;
            UNTIL TempTrackingSpecification.NEXT = 0;
            TempTrackingSpecification.DELETEALL;
        END;

        ReserveSalesLine.UpdateItemTrackingAfterPosting(SalesHeader);
    end;

    local procedure InsertValueEntryRelation()
    var
        ValueEntryRelation: Record "Value Entry Relation";
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

    procedure PostItemCharge(SalesLine: Record "Sales Line"; ItemEntryNo: Integer; QuantityBase: Decimal; AmountToAssign: Decimal; QtyToAssign: Decimal)
    var
        DummyTrackingSpecification: Record "Tracking Specification";
    begin
        WITH TempItemChargeAssgntSales DO BEGIN
            SalesLine."No." := "Item No.";
            SalesLine."Appl.-to Item Entry" := ItemEntryNo;
            IF NOT ("Document Type" IN ["Document Type"::"Return Order", "Document Type"::"Credit Memo"]) THEN
                SalesLine.Amount := -AmountToAssign
            ELSE
                SalesLine.Amount := AmountToAssign;

            IF SalesLine."Currency Code" <> '' THEN
                SalesLine."Unit Cost" := ROUND(
                  -SalesLine.Amount / QuantityBase, Currency."Unit-Amount Rounding Precision")
            ELSE
                SalesLine."Unit Cost" := ROUND(
                  -SalesLine.Amount / QuantityBase, GLSetup."Unit-Amount Rounding Precision");
            TotalChargeAmt := TotalChargeAmt + SalesLine.Amount;

            IF SalesHeader."Currency Code" <> '' THEN
                SalesLine.Amount :=
                  CurrExchRate.ExchangeAmtFCYToLCY(
                    UseDate, SalesHeader."Currency Code", TotalChargeAmt, SalesHeader."Currency Factor");
            SalesLine."Inv. Discount Amount" := ROUND(
              SalesLine."Inv. Discount Amount" / SalesLine.Quantity * QtyToAssign,
              GLSetup."Amount Rounding Precision");
            SalesLine.Amount := ROUND(SalesLine.Amount, GLSetup."Amount Rounding Precision") - TotalChargeAmtLCY;
            IF SalesHeader."Currency Code" <> '' THEN
                TotalChargeAmtLCY := TotalChargeAmtLCY + SalesLine.Amount;
            SalesLine."Unit Cost (LCY)" := ROUND(
              SalesLine.Amount / QuantityBase, GLSetup."Unit-Amount Rounding Precision");
            SalesLine."Line No." := "Document Line No.";
            PostItemJnlLine(
              SalesLine,
              0, 0, -QuantityBase, -QuantityBase,
              SalesLine."Appl.-to Item Entry",
              TempItemChargeAssgntSales."Item Charge No.", DummyTrackingSpecification);
        END;
    end;

    local procedure SaveTempWhseSplitSpec(var SalesLine3: Record "Sales Line")
    begin
        TempWhseSplitSpecification.RESET;
        TempWhseSplitSpecification.DELETEALL;
        IF TempHandlingSpecification.FINDSET THEN
            REPEAT
                TempWhseSplitSpecification := TempHandlingSpecification;
                TempWhseSplitSpecification."Source Type" := DATABASE::"Sales Line";
                TempWhseSplitSpecification."Source Subtype" := SalesLine3."Document Type";
                TempWhseSplitSpecification."Source ID" := SalesLine3."Document No.";
                TempWhseSplitSpecification."Source Ref. No." := SalesLine3."Line No.";
                TempWhseSplitSpecification.INSERT;
            UNTIL TempHandlingSpecification.NEXT = 0;
    end;

    procedure TransferReservToItemJnlLine(var SalesOrderLine: Record "Sales Line"; var ItemJnlLine: Record "Item Journal Line"; QtyToBeShippedBase: Decimal; var TempTrackingSpecification2: Record "Tracking Specification" temporary; var CheckApplFromItemEntry: Boolean)
    begin
        // Handle Item Tracking and reservations, also on drop shipment
        IF QtyToBeShippedBase = 0 THEN
            EXIT;

        CLEAR(ReserveSalesLine);
        IF NOT SalesOrderLine."Drop Shipment" THEN
            ReserveSalesLine.TransferSalesLineToItemJnlLine(
              SalesOrderLine, ItemJnlLine, QtyToBeShippedBase, CheckApplFromItemEntry)
        ELSE BEGIN
            TempTrackingSpecification2.RESET;
            TempTrackingSpecification2.SETRANGE("Source Type", DATABASE::"Purchase Line");
            TempTrackingSpecification2.SETRANGE("Source Subtype", 1);
            TempTrackingSpecification2.SETRANGE("Source ID", SalesOrderLine."Purchase Order No.");
            TempTrackingSpecification2.SETRANGE("Source Batch Name", '');
            TempTrackingSpecification2.SETRANGE("Source Prod. Order Line", 0);
            TempTrackingSpecification2.SETRANGE("Source Ref. No.", SalesOrderLine."Purch. Order Line No.");
            IF TempTrackingSpecification2.ISEMPTY THEN
                ReserveSalesLine.TransferSalesLineToItemJnlLine(
                  SalesOrderLine, ItemJnlLine, QtyToBeShippedBase, CheckApplFromItemEntry)
            ELSE BEGIN
                ReserveSalesLine.SetApplySpecificItemTracking(TRUE);
                ReserveSalesLine.SetOverruleItemTracking(TRUE);
                ReserveSalesLine.SetItemTrkgAlreadyOverruled(ItemTrkgAlreadyOverruled);
                TempTrackingSpecification2.FINDSET;
                IF TempTrackingSpecification2."Quantity (Base)" / QtyToBeShippedBase < 0 THEN
                    ERROR(Text043);
                REPEAT
                    ItemJnlLine."Serial No." := TempTrackingSpecification2."Serial No.";
                    ItemJnlLine."Lot No." := TempTrackingSpecification2."Lot No.";
                    ItemJnlLine."Applies-to Entry" := TempTrackingSpecification2."Appl.-to Item Entry";
                    ReserveSalesLine.TransferSalesLineToItemJnlLine(SalesOrderLine, ItemJnlLine,
                      TempTrackingSpecification2."Quantity (Base)", CheckApplFromItemEntry);
                UNTIL TempTrackingSpecification2.NEXT = 0;
                ItemJnlLine."Serial No." := '';
                ItemJnlLine."Lot No." := '';
                ItemJnlLine."Applies-to Entry" := 0;
            END;
        END;
    end;

    procedure TransferReservFromPurchLine(var PurchOrderLine: Record "Purchase Line"; var ItemJnlLine: Record "Item Journal Line"; QtyToBeShippedBase: Decimal)
    var
        ReservEntry: Record "Reservation Entry";
        TempTrackingSpecification2: Record "Tracking Specification" temporary;
        ReservePurchLine: Codeunit "99000834";
        RemainingQuantity: Decimal;
        CheckApplToItemEntry: Boolean;
    begin
        // Handle Item Tracking on Drop Shipment
        ItemTrkgAlreadyOverruled := FALSE;
        IF QtyToBeShippedBase = 0 THEN
            EXIT;

        ReservEntry.SETCURRENTKEY(
          "Source ID", "Source Ref. No.", "Source Type", "Source Subtype",
          "Source Batch Name", "Source Prod. Order Line");
        ReservEntry.SETRANGE("Source ID", SalesLine."Document No.");
        ReservEntry.SETRANGE("Source Ref. No.", SalesLine."Line No.");
        ReservEntry.SETRANGE("Source Type", DATABASE::"Sales Line");
        ReservEntry.SETRANGE("Source Subtype", SalesLine."Document Type");
        ReservEntry.SETRANGE("Source Batch Name", '');
        ReservEntry.SETRANGE("Source Prod. Order Line", 0);
        ReservEntry.SETFILTER("Qty. to Handle (Base)", '<>0');
        IF NOT ReservEntry.ISEMPTY THEN
            ItemTrackingMgt.SumUpItemTracking(ReservEntry, TempTrackingSpecification2, FALSE, TRUE);
        TempTrackingSpecification2.SETFILTER("Qty. to Handle (Base)", '<>0');
        IF TempTrackingSpecification2.ISEMPTY THEN
            ReservePurchLine.TransferPurchLineToItemJnlLine(
              PurchOrderLine, ItemJnlLine, QtyToBeShippedBase, CheckApplToItemEntry)
        ELSE BEGIN
            ReservePurchLine.SetOverruleItemTracking(TRUE);
            ItemTrkgAlreadyOverruled := TRUE;
            TempTrackingSpecification2.FINDSET;
            IF -TempTrackingSpecification2."Quantity (Base)" / QtyToBeShippedBase < 0 THEN
                ERROR(Text043);
            REPEAT
                ItemJnlLine."Serial No." := TempTrackingSpecification2."Serial No.";
                ItemJnlLine."Lot No." := TempTrackingSpecification2."Lot No.";
                RemainingQuantity :=
                  ReservePurchLine.TransferPurchLineToItemJnlLine(
                    PurchOrderLine, ItemJnlLine,
                    -TempTrackingSpecification2."Qty. to Handle (Base)", CheckApplToItemEntry);
                IF RemainingQuantity <> 0 THEN
                    ERROR(Text044);
            UNTIL TempTrackingSpecification2.NEXT = 0;
            ItemJnlLine."Serial No." := '';
            ItemJnlLine."Lot No." := '';
            ItemJnlLine."Applies-to Entry" := 0;
        END;
    end;

    procedure SetWhseRcptHeader(var WhseRcptHeader2: Record "Warehouse Receipt Header")
    begin
        WhseRcptHeader := WhseRcptHeader2;
        TempWhseRcptHeader := WhseRcptHeader;
        TempWhseRcptHeader.INSERT;
    end;

    procedure SetWhseShptHeader(var WhseShptHeader2: Record "Warehouse Shipment Header")
    begin
        WhseShptHeader := WhseShptHeader2;
        TempWhseShptHeader := WhseShptHeader;
        TempWhseShptHeader.INSERT;
    end;

    local procedure CopyPurchCommentLines(FromDocumentType: Integer; ToDocumentType: Integer; FromNumber: Code[20]; ToNumber: Code[20])
    var
        PurchCommentLine: Record "Purch. Comment Line";
        PurchCommentLine2: Record "Purch. Comment Line";
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

    local procedure GetItem(SalesLine: Record "Sales Line")
    begin
        WITH SalesLine DO BEGIN
            TESTFIELD(Type, Type::Item);
            TESTFIELD("No.");
            IF "No." <> Item."No." THEN
                Item.GET("No.");
        END;
    end;

    local procedure GetNextSalesline(var SalesLine: Record "Sales Line"): Boolean
    begin
        IF SalesLine.NEXT = 1 THEN
            EXIT(FALSE);
        IF TempPrepaymentSalesLine.FIND('-') THEN BEGIN
            SalesLine := TempPrepaymentSalesLine;
            TempPrepaymentSalesLine.DELETE;
            EXIT(FALSE);
        END;
        EXIT(TRUE);
    end;

    procedure CreatePrepaymentLines(SalesHeader: Record "Sales Header"; var TempPrepmtSalesLine: Record "Sales Line"; var TempDocDim: Record "Document Dimension"; CompleteFunctionality: Boolean)
    var
        GLAcc: Record "15";
        SalesLine: Record "Sales Line";
        DocDim: Record "Document Dimension";
        TempExtTextLine: Record "Extended Text Line" temporary;
        DimMgt: Codeunit "408";
        TransferExtText: Codeunit "378";
        NextLineNo: Integer;
        Fraction: Decimal;
        VATDifference: Decimal;
        TempLineFound: Boolean;
        PrePmtTestRun: Boolean;
    begin
        GLSetup.GET;
        WITH SalesLine DO BEGIN
            SETRANGE("Document Type", SalesHeader."Document Type");
            SETRANGE("Document No.", SalesHeader."No.");
            IF NOT FIND('+') THEN
                EXIT;
            NextLineNo := "Line No." + 10000;
            SETFILTER(Quantity, '>0');
            SETFILTER("Qty. to Invoice", '>0');
            TempPrepmtSalesLine.SetHasBeenShown;
            IF FIND('-') THEN
                REPEAT
                    IF CompleteFunctionality THEN BEGIN
                        IF SalesHeader."Document Type" <> SalesHeader."Document Type"::Invoice THEN BEGIN
                            IF NOT SalesHeader.Ship AND ("Qty. to Invoice" = Quantity - "Quantity Invoiced") THEN
                                Fraction := ("Qty. Shipped Not Invoiced" + "Quantity Invoiced") / Quantity
                            ELSE
                                Fraction := ("Qty. to Invoice" + "Quantity Invoiced") / Quantity;

                            IF (SalesHeader.Ship = FALSE) AND (SalesHeader.Invoice = TRUE) THEN
                                VALIDATE("Qty. to Ship", 0);

                            CASE TRUE OF
                                ("Prepmt Amt to Deduct" <> 0) AND
                              ("Prepmt Amt to Deduct" > ROUND(Fraction * "Line Amount", Currency."Amount Rounding Precision")):
                                    FIELDERROR(
                                      "Prepmt Amt to Deduct",
                                      STRSUBSTNO(Text047,
                                        ROUND(Fraction * "Line Amount", Currency."Amount Rounding Precision")));
                                ("Prepmt. Amt. Inv." <> 0) AND
                              (ROUND((1 - Fraction) * "Line Amount", Currency."Amount Rounding Precision") <
                               ROUND(
                                 ROUND(
                                   ROUND("Unit Price" * (Quantity - "Quantity Invoiced" - "Qty. to Invoice"), Currency."Amount Rounding Precision") *
                                   (1 - ("Line Discount %" / 100)), Currency."Amount Rounding Precision") *
                                 "Prepayment %" / 100, Currency."Amount Rounding Precision")):
                                    FIELDERROR(
                                      "Prepmt Amt to Deduct",
                                      STRSUBSTNO(Text048,
                                        ROUND(
                                          "Prepmt. Amt. Inv." - "Prepmt Amt Deducted" - (1 - Fraction) * "Line Amount",
                                          Currency."Amount Rounding Precision")));
                            END;
                        END ELSE
                            IF NOT PrePmtTestRun THEN BEGIN
                                TestGetShipmentPPmtAmtToDeduct(SalesHeader, SalesLine);
                                PrePmtTestRun := TRUE;
                            END;
                    END;
                    IF "Prepmt Amt to Deduct" <> 0 THEN BEGIN
                        IF ("Gen. Bus. Posting Group" <> GenPostingSetup."Gen. Bus. Posting Group") OR
                           ("Gen. Prod. Posting Group" <> GenPostingSetup."Gen. Prod. Posting Group")
                        THEN BEGIN
                            GenPostingSetup.GET("Gen. Bus. Posting Group", "Gen. Prod. Posting Group");
                            GenPostingSetup.TESTFIELD("Sales Prepayments Account");
                        END;
                        GLAcc.GET(GenPostingSetup."Sales Prepayments Account");
                        TempLineFound := FALSE;
                        IF SalesHeader."Compress Prepayment" THEN BEGIN
                            TempPrepmtSalesLine.SETRANGE("No.", GLAcc."No.");
                            IF TempPrepmtSalesLine.FIND('-') THEN
                                TempLineFound := DocDimMatch(SalesLine, TempPrepmtSalesLine."Line No.", TempDocDim);
                            TempPrepmtSalesLine.SETRANGE("No.");
                        END;
                        IF TempLineFound THEN BEGIN
                            IF SalesHeader."Currency Code" <> '' THEN BEGIN
                                TempPrePayDeductLCYSalesLine := SalesLine;
                                TempPrePayDeductLCYSalesLine."Prepmt. Amount Inv. (LCY)" :=
                                  ROUND(CurrExchRate.ExchangeAmtFCYToLCY(
                                    SalesHeader."Posting Date",
                                    SalesHeader."Currency Code",
                                    TempPrepmtSalesLine."Unit Price" + "Prepmt Amt to Deduct",
                                    SalesHeader."Currency Factor")) -
                                  ROUND(CurrExchRate.ExchangeAmtFCYToLCY(
                                    SalesHeader."Posting Date",
                                    SalesHeader."Currency Code",
                                    TempPrepmtSalesLine."Unit Price",
                                    SalesHeader."Currency Factor"));
                                TempPrePayDeductLCYSalesLine.INSERT;
                            END;
                            VATDifference := TempPrepmtSalesLine."VAT Difference";
                            TempPrepmtSalesLine.VALIDATE(
                              "Unit Price", TempPrepmtSalesLine."Unit Price" + "Prepmt Amt to Deduct");
                            TempPrepmtSalesLine.VALIDATE("VAT Difference", VATDifference - "Prepmt VAT Diff. to Deduct");
                            TempPrepmtSalesLine.MODIFY;
                        END ELSE BEGIN
                            TempPrepmtSalesLine.INIT;
                            TempPrepmtSalesLine."Document Type" := SalesHeader."Document Type";
                            TempPrepmtSalesLine."Document No." := SalesHeader."No.";
                            TempPrepmtSalesLine."Line No." := 0;
                            TempPrepmtSalesLine."System-Created Entry" := TRUE;
                            IF CompleteFunctionality THEN
                                TempPrepmtSalesLine.VALIDATE(Type, TempPrepmtSalesLine.Type::"G/L Account")
                            ELSE
                                TempPrepmtSalesLine.Type := TempPrepmtSalesLine.Type::"G/L Account";
                            TempPrepmtSalesLine.VALIDATE("No.", GenPostingSetup."Sales Prepayments Account");
                            TempPrepmtSalesLine.VALIDATE(Quantity, -1);
                            TempPrepmtSalesLine."Qty. to Ship" := TempPrepmtSalesLine.Quantity;
                            TempPrepmtSalesLine."Qty. to Invoice" := TempPrepmtSalesLine.Quantity;
                            IF SalesHeader."Currency Code" <> '' THEN BEGIN
                                TempPrePayDeductLCYSalesLine := SalesLine;
                                TempPrePayDeductLCYSalesLine."Prepmt. Amount Inv. (LCY)" :=
                                  ROUND(CurrExchRate.ExchangeAmtFCYToLCY(
                                    SalesHeader."Posting Date",
                                    SalesHeader."Currency Code",
                                    "Prepmt Amt to Deduct",
                                    SalesHeader."Currency Factor"));
                                TempPrePayDeductLCYSalesLine.INSERT;
                            END;
                            TempPrepmtSalesLine.VALIDATE("Unit Price", "Prepmt Amt to Deduct");
                            TempPrepmtSalesLine.VALIDATE("VAT Difference", -"Prepmt VAT Diff. to Deduct");
                            TempPrepmtSalesLine."Prepayment Line" := TRUE;
                            TempPrepmtSalesLine."Line No." := NextLineNo;
                            NextLineNo := NextLineNo + 10000;
                            DocDim.SETRANGE("Table ID", DATABASE::"Sales Line");
                            DocDim.SETRANGE("Document Type", "Document Type");
                            DocDim.SETRANGE("Document No.", "Document No.");
                            DocDim.SETRANGE("Line No.", "Line No.");
                            IF DocDim.FIND('-') THEN
                                REPEAT
                                    TempDocDim := DocDim;
                                    TempDocDim."Line No." := TempPrepmtSalesLine."Line No.";
                                    TempDocDim.INSERT;
                                    IF TempDocDim."Dimension Code" = GLSetup."Global Dimension 1 Code" THEN
                                        TempPrepmtSalesLine."Shortcut Dimension 1 Code" := TempDocDim."Dimension Value Code";
                                    IF TempDocDim."Dimension Code" = GLSetup."Global Dimension 2 Code" THEN
                                        TempPrepmtSalesLine."Shortcut Dimension 2 Code" := TempDocDim."Dimension Value Code";
                                UNTIL DocDim.NEXT = 0;
                            TempPrepmtSalesLine.INSERT;
                            TransferExtText.PrepmtGetAnyExtText(
                              TempPrepmtSalesLine."No.", DATABASE::"Sales Invoice Line",
                              SalesHeader."Document Date", SalesHeader."Language Code", TempExtTextLine);
                            IF TempExtTextLine.FIND('-') THEN
                                REPEAT
                                    TempPrepmtSalesLine.INIT;
                                    TempPrepmtSalesLine.Description := TempExtTextLine.Text;
                                    TempPrepmtSalesLine."System-Created Entry" := TRUE;
                                    TempPrepmtSalesLine."Prepayment Line" := TRUE;
                                    TempPrepmtSalesLine."Line No." := NextLineNo;
                                    NextLineNo := NextLineNo + 10000;
                                    TempPrepmtSalesLine.INSERT;
                                UNTIL TempExtTextLine.NEXT = 0;
                        END;
                    END;
                UNTIL NEXT = 0
        END;
    end;

    procedure MergeSaleslines(SalesHeader: Record "Sales Header"; var Salesline: Record "Sales Line"; var Salesline2: Record "Sales Line"; var MergedSalesline: Record "Sales Line")
    begin
        WITH Salesline DO BEGIN
            SETRANGE("Document Type", SalesHeader."Document Type");
            SETRANGE("Document No.", SalesHeader."No.");
            IF FIND('-') THEN
                REPEAT
                    MergedSalesline := Salesline;
                    MergedSalesline.INSERT;
                UNTIL NEXT = 0;
        END;
        WITH Salesline2 DO BEGIN
            SETRANGE("Document Type", SalesHeader."Document Type");
            SETRANGE("Document No.", SalesHeader."No.");
            IF FIND('-') THEN
                REPEAT
                    MergedSalesline := Salesline2;
                    MergedSalesline.INSERT;
                UNTIL NEXT = 0;
        END;
    end;

    local procedure DocDimMatch(SalesLine: Record "Sales Line"; LineNo2: Integer; var TempDocDim: Record "Document Dimension"): Boolean
    var
        DocDim: Record "Document Dimension";
        Found: Boolean;
        Found2: Boolean;
    begin
        WITH DocDim DO BEGIN
            SETRANGE("Table ID", DATABASE::"Sales Line");
            SETRANGE("Document Type", SalesLine."Document Type");
            SETRANGE("Document No.", SalesLine."Document No.");
            SETRANGE("Line No.", SalesLine."Line No.");
            IF NOT FIND('-') THEN
                CLEAR(DocDim);
        END;
        WITH TempDocDim DO BEGIN
            SETRANGE("Table ID", DATABASE::"Sales Line");
            SETRANGE("Document Type", SalesLine."Document Type");
            SETRANGE("Document No.", SalesLine."Document No.");
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

    procedure PostJobContractLine(SalesLine: Record "Sales Line"; var TempJnlLineDim: Record "Gen. Journal Line Dimension")
    begin
        IF SalesLine."Job Contract Entry No." = 0 THEN
            EXIT;
        IF (SalesHeader."Document Type" <> SalesHeader."Document Type"::Invoice) AND
           (SalesHeader."Document Type" <> SalesHeader."Document Type"::"Credit Memo")
        THEN
            SalesLine.TESTFIELD("Job Contract Entry No.", 0);

        SalesLine.TESTFIELD("Job No.");
        SalesLine.TESTFIELD("Job Task No.");

        IF SalesHeader."Document Type" = SalesHeader."Document Type"::Invoice THEN
            SalesLine."Document No." := SalesInvHeader."No.";
        IF SalesHeader."Document Type" = SalesHeader."Document Type"::"Credit Memo" THEN
            SalesLine."Document No." := SalesCrMemoHeader."No.";
        JobPostLine.PostInvoiceContractLine(SalesHeader, SalesLine, TempJnlLineDim);
        JobContractLine := TRUE;
    end;

    local procedure InsertICGenJnlLine(SalesLine: Record "Sales Line")
    var
        ICGLAccount: Record "IC G/L Account";
        Vend: Record Vendor;
        ICPartner: Record "IC Partner";
    begin
        SalesHeader.TESTFIELD("Sell-to IC Partner Code", '');
        SalesHeader.TESTFIELD("Bill-to IC Partner Code", '');
        SalesLine.TESTFIELD("IC Partner Ref. Type", SalesLine."IC Partner Ref. Type"::"G/L Account");
        ICGLAccount.GET(SalesLine."IC Partner Reference");
        ICGenJnlLineNo := ICGenJnlLineNo + 1;
        TempICGenJnlLine.INIT;
        TempICGenJnlLine."Line No." := ICGenJnlLineNo;
        TempICGenJnlLine.VALIDATE("Posting Date", SalesHeader."Posting Date");
        TempICGenJnlLine."Document Date" := SalesHeader."Document Date";
        TempICGenJnlLine.Description := SalesHeader."Posting Description";
        TempICGenJnlLine."Reason Code" := SalesHeader."Reason Code";
        TempICGenJnlLine."Document Type" := GenJnlLineDocType;
        TempICGenJnlLine."Document No." := GenJnlLineDocNo;
        TempICGenJnlLine."External Document No." := GenJnlLineExtDocNo;
        TempICGenJnlLine.VALIDATE("Account Type", TempICGenJnlLine."Account Type"::"IC Partner");
        TempICGenJnlLine.VALIDATE("Account No.", SalesLine."IC Partner Code");
        TempICGenJnlLine."Source Currency Code" := SalesHeader."Currency Code";
        TempICGenJnlLine."Source Currency Amount" := TempICGenJnlLine.Amount;
        TempICGenJnlLine.Correction := SalesHeader.Correction;
        TempICGenJnlLine."Shortcut Dimension 1 Code" := SalesLine."Shortcut Dimension 1 Code";
        TempICGenJnlLine."Shortcut Dimension 2 Code" := SalesLine."Shortcut Dimension 2 Code";
        TempICGenJnlLine."Source Code" := SrcCode;
        TempICGenJnlLine."Country/Region Code" := SalesHeader."VAT Country/Region Code";
        TempICGenJnlLine."Source Type" := GenJnlLine."Source Type"::Customer;
        TempICGenJnlLine."Source No." := SalesHeader."Bill-to Customer No.";
        TempICGenJnlLine."Posting No. Series" := SalesHeader."Posting No. Series";
        TempICGenJnlLine.VALIDATE("Bal. Account Type", TempICGenJnlLine."Bal. Account Type"::"G/L Account");
        TempICGenJnlLine.VALIDATE("Bal. Account No.", SalesLine."No.");
        //APNT-IC1.0
        IF SalesHeader."IC Transaction No." <> 0 THEN BEGIN
            TempICGenJnlLine."IC Transaction No." := SalesHeader."IC Transaction No.";
            TempICGenJnlLine."IC Partner Direction" := SalesHeader."IC Partner Direction";
        END ELSE BEGIN
            TempICGenJnlLine."IC Transaction No." := ICTransactionNo;
            TempICGenJnlLine."IC Partner Direction" := ICDirection;
        END;
        //APNT-IC1.0
        Vend.SETRANGE("IC Partner Code", SalesLine."IC Partner Code");
        IF Vend.FINDFIRST THEN BEGIN
            TempICGenJnlLine.VALIDATE("Bal. Gen. Bus. Posting Group", Vend."Gen. Bus. Posting Group");
            TempICGenJnlLine.VALIDATE("Bal. VAT Bus. Posting Group", Vend."VAT Bus. Posting Group");
        END;
        TempICGenJnlLine."IC Partner Code" := SalesLine."IC Partner Code";
        TempICGenJnlLine."IC Partner G/L Acc. No." := SalesLine."IC Partner Reference";
        TempICGenJnlLine."IC Direction" := TempICGenJnlLine."IC Direction"::Outgoing;
        ICPartner.GET(SalesLine."IC Partner Code");
        IF ICPartner."Cost Distribution in LCY" AND (SalesLine."Currency Code" <> '') THEN BEGIN
            TempICGenJnlLine."Currency Code" := '';
            TempICGenJnlLine."Currency Factor" := 0;
            Currency.GET(SalesLine."Currency Code");
            IF SalesHeader."Document Type" IN
               [SalesHeader."Document Type"::"Return Order", SalesHeader."Document Type"::"Credit Memo"]
            THEN
                TempICGenJnlLine.Amount :=
                  -ROUND(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      SalesHeader."Posting Date", SalesLine."Currency Code",
                      SalesLine.Amount, SalesHeader."Currency Factor"))
            ELSE
                TempICGenJnlLine.Amount :=
                  ROUND(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      SalesHeader."Posting Date", SalesLine."Currency Code",
                      SalesLine.Amount, SalesHeader."Currency Factor"));
        END ELSE BEGIN
            Currency.InitRoundingPrecision;
            TempICGenJnlLine."Currency Code" := SalesHeader."Currency Code";
            TempICGenJnlLine."Currency Factor" := SalesHeader."Currency Factor";
            IF SalesHeader."Document Type" IN [SalesHeader."Document Type"::"Return Order", SalesHeader."Document Type"::"Credit Memo"] THEN
                TempICGenJnlLine.Amount := -SalesLine.Amount
            ELSE
                TempICGenJnlLine.Amount := SalesLine.Amount;
        END;
        IF TempICGenJnlLine."Bal. VAT %" <> 0 THEN
            TempICGenJnlLine.Amount := ROUND(TempICGenJnlLine.Amount * (1 + TempICGenJnlLine."Bal. VAT %" / 100),
                                                   Currency."Amount Rounding Precision");
        TempICGenJnlLine.VALIDATE(Amount);
        TempICGenJnlLine.INSERT;

        TempDocDim.RESET;
        TempDocDim.SETRANGE("Table ID", DATABASE::"Sales Line");
        TempDocDim.SETRANGE("Line No.", SalesLine."Line No.");
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
        ICInOutBoxMgt: Codeunit "427";
        ICTransactionNo: Integer;
        ICPartner: Record "IC Partner";
        ICOutboxTransaction: Record "IC Outbox Transaction";
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

    procedure TestGetShipmentPPmtAmtToDeduct(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line")
    var
        TempSalesLine2: Record "Sales Line";
        TempSalesLine3: Record "Sales Line" temporary;
        OrderNo: Code[20];
        TotalPrePmtAmtToDeduct: Decimal;
        QtyToInv: Decimal;
        LineNo: Decimal;
    begin
        TempSalesLine.SETRANGE("Document Type", SalesHeader."Document Type");
        TempSalesLine.SETRANGE("Document No.", SalesHeader."No.");
        IF NOT TempSalesLine.FIND('+') THEN
            EXIT;
        TempSalesLine.SETFILTER(Quantity, '>0');
        TempSalesLine.SETFILTER("Qty. to Invoice", '>0');
        TempSalesLine.SETFILTER("Shipment No.", '<>%1', '');

        IF TempSalesLine.FINDSET THEN
            REPEAT
                TempSalesLine3 := TempSalesLine;
                TempSalesLine3.INSERT;
            UNTIL TempSalesLine.NEXT = 0;

        IF TempSalesLine.FINDSET THEN
            REPEAT
                IF SalesShptLine.GET(TempSalesLine."Shipment No.", TempSalesLine."Shipment Line No.") THEN BEGIN
                    TempSalesLine2.GET(
                      TempSalesLine."Document Type"::Order,
                      SalesShptLine."Order No.", SalesShptLine."Order Line No.");
                    OrderNo := SalesShptLine."Order No.";
                    LineNo := SalesShptLine."Line No.";

                    IF TempSalesLine3.FINDSET THEN
                        REPEAT
                            IF SalesShptLine.GET(TempSalesLine3."Shipment No.", TempSalesLine3."Shipment Line No.") THEN
                                IF (SalesShptLine."Order No." = OrderNo) AND (SalesShptLine."Line No." = LineNo) THEN BEGIN
                                    QtyToInv := QtyToInv + TempSalesLine3."Qty. to Invoice";
                                    TotalPrePmtAmtToDeduct := TotalPrePmtAmtToDeduct + TempSalesLine3."Prepmt Amt to Deduct";
                                END;
                        UNTIL TempSalesLine3.NEXT = 0;
                    CASE TRUE OF
                        (TotalPrePmtAmtToDeduct > TempSalesLine2."Prepmt. Amt. Inv." - TempSalesLine2."Prepmt Amt Deducted"):
                            ERROR(
                              STRSUBSTNO(Text050,
                                TempSalesLine2.FIELDCAPTION("Prepmt Amt to Deduct"),
                                ROUND(
                                  TempSalesLine2."Prepmt. Amt. Inv." - TempSalesLine2."Prepmt Amt Deducted",
                                  GLSetup."Amount Rounding Precision")));
                        (QtyToInv = TempSalesLine2.Quantity - TempSalesLine2."Quantity Invoiced"):
                            IF NOT (TotalPrePmtAmtToDeduct = TempSalesLine2."Prepmt. Amt. Inv." - TempSalesLine2."Prepmt Amt Deducted") THEN
                                ERROR(
                                  STRSUBSTNO(Text051,
                                    TempSalesLine2.FIELDCAPTION("Prepmt Amt to Deduct"),
                                    ROUND(
                                      TempSalesLine2."Prepmt. Amt. Inv." - TempSalesLine2."Prepmt Amt Deducted",
                                      GLSetup."Amount Rounding Precision")));
                    END;
                    TotalPrePmtAmtToDeduct := 0;
                    QtyToInv := 0;
                END;
            UNTIL TempSalesLine.NEXT = 0;
    end;

    procedure ArchiveUnpostedOrder()
    var
        ArchiveManagement: Codeunit "5063";
    begin
        IF NOT SalesSetup."Archive Quotes and Orders" THEN
            EXIT;
        IF NOT (SalesHeader."Document Type" IN [SalesHeader."Document Type"::Order, SalesHeader."Document Type"::"Return Order"]) THEN
            EXIT;
        SalesLine.RESET;
        SalesLine.SETRANGE("Document Type", SalesHeader."Document Type");
        SalesLine.SETRANGE("Document No.", SalesHeader."No.");
        SalesLine.SETFILTER(Quantity, '<>0');
        IF SalesHeader."Document Type" = SalesHeader."Document Type"::Order THEN BEGIN
            SalesLine.SETRANGE("Quantity Shipped", 0);
            SalesLine.SETFILTER("Qty. to Ship", '<>0');
        END ELSE BEGIN
            SalesLine.SETRANGE("Return Qty. Received", 0);
            SalesLine.SETFILTER("Return Qty. to Receive", '<>0');
        END;
        IF NOT SalesLine.ISEMPTY THEN BEGIN
            ArchiveManagement.ArchSalesDocumentNoConfirm(SalesHeader);
            COMMIT;
        END;
    end;

    procedure PrepayRealizeGainLoss(SalesLine: Record "Sales Line")
    var
        TempJnlLineDim: Record "Gen. Journal Line Dimension" temporary;
        SalesPostPrepayments: Codeunit "442";
    begin
        WITH SalesHeader DO BEGIN
            IF (SalesLine."Prepmt. Amount Inv. (LCY)" <> 0) THEN BEGIN
                GenJnlLine.INIT;
                GenJnlLine."Posting Date" := "Posting Date";
                GenJnlLine."Document Date" := "Document Date";
                GenJnlLine.Description := "Posting Description";
                GenJnlLine."Reason Code" := "Reason Code";
                GenJnlLine."Document Type" := GenJnlLineDocType;
                GenJnlLine."Document No." := GenJnlLineDocNo;
                GenJnlLine."External Document No." := GenJnlLineExtDocNo;
                DocDim.SETRANGE("Table ID", DATABASE::"Sales Line");
                DocDim.SETRANGE("Document Type", "Document Type");
                DocDim.SETRANGE("Document No.", SalesLine."Document No.");
                DocDim.SETRANGE("Line No.", SalesLine."Line No.");
                TempJnlLineDim.RESET;
                TempJnlLineDim.DELETEALL;
                DimMgt.CopyDocDimToJnlLineDim(DocDim, TempJnlLineDim);
                GenJnlLine."Shortcut Dimension 1 Code" := SalesLine."Shortcut Dimension 1 Code";
                GenJnlLine."Shortcut Dimension 2 Code" := SalesLine."Shortcut Dimension 2 Code";
                GenJnlLine."Source Code" := SrcCode;
                GenJnlLine."Source Type" := GenJnlLine."Source Type"::Customer;
                GenJnlLine."Source No." := "Bill-to Customer No.";
                GenJnlLine."Posting No. Series" := "Posting No. Series";
                GenJnlLine."Source Currency Code" := "Currency Code";

                //DP6.01.01 START
                IF "Ref. Document No." <> '' THEN BEGIN
                    GenJnlLine."Ref. Document Type" := "Ref. Document Type";
                    GenJnlLine."Ref. Document No." := "Ref. Document No.";
                END;
                //DP6.01.01 STOP

                SalesPostPrepayments.RealizeGainLoss(GenJnlLine, SalesLine);
                GenJnlPostLine.RunWithCheck(GenJnlLine, TempJnlLineDim);
            END;
        END;
    end;

    procedure SynchBOMSerialNo(var ServItemTmp3: Record "Service Item" temporary; var ServItemTmpCmp3: Record "Service Item Component" temporary)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ItemLedgEntry2: Record "Item Ledger Entry";
        TempSalesShipMntLine: Record "Sales Shipment Line" temporary;
        ServItemTmpCmp4: Record "Service Item Component" temporary;
        ServItemCompLocal: Record "Service Item Component";
        ChildCount: Integer;
        EndLoop: Boolean;
        ItemNumberMatch: Boolean;
    begin
        IF NOT ServItemTmpCmp3.FIND('-') THEN
            EXIT;

        IF NOT ServItemTmp3.FIND('-') THEN
            EXIT;

        TempSalesShipMntLine.DELETEALL;
        REPEAT
            CLEAR(TempSalesShipMntLine);
            TempSalesShipMntLine."Document No." := ServItemTmp3."Sales/Serv. Shpt. Document No.";
            TempSalesShipMntLine."Line No." := ServItemTmp3."Sales/Serv. Shpt. Line No.";
            IF TempSalesShipMntLine.INSERT THEN;
        UNTIL ServItemTmp3.NEXT = 0;

        IF NOT TempSalesShipMntLine.FIND('-') THEN
            EXIT;

        ServItemTmp3.SETCURRENTKEY("Sales/Serv. Shpt. Document No.", "Sales/Serv. Shpt. Line No.");
        CLEAR(ItemLedgEntry);
        ItemLedgEntry.SETCURRENTKEY("Document No.", "Document Type", "Document Line No.");

        REPEAT
            ChildCount := 0;
            ServItemTmpCmp4.DELETEALL;
            ServItemTmp3.SETRANGE("Sales/Serv. Shpt. Document No.", TempSalesShipMntLine."Document No.");
            ServItemTmp3.SETRANGE("Sales/Serv. Shpt. Line No.", TempSalesShipMntLine."Line No.");
            IF ServItemTmp3.FIND('-') THEN
                REPEAT
                    ServItemTmpCmp3.SETRANGE(Active, TRUE);
                    ServItemTmpCmp3.SETRANGE("Parent Service Item No.", ServItemTmp3."No.");
                    IF ServItemTmpCmp3.FIND('-') THEN
                        REPEAT
                            ChildCount += 1;
                            ServItemTmpCmp4 := ServItemTmpCmp3;
                            ServItemTmpCmp4.INSERT;
                        UNTIL ServItemTmpCmp3.NEXT = 0;
                UNTIL ServItemTmp3.NEXT = 0;
            ItemLedgEntry.SETRANGE("Document No.", TempSalesShipMntLine."Document No.");
            ItemLedgEntry.SETRANGE("Document Type", ItemLedgEntry."Document Type"::"Sales Shipment");
            ItemLedgEntry.SETRANGE("Document Line No.", TempSalesShipMntLine."Line No.");
            IF ItemLedgEntry.FIND('-') AND ServItemTmpCmp4.FIND('-') THEN BEGIN
                CLEAR(ItemLedgEntry2);
                ItemLedgEntry2.GET(ItemLedgEntry."Entry No.");
                EndLoop := FALSE;
                ItemNumberMatch := FALSE;
                REPEAT
                    IF ItemLedgEntry2."Item No." = ServItemTmpCmp4."No." THEN BEGIN
                        EndLoop := TRUE;
                        ItemNumberMatch := TRUE;
                    END ELSE
                        IF ItemLedgEntry2.NEXT = 0 THEN
                            EndLoop := TRUE;
                UNTIL EndLoop;
                IF ItemNumberMatch THEN BEGIN
                    ItemLedgEntry2.SETRANGE("Entry No.", ItemLedgEntry2."Entry No.", ItemLedgEntry2."Entry No." + ChildCount - 1);
                    IF ItemLedgEntry2.FIND('-') THEN
                        REPEAT
                            IF ServItemCompLocal.GET(
                                 ServItemTmpCmp4.Active,
                                 ServItemTmpCmp4."Parent Service Item No.",
                                 ServItemTmpCmp4."Line No.")
                            THEN BEGIN
                                IF (ServItemCompLocal."Serial No." = '') AND (ItemLedgEntry2."Serial No." <> '') AND
                                   (ServItemCompLocal."No." = ItemLedgEntry2."Item No.")
                                THEN BEGIN
                                    ServItemCompLocal."Serial No." := ItemLedgEntry2."Serial No.";
                                    ServItemCompLocal.MODIFY;
                                END;
                            END;
                        UNTIL (ItemLedgEntry2.NEXT = 0) OR (ServItemTmpCmp4.NEXT = 0);
                END;
            END;
        UNTIL TempSalesShipMntLine.NEXT = 0;
    end;

    local procedure ItemLedgerEntryExist(SalesLine2: Record "Sales Line"): Boolean
    var
        HasItemLedgerEntry: Boolean;
    begin
        IF SalesHeader.Ship OR SalesHeader.Receive THEN
            // item ledger entry will be created during posting in this transaction
            HasItemLedgerEntry :=
            ((SalesLine2."Qty. to Ship" + SalesLine2."Quantity Shipped") <> 0) OR
            ((SalesLine2."Qty. to Invoice" + SalesLine2."Quantity Invoiced") <> 0) OR
            ((SalesLine2."Return Qty. to Receive" + SalesLine2."Return Qty. Received") <> 0)
        ELSE
            // item ledger entry must already exist
            HasItemLedgerEntry :=
            (SalesLine2."Quantity Shipped" <> 0) OR
            (SalesLine2."Return Qty. Received" <> 0);

        EXIT(HasItemLedgerEntry);
    end;

    procedure SetStatement()
    begin
        //LS
        tempStatement."No." := '1';
        tempStatement.INSERT(FALSE);
    end;

    procedure ShowDialog(): Boolean
    begin
        //LS
        IF NOT GUIALLOWED THEN
            EXIT(FALSE)
        ELSE
            IF gNotShowDialog THEN
                EXIT(FALSE)
            ELSE
                EXIT(TRUE);
    end;

    procedure PostSPOPaymentLines()
    var
        lSPOFromPaymentLines: Record "10012727";
        lSPOToPaymentLines: Record "10012730";
    begin
        //PostSPOPaymentLines
        //LS

        lSPOFromPaymentLines.RESET;
        lSPOFromPaymentLines.SETRANGE("Document Type", SalesHeader."Document Type");
        lSPOFromPaymentLines.SETRANGE("Document No.", SalesLine."Document No.");
        lSPOFromPaymentLines.SETRANGE("Document Line No.", SalesLine."Line No.");
        IF lSPOFromPaymentLines.FINDSET THEN
            REPEAT
                lSPOToPaymentLines.INIT;
                lSPOToPaymentLines.TRANSFERFIELDS(lSPOFromPaymentLines);
                lSPOToPaymentLines."Document No." := SalesInvLine."Document No.";
                lSPOToPaymentLines.INSERT;
            UNTIL (lSPOFromPaymentLines.NEXT = 0);
    end;

    procedure DeleteSPOPaymentLines()
    var
        lSPOPaymentLines: Record "10012727";
    begin
        //DeleteSPOPaymentLines
        //LS

        lSPOPaymentLines.RESET;
        lSPOPaymentLines.SETRANGE("Document Type", SalesHeader."Document Type");
        lSPOPaymentLines.SETRANGE("Document No.", SalesHeader."No.");
        lSPOPaymentLines.DELETEALL;
    end;

    procedure PostSPOOptionTypeValues()
    var
        lOptionTypeValueHeader: Record "10012712";
        lOptionTypeValueEntry: Record "10012713";
        lPstOptionTypeValueHeader: Record "10012728";
        lPstOptionTypeValueEntry: Record "10012729";
        Pos: Integer;
        LineNo: Code[10];
    begin
        //PostSPOOptionTypeValues
        //LS

        IF lPstOptionTypeValueHeader.GET(TempSalesLine."Configuration ID") THEN
            EXIT;

        IF NOT lOptionTypeValueHeader.GET(TempSalesLine."Configuration ID") THEN
            ERROR(Text054, TempSalesLine."Configuration ID");

        lPstOptionTypeValueHeader.INIT;
        lPstOptionTypeValueHeader.TRANSFERFIELDS(lOptionTypeValueHeader);
        lPstOptionTypeValueHeader.INSERT;

        lOptionTypeValueEntry.RESET;
        lOptionTypeValueEntry.SETFILTER("Configuration ID", lOptionTypeValueHeader."Configuration ID");
        IF lOptionTypeValueEntry.FINDSET THEN
            REPEAT
                lPstOptionTypeValueEntry.INIT;
                lPstOptionTypeValueEntry.TRANSFERFIELDS(lOptionTypeValueEntry);
                lPstOptionTypeValueEntry.INSERT(TRUE);
            UNTIL lOptionTypeValueEntry.NEXT = 0;
    end;

    procedure DeleteSPOOptionTypeValues()
    var
        lOptionTypeValueHeader: Record "10012712";
    begin
        //DeleteSPOOptionTypeValues
        //LS

        IF lOptionTypeValueHeader.GET(SalesLine."Configuration ID") THEN
            lOptionTypeValueHeader.DELETE(TRUE); //Deletes Entry lines too.
    end;

    procedure UpdateAgreement(TempSalesAgrmtLine: Record "Sales Line"; NewDocumentNo: Code[20])
    var
        PaymentScheduleLine: Record "Payment Schedule Lines";
        AgrmtLine: Record "Agreement Line";
    begin
        //DP6.01.01 START
        PaymentScheduleLine.SETCURRENTKEY("Agreement Type", "Agreement No.", "Agreement Line No.", "Due Date");
        PaymentScheduleLine.SETRANGE("Agreement Type", TempSalesAgrmtLine."Ref. Document Type");
        PaymentScheduleLine.SETRANGE("Agreement No.", TempSalesAgrmtLine."Ref. Document No.");
        PaymentScheduleLine.SETRANGE("Agreement Line No.", TempSalesAgrmtLine."Ref. Document Line No.");
        PaymentScheduleLine.SETRANGE("Due Date", TempSalesAgrmtLine."Agreement Due Date");
        IF TempSalesAgrmtLine."Document Type" = TempSalesAgrmtLine."Document Type"::Invoice THEN BEGIN
            PaymentScheduleLine.SETRANGE("Invoice No.", TempSalesAgrmtLine."Document No.");
            IF PaymentScheduleLine.FINDFIRST THEN BEGIN
                PaymentScheduleLine."Invoice No." := '';
                PaymentScheduleLine."Posted Invoice No." := NewDocumentNo;
                PaymentScheduleLine.MODIFY(TRUE);
            END;
        END ELSE
            IF TempSalesAgrmtLine."Document Type" = TempSalesAgrmtLine."Document Type"::"Credit Memo" THEN BEGIN
                PaymentScheduleLine.SETRANGE("Credit Memo No.", TempSalesAgrmtLine."Document No.");
                IF PaymentScheduleLine.FINDFIRST THEN BEGIN
                    PaymentScheduleLine."Credit Memo No." := '';
                    PaymentScheduleLine."Posted Invoice No." := '';
                    PaymentScheduleLine."Posted Cr. Memo No." := NewDocumentNo;
                    PaymentScheduleLine.MODIFY(TRUE);
                END;
            END;
        //DP6.01.01 STOP
    end;

    procedure CreateBinLedgerEntries(RecSalesHdr: Record "Sales Header"; SalesCrMemo: Record "Sales Cr.Memo Header")
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
        CheckBinMandatory(RecSalesHdr);
        CLEAR(EntryNo);
        BinLedgersEntryNo.RESET;
        IF BinLedgersEntryNo.FINDLAST THEN
            EntryNo := BinLedgersEntryNo."Entry No." + 1
        ELSE
            EntryNo := 1;

        DocumentBin.RESET;
        DocumentBin.SETRANGE(Type, DocumentBin.Type::"Credit Memo");
        DocumentBin.SETRANGE("Document Type", DocumentBin."Document Type"::"Credit Memo");
        DocumentBin.SETRANGE("Document No.", RecSalesHdr."No.");
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
                DocumentBinCpy."Sales Cr. Memo No." := SalesCrMemo."No.";
                DocumentBinCpy."Posting date" := RecSalesHdr."Posting Date";
                DocumentBinCpy.MODIFY;
            UNTIL DocumentBin.NEXT = 0;
        //APNT-T009914
    end;

    procedure CheckBinMandatory(RecSHrd: Record "Sales Header")
    var
        RecSalesLine: Record "Sales Line";
        RecLocation: Record Location;
        RecItem: Record Item;
        RecDoBin: Record "50082";
    begin
        //APNT-T009914
        WITH RecSHrd DO BEGIN
            TESTFIELD("Location Code");
            CLEAR(RecLocation);
            IF RecLocation.GET(RecSHrd."Location Code") THEN;
            RecSalesLine.RESET;
            RecSalesLine.SETRANGE("Document Type", RecSHrd."Document Type");
            RecSalesLine.SETRANGE("Document No.", RecSHrd."No.");
            RecSalesLine.SETRANGE(Type, RecSalesLine.Type::Item);
            IF RecSalesLine.FINDFIRST THEN
                REPEAT
                    CLEAR(RecItem);
                    IF RecItem.GET(RecSalesLine."No.") THEN;
                    IF (RecLocation."WMS Active" = TRUE) AND (RecItem."WMS Active" = TRUE) THEN BEGIN
                        RecDoBin.RESET;
                        RecDoBin.SETRANGE("Document No.", RecSalesLine."Document No.");
                        RecDoBin.SETRANGE("Barcode No.", RecSalesLine.Barcode);
                        RecDoBin.SETRANGE("Location Code", RecSalesLine."Location Code");
                        RecDoBin.SETRANGE(Posted, FALSE);
                        IF NOT RecDoBin.FINDFIRST THEN BEGIN
                            IF RecSalesLine."Return Qty. to Receive" <> 0 THEN
                                ERROR('There should be atleast one Bin code for the Barcode %1', RecSalesLine.Barcode)
                        END ELSE BEGIN
                            IF RecSalesLine."Return Qty. to Receive" <> 0 THEN BEGIN
                                IF RecDoBin."Bin Code" = '' THEN
                                    ERROR('There should be atleast one Bin code for the Barcode %1', RecSalesLine.Barcode)
                            END;
                        END;
                    END;
                UNTIL RecSalesLine.NEXT = 0;
        END;
    end;

    procedure CreateBinLedgerEntriesSReturn(RecSalesHdr: Record "Sales Header"; ReturnReceiptHdr: Record "Return Receipt Header")
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
        CheckBinMandatory(RecSalesHdr);
        CLEAR(EntryNo);
        BinLedgersEntryNo.RESET;
        IF BinLedgersEntryNo.FINDLAST THEN
            EntryNo := BinLedgersEntryNo."Entry No." + 1
        ELSE
            EntryNo := 1;

        DocumentBin.RESET;
        DocumentBin.SETRANGE(Type, DocumentBin.Type::"Sales Return");
        DocumentBin.SETRANGE("Document Type", DocumentBin."Document Type"::"Return Order");
        DocumentBin.SETRANGE("Document No.", RecSalesHdr."No.");
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
                DocumentBinCpy."Posting date" := RecSalesHdr."Posting Date";
                DocumentBinCpy.MODIFY;
            UNTIL DocumentBin.NEXT = 0;
        //APNT-T009914
    end;

    procedure CheckBinMandatorySReturn(RecSHrd: Record "Sales Header")
    var
        RecSalesLine: Record "Sales Line";
        RecLocation: Record Location;
        RecItem: Record Item;
        RecDoBin: Record "50082";
    begin
        //APNT-T009914
        WITH RecSHrd DO BEGIN
            TESTFIELD("Location Code");
            CLEAR(RecLocation);
            IF RecLocation.GET(RecSHrd."Location Code") THEN;
            RecSalesLine.RESET;
            RecSalesLine.SETRANGE("Document Type", RecSHrd."Document Type");
            RecSalesLine.SETRANGE("Document No.", RecSHrd."No.");
            RecSalesLine.SETRANGE(Type, RecSalesLine.Type::Item);
            IF RecSalesLine.FINDFIRST THEN
                REPEAT
                    CLEAR(RecItem);
                    IF RecItem.GET(RecSalesLine."No.") THEN;
                    IF (RecLocation."WMS Active" = TRUE) AND (RecItem."WMS Active" = TRUE) THEN BEGIN
                        RecDoBin.RESET;
                        RecDoBin.SETRANGE("Document No.", RecSalesLine."Document No.");
                        RecDoBin.SETRANGE("Barcode No.", RecSalesLine.Barcode);
                        RecDoBin.SETRANGE("Location Code", RecSalesLine."Location Code");
                        RecDoBin.SETRANGE(Posted, FALSE);
                        IF NOT RecDoBin.FINDFIRST THEN BEGIN
                            IF RecSalesLine."Return Qty. to Receive" <> 0 THEN
                                ERROR('There should be atleast one Bin code for the Barcode %1', RecSalesLine.Barcode)
                        END ELSE BEGIN
                            IF RecSalesLine."Return Qty. to Receive" <> 0 THEN BEGIN
                                IF RecDoBin."Bin Code" = '' THEN
                                    ERROR('There should be atleast one Bin code for the Barcode %1', RecSalesLine.Barcode)
                            END;
                        END;
                    END;
                UNTIL RecSalesLine.NEXT = 0;
        END;
    end;

    procedure CreateVATSalesInvoiceEntries(RecSH: Record "Sales Header")
    var
        PremiseSetup: Record "Premise Management Setup";
        RecSalesLines: Record "Sales Line";
        GeneralPostingSetup: Record "252";
        TempJnlLineDim: Record "Gen. Journal Line Dimension" temporary;
    begin
        PremiseSetup.GET;

        IF (RecSH."Document Type" <> RecSH."Document Type"::Invoice) THEN
            EXIT;

        IF RecSH."Reason Code" = '' THEN
            EXIT;

        IF (RecSH."Reason Code" <> PremiseSetup."Reason Code") THEN
            EXIT;

        GeneralPostingSetup.GET(PremiseSetup."Gen. Bus. Posting Group", PremiseSetup."Gen. Prod. Posting Group");
        WITH RecSH DO BEGIN
            RecSH.CALCFIELDS(Amount);

            GenJnlLine.INIT;
            GenJnlLine."Posting Date" := "Posting Date";
            GenJnlLine."Document Date" := "Document Date";
            GenJnlLine.Description := 'VAT INVOICE CONTRA';  //"Posting Description" + '-Reversal';
            GenJnlLine."Shortcut Dimension 1 Code" := "Shortcut Dimension 1 Code";
            GenJnlLine."Shortcut Dimension 2 Code" := "Shortcut Dimension 2 Code";
            GenJnlLine."Reason Code" := "Reason Code";
            GenJnlLine."Account Type" := GenJnlLine."Account Type"::Customer;
            GenJnlLine."Account No." := "Bill-to Customer No.";
            //GenJnlLine."Document Type"       := GenJnlLine."Document Type"::Invoice;  //GenJnlLineDocType;  APNT 10Jan18
            GenJnlLine."Document No." := GenJnlLineDocNo;
            GenJnlLine."External Document No." := GenJnlLineExtDocNo;
            GenJnlLine."Currency Code" := "Currency Code";
            GenJnlLine.Amount := -Amount;
            GenJnlLine."Source Currency Code" := "Currency Code";
            GenJnlLine."Source Currency Amount" := -Amount;
            GenJnlLine."Amount (LCY)" := -Amount;
            IF SalesHeader."Currency Code" = '' THEN
                GenJnlLine."Currency Factor" := 1
            ELSE
                GenJnlLine."Currency Factor" := "Currency Factor";
            GenJnlLine.Correction := Correction;
            GenJnlLine."Bal. Account No." := GeneralPostingSetup."Sales Account";
            GenJnlLine."Sell-to/Buy-from No." := "Sell-to Customer No.";
            GenJnlLine."Bill-to/Pay-to No." := "Bill-to Customer No.";
            GenJnlLine."Salespers./Purch. Code" := "Salesperson Code";
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
            GenJnlLine."Source Type" := GenJnlLine."Source Type"::Customer;
            GenJnlLine."Source No." := "Bill-to Customer No.";
            GenJnlLine."Source Code" := SrcCode;
            GenJnlLine."Posting No. Series" := "Posting No. Series";
            GenJnlLine."IC Partner Code" := "Sell-to IC Partner Code";
            GenJnlLine."Batch No." := "Batch No.";  //LS
                                                    // GenJnlLine."Gen. Posting Type"       := GenJnlLine."Gen. Posting Type"::Sale;
                                                    //  GenJnlLine."Gen. Bus. Posting Group" := PremiseSetup."Gen. Bus. Posting Group";
                                                    //GenJnlLine."Gen. Prod. Posting Group" :=PremiseSetup."Gen. Prod. Posting Group";

            //DP6.01.01 START
            IF "Ref. Document No." <> '' THEN BEGIN
                GenJnlLine."Ref. Document Type" := "Ref. Document Type";
                GenJnlLine."Ref. Document No." := "Ref. Document No.";
            END;
            //DP6.01.01 STOP

            GenJnlLine."Recurring Method" := 1; //APNT
                                                //-----------APNT 14JAN18
            GenJnlLine.VALIDATE("Applies-to Doc. Type", GenJnlLine."Applies-to Doc. Type"::Invoice);
            GenJnlLine.VALIDATE("Applies-to Doc. No.", GenJnlLineDocNo);

            //-----------APNT 14JAN18
            TempJnlLineDim.DELETEALL;
            TempDocDim.RESET;
            TempDocDim.SETRANGE("Table ID", DATABASE::"Sales Header");
            DimMgt.CopyDocDimToJnlLineDim(TempDocDim, TempJnlLineDim);
            GenJnlPostLine.RunWithCheck(GenJnlLine, TempJnlLineDim);

        END;
    end;
}

