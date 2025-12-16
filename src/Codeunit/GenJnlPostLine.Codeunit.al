codeunit 12 "Gen. Jnl.-Post Line"
{
    // LS = changes made by LS Retail
    // Code        Date      Name            Description
    // APNT-IBU1.0 03.08.11  Tanweer         Added code for IBU Customization
    // APNT-AT1.0  07.09.11  Tanweer         Added code for Asset Transfer Customization
    // APNT-FIN1.0 08.09.11  Tanweer         Added code for Finance Customization
    // APNT-CP1.0  28.09.11  Sangeeta        Added code for Closed Period
    // APNT-IC1.0  16.02.12  Tanweer         Added code for IC Customization
    // APNT-IC1.1  30.05.12  Shameema        Added code for IC Customization - Fix Direct Posting
    // APNT-IBU1.1 05.06.12  Shameema        Added code for Balancing IBU Entries Update function
    // APNT-LM1.0  08.07.12  Shameema        Added code for Lease Customization
    // APNT-2.0    27.08.12  Tanweer         Added code to pass Ship-to Code to Cust. Ledg. Entry
    // DP = changes made by DVS
    // APNT-HR1.0  12.11.13  Sangeeta        Added code for HR & Payroll Customization.
    // T002747     12.02.14  Tanweer         Added code for LG Specific IC Jnl. Customization.
    // LG00.02 20032014 Changes done for Reversal of PDC Transaction with Reason Code
    // 
    // APNT-DT1.0   18.10.15  Ashish          Added code for Date Time
    // APNT-T009612 29.02.16  Sujith          Added code for lease management customization.
    // APNT-T011400 11.08.16  Sangeeta        Added code to update the Entry status to posted in Check ledger
    //                                        entry while posting the check.
    // APNT-VAT1.1  27.06.19  Sujith          VAT Issue fix - automatic vat amount getting calculated for blank "VAT Bus. Posting Group",
    //                                        "VAT Prod. Posting Group".
    // APNT-PV1.0   02.07.19  Sujith          Added code for payment voucher customization
    // GC-LALS                Ganesh           Invoice recive date filed flowing to ledger tables
    // T033564      24.06.20  Sujith          Added conditon to pick the external document no.
    // T044145      13.07.22  Sujith          Added code for CRF_22_0859

    Permissions = TableData 17 = imd,
                  TableData 21 = imd,
                  TableData 25 = imd,
                  TableData 45 = imd,
                  TableData 253 = rimd,
                  TableData 254 = imd,
                  TableData 271 = imd,
                  TableData 272 = imd,
                  TableData 379 = imd,
                  TableData 380 = imd,
                  TableData 5601 = rimd,
                  TableData 5617 = imd,
                  TableData 5625 = rimd;
    TableNo = 81;

    trigger OnRun()
    var
        TempJnlLineDim2: Record "Gen. Journal Line Dimension" temporary;
    begin
        GLSetup.GET;
        TempJnlLineDim2.RESET;
        TempJnlLineDim2.DELETEALL;
        IF "Shortcut Dimension 1 Code" <> '' THEN BEGIN
            TempJnlLineDim2."Table ID" := DATABASE::"Gen. Journal Line";
            TempJnlLineDim2."Journal Template Name" := "Journal Template Name";
            TempJnlLineDim2."Journal Batch Name" := "Journal Batch Name";
            TempJnlLineDim2."Journal Line No." := "Line No.";
            TempJnlLineDim2."Dimension Code" := GLSetup."Global Dimension 1 Code";
            TempJnlLineDim2."Dimension Value Code" := "Shortcut Dimension 1 Code";
            TempJnlLineDim2.INSERT;
        END;
        IF "Shortcut Dimension 2 Code" <> '' THEN BEGIN
            TempJnlLineDim2."Table ID" := DATABASE::"Gen. Journal Line";
            TempJnlLineDim2."Journal Template Name" := "Journal Template Name";
            TempJnlLineDim2."Journal Batch Name" := "Journal Batch Name";
            TempJnlLineDim2."Journal Line No." := "Line No.";
            TempJnlLineDim2."Dimension Code" := GLSetup."Global Dimension 2 Code";
            TempJnlLineDim2."Dimension Value Code" := "Shortcut Dimension 2 Code";
            TempJnlLineDim2.INSERT;
        END;
        //APNT-HR1.0
        UpdateShortcutDimCodes(Rec, TempJnlLineDim2);
        //APNT-HR1.0
        RunWithCheck(Rec, TempJnlLineDim2);
    end;

    var
        Text000: Label '%1 needs to be rounded';
        Text001: Label 'Sales %1 %2 already exists.';
        Text002: Label 'Purchase %1 %2 already exists.';
        Text003: Label 'Purchase %1 %2 already exists for this vendor.';
        Text004: Label 'must not be filled when %1 is different in %2 and %3.';
        Text005: Label ' must be entered when %1 is %2';
        Text006: Label 'Check %1 already exists for this Bank Account.';
        GLSetup: Record "General Ledger Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        PurchSetup: Record "Purchases & Payables Setup";
        AccountingPeriod: Record "Accounting Period";
        GLAcc: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        GLEntryTmp: Record "G/L Entry" temporary;
        TempGLEntryVAT: Record "G/L Entry" temporary;
        OrigGLEntry: Record "G/L Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        Cust: Record Customer;
        Vend: Record Vendor;
        GenJnlLine: Record "Gen. Journal Line";
        TempJnlLineDim: Record "Gen. Journal Line Dimension" temporary;
        TempFAJnlLineDim: Record "Gen. Journal Line Dimension" temporary;
        GLReg: Record "G/L Register";
        CustPostingGr: Record "92";
        VendPostingGr: Record "93";
        Currency: Record "4";
        AddCurrency: Record "4";
        ApplnCurrency: Record "4";
        CurrExchRate: Record "330";
        VATEntry: Record "254";
        BankAcc: Record "270";
        BankAccLedgEntry: Record "271";
        CheckLedgEntry: Record "272";
        CheckLedgEntry2: Record "272";
        BankAccPostingGr: Record "277";
        GenJnlTemplate: Record "80";
        TaxJurisdiction: Record "320";
        TaxDetail: Record "322";
        FAGLPostBuf: Record "5637" temporary;
        UnrealizedCustLedgEntry: Record "21";
        UnrealizedVendLedgEntry: Record "25";
        GLEntryVatEntrylink: Record "253";
        TempVatEntry: Record "254" temporary;
        ReversedGLEntryTemp: Record "G/L Entry" temporary;
        InitEntryNoInStore: Record "99001469";
        GenJnlCheckLine: Codeunit "11";
        ExchAccGLJnlLine: Codeunit "366";
        FAJnlPostLine: Codeunit "5632";
        SalesTaxCalculate: Codeunit "398";
        GenJnlApply: Codeunit "225";
        DimMgt: Codeunit "408";
        JobPostLine: Codeunit "1001";
        FiscalYearStartDate: Date;
        NextEntryNo: Integer;
        BalanceCheckAmount: Decimal;
        BalanceCheckAmount2: Decimal;
        BalanceCheckAddCurrAmount: Decimal;
        BalanceCheckAddCurrAmount2: Decimal;
        CurrentBalance: Decimal;
        SalesTaxBaseAmount: Decimal;
        TotalAddCurrAmount: Decimal;
        TotalAmount: Decimal;
        UnrealizedRemainingAmountCust: Decimal;
        UnrealizedRemainingAmountVend: Decimal;
        NextVATEntryNo: Integer;
        FirstNewVATEntryNo: Integer;
        NextTransactionNo: Integer;
        NextConnectionNo: Integer;
        InsertedTempGLEntryVAT: Integer;
        LastDocNo: Code[20];
        LastLineNo: Integer;
        LastDate: Date;
        LastDocType: Option " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder;
        NextCheckEntryNo: Integer;
        AddCurrGLEntryVATAmt: Decimal;
        StartDate: Date;
        CurrencyDate: Date;
        CurrencyFactor: Decimal;
        UseCurrFactorOnly: Boolean;
        NonAddCurrCodeOccured: Boolean;
        FADimAlreadyChecked: Boolean;
        Text010: Label 'Residual caused by rounding of %1';
        Text013: Label 'A dimension used in %1 %2, %3, %4 has caused an error. %5';
        Text014: Label 'Reversal found a %1 without a matching %2.';
        Text015: Label 'You cannot reverse the transaction, because it has already been reversed.';
        Text011: Label 'The combination of dimensions used in %1 %2 is blocked. %3';
        AllApplied: Boolean;
        OverrideDimErr: Boolean;
        JobLine: Boolean;
        Prepayment: Boolean;
        CheckUnrealizedCust: Boolean;
        CheckUnrealizedVend: Boolean;
        ICTProcesses: Codeunit "10001416";
        Inserted: Boolean;
        CustLedgEntryRec2: Record "21";
        VendLedgEntryRec2: Record "25";
        ReverseReason: Code[20];
        GenJnlLine3: Record "Gen. Journal Line";
        LASTLINES: Integer;
        CompanyInformation: Record "79";

    procedure GetGLReg(var NewGLReg: Record "G/L Register")
    begin
        NewGLReg := GLReg;
    end;

    procedure RunWithCheck(var GenJnlLine2: Record "Gen. Journal Line"; var TempJnlLineDim2: Record "Gen. Journal Line Dimension")
    begin
        //TEMP-SP
        CLEAR(LASTLINES);
        GenJnlLine3.RESET;
        GenJnlLine3.SETRANGE("Journal Template Name", 'DEFAULT');
        GenJnlLine3.SETRANGE("Journal Batch Name", 'DEFAULT');
        IF GenJnlLine3.FINDLAST THEN
            LASTLINES := GenJnlLine3."Line No.";

        GenJnlLine3.INIT;
        GenJnlLine3.COPY(GenJnlLine2);
        GenJnlLine3."Journal Template Name" := 'DEFAULT';
        GenJnlLine3."Journal Batch Name" := 'DEFAULT';
        GenJnlLine3."Line No." := LASTLINES + 1;
        GenJnlLine3.INSERT;
        //TEMP-SP

        GenJnlLine.COPY(GenJnlLine2);
        TempJnlLineDim.RESET;
        TempJnlLineDim.DELETEALL;
        DimMgt.CopyJnlLineDimToJnlLineDim(TempJnlLineDim2, TempJnlLineDim);
        Code(TRUE);
        GenJnlLine2 := GenJnlLine;
    end;

    procedure RunWithoutCheck(var GenJnlLine2: Record "Gen. Journal Line"; var TempJnlLineDim2: Record "Gen. Journal Line Dimension")
    begin
        GenJnlLine.COPY(GenJnlLine2);
        TempJnlLineDim.RESET;
        TempJnlLineDim.DELETEALL;
        DimMgt.CopyJnlLineDimToJnlLineDim(TempJnlLineDim2, TempJnlLineDim);
        Code(FALSE);
        GenJnlLine2 := GenJnlLine;
    end;

    local procedure "Code"(CheckLine: Boolean)
    var
        GenJnlLineRec: Record "Gen. Journal Line";
        PDCMgt: Codeunit "33016806";
        PostedPayrollSmtLines: Record "60085";
    begin
        WITH GenJnlLine DO BEGIN
            IF EmptyLine THEN BEGIN
                LastDocType := "Document Type";
                LastDocNo := "Document No.";
                LastLineNo := "Line No.";
                LastDate := "Posting Date";
                EXIT;
            END;

            //LS -
            ICTProcesses.GLJnlLineMirror(GenJnlLine, TempJnlLineDim);
            ICTProcesses.GLJnlLineTransfer(GenJnlLine, TempJnlLineDim);
            //LS +

            IF CheckLine THEN BEGIN
                IF OverrideDimErr THEN
                    GenJnlCheckLine.SetOverDimErr;
                GenJnlCheckLine.RunCheck(GenJnlLine, TempJnlLineDim);
            END;
            IF "Currency Code" = '' THEN BEGIN
                Currency.InitRoundingPrecision;
                "Amount (LCY)" := Amount;
                "VAT Amount (LCY)" := "VAT Amount";
                "VAT Base Amount (LCY)" := "VAT Base Amount";
            END ELSE BEGIN
                Currency.GET("Currency Code");
                Currency.TESTFIELD("Amount Rounding Precision");
                IF NOT "System-Created Entry" THEN BEGIN
                    "Source Currency Code" := "Currency Code";
                    "Source Currency Amount" := Amount;
                    "Source Curr. VAT Base Amount" := "VAT Base Amount";
                    "Source Curr. VAT Amount" := "VAT Amount";
                END;
            END;
            IF "Additional-Currency Posting" = "Additional-Currency Posting"::None THEN BEGIN
                IF Amount <> ROUND(Amount, Currency."Amount Rounding Precision") THEN
                    FIELDERROR(
                      Amount,
                      STRSUBSTNO(Text000, Amount));
                IF "Amount (LCY)" <> ROUND("Amount (LCY)") THEN
                    FIELDERROR(
                      "Amount (LCY)",
                      STRSUBSTNO(Text000, "Amount (LCY)"));
            END;

            IF ("Bill-to/Pay-to No." = '') THEN
                CASE TRUE OF
                    "Account Type" IN ["Account Type"::Customer, "Account Type"::Vendor]:
                        "Bill-to/Pay-to No." := "Account No.";
                    "Bal. Account Type" IN ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor]:
                        "Bill-to/Pay-to No." := "Bal. Account No.";
                END;
            IF "Document Date" = 0D THEN
                "Document Date" := "Posting Date";
            IF "Due Date" = 0D THEN
                "Due Date" := "Posting Date";

            JobLine := (GenJnlLine."Job No." <> '');

            InitCodeUnit;

            IF ("Account No." <> '') AND ("Bal. Account No." <> '') AND (NOT "System-Created Entry") AND
               ("Account Type" IN
                ["Account Type"::Customer,
                 "Account Type"::Vendor,
                 "Account Type"::"Fixed Asset"])
            THEN
                ExchAccGLJnlLine.RUN(GenJnlLine);

            //APNT-IC1.0
            IF GenJnlLine."IC Partner Code" <> '' THEN BEGIN
                IF GenJnlLine."IC Partner Direction" <> GenJnlLine."IC Partner Direction"::" " THEN BEGIN
                    GenJnlLineRec.RESET;
                    GenJnlLineRec.SETRANGE("Journal Template Name", "Journal Template Name");
                    GenJnlLineRec.SETRANGE("Journal Batch Name", "Journal Batch Name");
                    GenJnlLineRec.SETRANGE("Document No.", "Doc. No. Before Posting");
                    IF GenJnlLineRec.FINDFIRST THEN BEGIN
                        GenJnlLineRec.MODIFYALL("IC Transaction No.", "IC Transaction No.");
                        GenJnlLineRec.MODIFYALL("IC Partner Direction", "IC Partner Direction");
                    END;
                END;
            END;
            //APNT-IC1.0

            //DP6.01.01 START
            IF (GenJnlLine."Ref. Document No." <> '') AND (GenJnlLine."Applied Agrmt. Amount" <> 0) THEN BEGIN
                PDCMgt.PostedAppliedAgrmtEntries(GenJnlLine);
            END;
            //DP6.01.01 STOP

            IF "Account No." <> '' THEN
                CASE "Account Type" OF
                    "Account Type"::"G/L Account":
                        PostGLAcc;
                    "Account Type"::Customer:
                        PostCust;
                    "Account Type"::Vendor:
                        PostVend;
                    "Account Type"::"Bank Account":
                        PostBankAcc;
                    "Account Type"::"Fixed Asset":
                        PostFixedAsset;
                    "Account Type"::"IC Partner":
                        PostICPartner;
                END;

            IF "Bal. Account No." <> '' THEN BEGIN
                ExchAccGLJnlLine.RUN(GenJnlLine);
                IF "Account No." <> '' THEN
                    CASE "Account Type" OF
                        "Account Type"::"G/L Account":
                            PostGLAcc;
                        "Account Type"::Customer:
                            PostCust;
                        "Account Type"::Vendor:
                            PostVend;
                        "Account Type"::"Bank Account":
                            PostBankAcc;
                        "Account Type"::"Fixed Asset":
                            PostFixedAsset;
                        "Account Type"::"IC Partner":
                            PostICPartner;
                    END;
            END;

            //T002747
            IF ("Payroll Open Statement No." <> '') AND ("Payroll Open Stmt. Line No." <> 0) THEN BEGIN
                PostedPayrollSmtLines.RESET;
                PostedPayrollSmtLines.SETRANGE("Statement No.", "Payroll Open Statement No.");
                PostedPayrollSmtLines.SETRANGE("Line No.", "Payroll Open Stmt. Line No.");
                IF PostedPayrollSmtLines.FINDFIRST THEN BEGIN
                    PostedPayrollSmtLines."IC Journal Posted" := TRUE;
                    PostedPayrollSmtLines.MODIFY;
                END;
            END;
            //T002747

            FinishCodeunit;
        END;
    end;

    procedure InitVat()
    var
        LCYCurrency: Record "4";
    begin
        LCYCurrency.InitRoundingPrecision;
        WITH GenJnlLine DO
            IF "Gen. Posting Type" <> 0 THEN BEGIN // None
                CLEAR(VATPostingSetup); //APNT-VAT1.1
                IF VATPostingSetup.GET("VAT Bus. Posting Group", "VAT Prod. Posting Group") THEN;//APNT-VAT1.0
                TESTFIELD("VAT Calculation Type", VATPostingSetup."VAT Calculation Type");
                CASE "VAT Posting" OF
                    "VAT Posting"::"Automatic VAT Entry":
                        BEGIN
                            GLEntry."Gen. Bus. Posting Group" := "Gen. Bus. Posting Group";
                            GLEntry."Gen. Prod. Posting Group" := "Gen. Prod. Posting Group";
                            GLEntry."VAT Bus. Posting Group" := "VAT Bus. Posting Group";
                            GLEntry."VAT Prod. Posting Group" := "VAT Prod. Posting Group";
                            GLEntry."Reason Code" := "Reason Code";  //LS
                            GLEntry."Tax Area Code" := "Tax Area Code";
                            GLEntry."Tax Liable" := "Tax Liable";
                            GLEntry."Tax Group Code" := "Tax Group Code";
                            GLEntry."Use Tax" := "Use Tax";
                            CASE "VAT Calculation Type" OF
                                "VAT Calculation Type"::"Normal VAT":
                                    BEGIN
                                        IF "VAT Difference" <> 0 THEN BEGIN
                                            GLEntry.Amount := "VAT Base Amount (LCY)";
                                            GLEntry."VAT Amount" := "Amount (LCY)" - GLEntry.Amount;
                                            GLEntry."Additional-Currency Amount" := "Source Curr. VAT Base Amount";
                                            IF "Source Currency Code" = GLSetup."Additional Reporting Currency" THEN
                                                AddCurrGLEntryVATAmt := "Source Curr. VAT Amount"
                                            ELSE
                                                AddCurrGLEntryVATAmt := CalcLCYToAddCurr(GLEntry."VAT Amount");
                                        END ELSE BEGIN
                                            GLEntry."VAT Amount" :=
                                              ROUND(
                                                "Amount (LCY)" * VATPostingSetup."VAT %" / (100 + VATPostingSetup."VAT %"),
                                                LCYCurrency."Amount Rounding Precision", LCYCurrency.VATRoundingDirection);
                                            GLEntry.Amount := "Amount (LCY)" - GLEntry."VAT Amount";
                                            IF "Source Currency Code" = GLSetup."Additional Reporting Currency" THEN
                                                AddCurrGLEntryVATAmt :=
                                                  ROUND(
                                                    "Source Currency Amount" * VATPostingSetup."VAT %" / (100 + VATPostingSetup."VAT %"),
                                                    AddCurrency."Amount Rounding Precision", AddCurrency.VATRoundingDirection)
                                            ELSE
                                                AddCurrGLEntryVATAmt := CalcLCYToAddCurr(GLEntry."VAT Amount");
                                            GLEntry."Additional-Currency Amount" := "Source Currency Amount" - AddCurrGLEntryVATAmt;
                                        END;
                                    END;
                                "VAT Calculation Type"::"Reverse Charge VAT":
                                    CASE "Gen. Posting Type" OF
                                        "Gen. Posting Type"::Purchase:
                                            BEGIN
                                                IF "VAT Difference" <> 0 THEN BEGIN
                                                    GLEntry."VAT Amount" := "VAT Amount (LCY)";
                                                    IF "Source Currency Code" = GLSetup."Additional Reporting Currency" THEN
                                                        AddCurrGLEntryVATAmt := "Source Curr. VAT Amount"
                                                    ELSE
                                                        AddCurrGLEntryVATAmt := CalcLCYToAddCurr(GLEntry."VAT Amount");
                                                END ELSE BEGIN
                                                    GLEntry."VAT Amount" :=
                                                      ROUND(
                                                        GLEntry.Amount * VATPostingSetup."VAT %" / 100,
                                                        LCYCurrency."Amount Rounding Precision", LCYCurrency.VATRoundingDirection);
                                                    IF "Source Currency Code" = GLSetup."Additional Reporting Currency" THEN
                                                        AddCurrGLEntryVATAmt :=
                                                          ROUND(
                                                            GLEntry."Additional-Currency Amount" * VATPostingSetup."VAT %" / 100,
                                                            AddCurrency."Amount Rounding Precision", AddCurrency.VATRoundingDirection)
                                                    ELSE
                                                        AddCurrGLEntryVATAmt := CalcLCYToAddCurr(GLEntry."VAT Amount");
                                                END;
                                            END;
                                        "Gen. Posting Type"::Sale:
                                            BEGIN
                                                GLEntry."VAT Amount" := 0;
                                                AddCurrGLEntryVATAmt := 0;
                                            END;
                                    END;
                                "VAT Calculation Type"::"Full VAT":
                                    BEGIN
                                        CASE "Gen. Posting Type" OF
                                            "Gen. Posting Type"::Sale:
                                                BEGIN
                                                    VATPostingSetup.TESTFIELD("Sales VAT Account");
                                                    TESTFIELD("Account No.", VATPostingSetup."Sales VAT Account");
                                                END;
                                            "Gen. Posting Type"::Purchase:
                                                BEGIN
                                                    VATPostingSetup.TESTFIELD("Purchase VAT Account");
                                                    TESTFIELD("Account No.", VATPostingSetup."Purchase VAT Account");
                                                END;
                                        END;
                                        GLEntry.Amount := 0;
                                        GLEntry."Additional-Currency Amount" := 0;
                                        GLEntry."VAT Amount" := "Amount (LCY)";
                                        IF "Source Currency Code" = GLSetup."Additional Reporting Currency" THEN
                                            AddCurrGLEntryVATAmt := "Source Currency Amount"
                                        ELSE
                                            AddCurrGLEntryVATAmt := CalcLCYToAddCurr("Amount (LCY)");
                                    END;
                                "VAT Calculation Type"::"Sales Tax":
                                    BEGIN
                                        IF ("Gen. Posting Type" = "Gen. Posting Type"::Purchase) AND
                                           "Use Tax"
                                        THEN BEGIN
                                            GLEntry."VAT Amount" :=
                                              ROUND(
                                                SalesTaxCalculate.CalculateTax(
                                                  "Tax Area Code", "Tax Group Code", "Tax Liable",
                                                  "Posting Date", "Amount (LCY)", Quantity, 0));
                                            GLEntry.Amount := "Amount (LCY)";
                                        END ELSE BEGIN
                                            GLEntry.Amount :=
                                              ROUND(
                                                SalesTaxCalculate.ReverseCalculateTax(
                                                  "Tax Area Code", "Tax Group Code", "Tax Liable",
                                                  "Posting Date", "Amount (LCY)", Quantity, 0));
                                            GLEntry."VAT Amount" := "Amount (LCY)" - GLEntry.Amount;
                                        END;
                                        GLEntry."Additional-Currency Amount" := "Source Curr. VAT Base Amount";
                                        IF "Source Currency Code" = GLSetup."Additional Reporting Currency" THEN
                                            AddCurrGLEntryVATAmt := "Source Curr. VAT Amount"
                                        ELSE
                                            AddCurrGLEntryVATAmt := CalcLCYToAddCurr(GLEntry."VAT Amount");
                                    END;
                            END;
                        END;
                    "VAT Posting"::"Manual VAT Entry":
                        BEGIN
                            IF GenJnlLine."Gen. Posting Type" <> GenJnlLine."Gen. Posting Type"::Settlement THEN BEGIN
                                GLEntry."Gen. Bus. Posting Group" := "Gen. Bus. Posting Group";
                                GLEntry."Gen. Prod. Posting Group" := "Gen. Prod. Posting Group";
                                GLEntry."VAT Bus. Posting Group" := "VAT Bus. Posting Group";
                                GLEntry."VAT Prod. Posting Group" := "VAT Prod. Posting Group";
                                GLEntry."Tax Area Code" := "Tax Area Code";
                                GLEntry."Tax Liable" := "Tax Liable";
                                GLEntry."Tax Group Code" := "Tax Group Code";
                                GLEntry."Use Tax" := "Use Tax";
                                GLEntry."VAT Amount" := "VAT Amount (LCY)";
                                IF "Source Currency Code" = GLSetup."Additional Reporting Currency" THEN
                                    AddCurrGLEntryVATAmt := "Source Curr. VAT Amount"
                                ELSE
                                    AddCurrGLEntryVATAmt := CalcLCYToAddCurr("VAT Amount (LCY)");
                            END;
                        END;
                END;
            END;
        GLCalcAddCurrency(GLEntry."Additional-Currency Amount", TRUE);
    end;

    procedure PostVAT()
    var
        TaxDetail2: Record "322";
        VATAmount: Decimal;
        VATAmount2: Decimal;
        VATBase: Decimal;
        VATBase2: Decimal;
        SrcCurrVATAmount: Decimal;
        SrcCurrVATBase: Decimal;
        SrcCurrSalesTaxBaseAmount: Decimal;
        RemSrcCurrVATAmount: Decimal;
        TaxDetailFound: Boolean;
    begin
        WITH GenJnlLine DO BEGIN
            // Post VAT
            // VAT for VAT entry
            CASE "VAT Calculation Type" OF
                "VAT Calculation Type"::"Normal VAT",
                "VAT Calculation Type"::"Reverse Charge VAT",
                "VAT Calculation Type"::"Full VAT":
                    BEGIN
                        IF "VAT Posting" = "VAT Posting"::"Automatic VAT Entry" THEN
                            "VAT Base Amount (LCY)" := GLEntry.Amount;
                        IF "Gen. Posting Type" = "Gen. Posting Type"::Settlement THEN
                            AddCurrGLEntryVATAmt := "Source Curr. VAT Amount";
                        InsertVAT(
                          GLEntry.Amount, GLEntry."VAT Amount", "VAT Base Amount (LCY)", "Source Currency Code",
                          GLEntry."Additional-Currency Amount", AddCurrGLEntryVATAmt, "Source Curr. VAT Base Amount");
                        NextConnectionNo := NextConnectionNo + 1;
                    END;
                "VAT Calculation Type"::"Sales Tax":
                    BEGIN
                        CASE "VAT Posting" OF
                            "VAT Posting"::"Automatic VAT Entry":
                                SalesTaxBaseAmount := GLEntry.Amount;
                            "VAT Posting"::"Manual VAT Entry":
                                SalesTaxBaseAmount := "VAT Base Amount (LCY)";
                        END;
                        IF ("VAT Posting" = "VAT Posting"::"Manual VAT Entry") AND
                           ("Gen. Posting Type" = "Gen. Posting Type"::Settlement)
                        THEN BEGIN
                            TaxDetail."Tax Jurisdiction Code" := "Tax Area Code";
                            "Tax Area Code" := '';
                            InsertVAT(
                              GLEntry.Amount, GLEntry."VAT Amount", "VAT Base Amount (LCY)", "Source Currency Code",
                              "Source Curr. VAT Base Amount", "Source Curr. VAT Amount", "Source Curr. VAT Base Amount");
                        END ELSE BEGIN
                            CLEAR(SalesTaxCalculate);
                            SalesTaxCalculate.InitSalesTaxLines(
                              "Tax Area Code", "Tax Group Code", "Tax Liable",
                              SalesTaxBaseAmount, Quantity, "Posting Date", GLEntry."VAT Amount");
                            SrcCurrVATAmount := 0;
                            SrcCurrSalesTaxBaseAmount := CalcLCYToAddCurr(SalesTaxBaseAmount);
                            RemSrcCurrVATAmount := AddCurrGLEntryVATAmt;
                            TaxDetailFound := FALSE;
                            WHILE SalesTaxCalculate.GetSalesTaxLine(TaxDetail2, VATAmount, VATBase) DO BEGIN
                                RemSrcCurrVATAmount := RemSrcCurrVATAmount - SrcCurrVATAmount;
                                IF TaxDetailFound THEN
                                    InsertVAT(
                                      SalesTaxBaseAmount, VATAmount2, VATBase2, "Source Currency Code",
                                      SrcCurrSalesTaxBaseAmount, SrcCurrVATAmount, SrcCurrVATBase);
                                TaxDetailFound := TRUE;
                                TaxDetail := TaxDetail2;
                                VATAmount2 := VATAmount;
                                VATBase2 := VATBase;
                                SrcCurrVATAmount := CalcLCYToAddCurr(VATAmount);
                                SrcCurrVATBase := CalcLCYToAddCurr(VATBase);
                            END;
                            IF TaxDetailFound THEN
                                InsertVAT(
                                  SalesTaxBaseAmount, VATAmount2, VATBase2, "Source Currency Code",
                                  SrcCurrSalesTaxBaseAmount, RemSrcCurrVATAmount, SrcCurrVATBase);
                            InsertSummarizedVAT;
                        END;
                    END;
            END;
        END;
    end;

    procedure InsertVAT(GLEntryAmount: Decimal; GLEntryVATAmount: Decimal; GLEntryBaseAmount: Decimal; SrcCurrCode: Code[10]; SrcCurrGLEntryAmt: Decimal; SrcCurrGLEntryVATAmt: Decimal; SrcCurrGLEntryBaseAmt: Decimal)
    var
        VATAmount: Decimal;
        VATBase: Decimal;
        UnrealizedVAT: Boolean;
        SrcCurrVATAmount: Decimal;
        SrcCurrVATBase: Decimal;
        VATDifferenceLCY: Decimal;
        SrcCurrVATDifference: Decimal;
    begin
        WITH GenJnlLine DO BEGIN
            // Post VAT
            // VAT for VAT entry
            VATEntry.INIT;
            VATEntry."Entry No." := NextVATEntryNo;
            VATEntry."Gen. Bus. Posting Group" := "Gen. Bus. Posting Group";
            VATEntry."Gen. Prod. Posting Group" := "Gen. Prod. Posting Group";
            VATEntry."VAT Bus. Posting Group" := "VAT Bus. Posting Group";
            VATEntry."VAT Prod. Posting Group" := "VAT Prod. Posting Group";
            VATEntry."Tax Area Code" := "Tax Area Code";
            VATEntry."Tax Liable" := "Tax Liable";
            VATEntry."Tax Group Code" := "Tax Group Code";
            VATEntry."Use Tax" := "Use Tax";
            VATEntry."Posting Date" := "Posting Date";
            VATEntry."Document Date" := "Document Date";
            VATEntry."Document No." := "Document No.";
            VATEntry."External Document No." := "External Document No.";
            VATEntry."Document Type" := "Document Type";
            VATEntry.Type := "Gen. Posting Type";
            VATEntry."VAT Calculation Type" := "VAT Calculation Type";
            VATEntry."Source Code" := "Source Code";
            VATEntry."Reason Code" := "Reason Code";
            VATEntry."Ship-to/Order Address Code" := "Ship-to/Order Address Code";
            VATEntry."EU 3-Party Trade" := "EU 3-Party Trade";
            VATEntry."Transaction No." := NextTransactionNo;
            VATEntry."Sales Tax Connection No." := NextConnectionNo;
            VATEntry."User ID" := USERID;
            VATEntry."No. Series" := "Posting No. Series";
            VATEntry."VAT Base Discount %" := "VAT Base Discount %";
            VATEntry."Bill-to/Pay-to No." := "Bill-to/Pay-to No.";
            IF "Bill-to/Pay-to No." <> '' THEN
                CASE VATEntry.Type OF
                    VATEntry.Type::Purchase:
                        BEGIN
                            IF Vend."No." <> "Bill-to/Pay-to No." THEN
                                Vend.GET("Bill-to/Pay-to No.");
                            VATEntry."Country/Region Code" := Vend."Country/Region Code";
                            VATEntry."VAT Registration No." := Vend."VAT Registration No.";
                        END;
                    VATEntry.Type::Sale:
                        BEGIN
                            IF Cust."No." <> "Bill-to/Pay-to No." THEN
                                Cust.GET("Bill-to/Pay-to No.");
                            VATEntry."Country/Region Code" := Cust."Country/Region Code";
                            VATEntry."VAT Registration No." := Cust."VAT Registration No.";
                        END;
                END;

            IF "VAT Difference" = 0 THEN
                VATDifferenceLCY := 0
            ELSE
                IF "Currency Code" = '' THEN
                    VATDifferenceLCY := "VAT Difference"
                ELSE
                    VATDifferenceLCY :=
                      ROUND(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                          "Posting Date", "Currency Code", "VAT Difference",
                          CurrExchRate.ExchangeRate("Posting Date", "Currency Code")));

            IF "VAT Calculation Type" = "VAT Calculation Type"::"Sales Tax" THEN BEGIN
                IF TaxJurisdiction.Code <> TaxDetail."Tax Jurisdiction Code" THEN
                    TaxJurisdiction.GET(TaxDetail."Tax Jurisdiction Code");
                IF "Gen. Posting Type" <> "Gen. Posting Type"::Settlement THEN BEGIN
                    VATEntry."Tax Group Used" := TaxDetail."Tax Group Code";
                    VATEntry."Tax Type" := TaxDetail."Tax Type";
                    VATEntry."Tax on Tax" := TaxDetail."Calculate Tax on Tax";
                END;
                VATEntry."Tax Jurisdiction Code" := TaxDetail."Tax Jurisdiction Code";
            END;

            IF GLSetup."Additional Reporting Currency" <> '' THEN
                IF GLSetup."Additional Reporting Currency" <> SrcCurrCode THEN BEGIN
                    SrcCurrGLEntryAmt := ExchangeAmtLCYToFCY2(GLEntryAmount);
                    SrcCurrGLEntryVATAmt := ExchangeAmtLCYToFCY2(GLEntryVATAmount);
                    SrcCurrGLEntryBaseAmt := ExchangeAmtLCYToFCY2(GLEntryBaseAmount);
                    SrcCurrVATDifference := ExchangeAmtLCYToFCY2(VATDifferenceLCY);
                END ELSE
                    SrcCurrVATDifference := "VAT Difference";

            UnrealizedVAT :=
              (((VATPostingSetup."Unrealized VAT Type" > 0) AND
                (VATPostingSetup."VAT Calculation Type" IN
                 [VATPostingSetup."VAT Calculation Type"::"Normal VAT",
                  VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT",
                  VATPostingSetup."VAT Calculation Type"::"Full VAT"])) OR
               ((TaxJurisdiction."Unrealized VAT Type" > 0) AND
                (VATPostingSetup."VAT Calculation Type" IN
                 [VATPostingSetup."VAT Calculation Type"::"Sales Tax"]))) AND
              ("Document Type" IN
               ["Document Type"::Invoice,
                "Document Type"::"Credit Memo",
                "Document Type"::"Finance Charge Memo",
                "Document Type"::Reminder]);
            IF GLSetup."Prepayment Unrealized VAT" AND NOT GLSetup."Unrealized VAT" AND
              (VATPostingSetup."Unrealized VAT Type" > 0)
            THEN
                UnrealizedVAT := GenJnlLine.Prepayment;

            // VAT for VAT entry
            IF "Gen. Posting Type" <> 0 THEN BEGIN
                CASE "VAT Posting" OF
                    "VAT Posting"::"Automatic VAT Entry":
                        BEGIN
                            VATAmount := GLEntryVATAmount;
                            VATBase := GLEntryBaseAmount;
                            SrcCurrVATAmount := SrcCurrGLEntryVATAmt;
                            SrcCurrVATBase := SrcCurrGLEntryBaseAmt;
                        END;
                    "VAT Posting"::"Manual VAT Entry":
                        BEGIN
                            IF "Gen. Posting Type" = "Gen. Posting Type"::Settlement THEN BEGIN
                                VATAmount := GLEntryAmount;
                                SrcCurrVATAmount := SrcCurrGLEntryVATAmt;
                                VATEntry.Closed := TRUE;
                            END ELSE BEGIN
                                VATAmount := GLEntryVATAmount;
                                SrcCurrVATAmount := SrcCurrGLEntryVATAmt;
                            END;
                            VATBase := GLEntryBaseAmount;
                            SrcCurrVATBase := SrcCurrGLEntryBaseAmt;
                        END;
                END;

                IF UnrealizedVAT THEN BEGIN
                    VATEntry.Amount := 0;
                    VATEntry.Base := 0;
                    VATEntry."Unrealized Amount" := VATAmount;
                    VATEntry."Unrealized Base" := VATBase;
                    VATEntry."Remaining Unrealized Amount" := VATEntry."Unrealized Amount";
                    VATEntry."Remaining Unrealized Base" := VATEntry."Unrealized Base";
                END ELSE BEGIN
                    VATEntry.Amount := VATAmount;
                    VATEntry.Base := VATBase;
                    VATEntry."Unrealized Amount" := 0;
                    VATEntry."Unrealized Base" := 0;
                    VATEntry."Remaining Unrealized Amount" := 0;
                    VATEntry."Remaining Unrealized Base" := 0;
                END;

                IF GLSetup."Additional Reporting Currency" = '' THEN BEGIN
                    VATEntry."Additional-Currency Base" := 0;
                    VATEntry."Additional-Currency Amount" := 0;
                    VATEntry."Add.-Currency Unrealized Amt." := 0;
                    VATEntry."Add.-Currency Unrealized Base" := 0;
                END ELSE
                    IF UnrealizedVAT THEN BEGIN
                        VATEntry."Additional-Currency Base" := 0;
                        VATEntry."Additional-Currency Amount" := 0;
                        VATEntry."Add.-Currency Unrealized Base" := SrcCurrVATBase;
                        VATEntry."Add.-Currency Unrealized Amt." := SrcCurrVATAmount;
                    END ELSE BEGIN
                        VATEntry."Additional-Currency Base" := SrcCurrVATBase;
                        VATEntry."Additional-Currency Amount" := SrcCurrVATAmount;
                        VATEntry."Add.-Currency Unrealized Base" := 0;
                        VATEntry."Add.-Currency Unrealized Amt." := 0;
                    END;
                VATEntry."Add.-Curr. Rem. Unreal. Amount" := VATEntry."Add.-Currency Unrealized Amt.";
                VATEntry."Add.-Curr. Rem. Unreal. Base" := VATEntry."Add.-Currency Unrealized Base";
                VATEntry."VAT Difference" := VATDifferenceLCY;
                VATEntry."Add.-Curr. VAT Difference" := SrcCurrVATDifference;

                VATEntry.INSERT;
                GLEntryVatEntrylink.InsertLink(GLEntryTmp, VATEntry);
                NextVATEntryNo := NextVATEntryNo + 1;
            END;

            // VAT for G/L entry/entries
            IF (GLEntryVATAmount <> 0) OR
               ((SrcCurrGLEntryVATAmt <> 0) AND (SrcCurrCode = GLSetup."Additional Reporting Currency"))
            THEN BEGIN
                CASE "Gen. Posting Type" OF
                    "Gen. Posting Type"::Purchase:
                        CASE VATPostingSetup."VAT Calculation Type" OF
                            VATPostingSetup."VAT Calculation Type"::"Normal VAT",
                            VATPostingSetup."VAT Calculation Type"::"Full VAT":
                                BEGIN
                                    IF UnrealizedVAT THEN BEGIN
                                        VATPostingSetup.TESTFIELD("Purch. VAT Unreal. Account");
                                        InitGLEntry(
                                          VATPostingSetup."Purch. VAT Unreal. Account",
                                          GLEntryVATAmount, SrcCurrGLEntryVATAmt, TRUE, TRUE);
                                        InsertGLEntry(TRUE);
                                    END ELSE BEGIN
                                        VATPostingSetup.TESTFIELD("Purchase VAT Account");
                                        InitGLEntry(
                                          VATPostingSetup."Purchase VAT Account",
                                          GLEntryVATAmount, SrcCurrGLEntryVATAmt, TRUE, TRUE);
                                        InsertGLEntry(TRUE);
                                    END;
                                END;
                            VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT":
                                BEGIN
                                    IF UnrealizedVAT THEN BEGIN
                                        VATPostingSetup.TESTFIELD("Purch. VAT Unreal. Account");
                                        InitGLEntry(
                                          VATPostingSetup."Purch. VAT Unreal. Account",
                                          GLEntryVATAmount, SrcCurrGLEntryVATAmt, TRUE, TRUE);
                                        InsertGLEntry(TRUE);
                                        VATPostingSetup.TESTFIELD("Reverse Chrg. VAT Unreal. Acc.");
                                        InitGLEntry(
                                          VATPostingSetup."Reverse Chrg. VAT Unreal. Acc.",
                                          -GLEntryVATAmount, -SrcCurrGLEntryVATAmt, TRUE, TRUE);
                                        InsertGLEntry(TRUE);
                                    END ELSE BEGIN
                                        VATPostingSetup.TESTFIELD("Purchase VAT Account");
                                        InitGLEntry(
                                          VATPostingSetup."Purchase VAT Account",
                                          GLEntryVATAmount, SrcCurrGLEntryVATAmt, TRUE, TRUE);
                                        InsertGLEntry(TRUE);
                                        VATPostingSetup.TESTFIELD("Reverse Chrg. VAT Acc.");
                                        InitGLEntry(
                                          VATPostingSetup."Reverse Chrg. VAT Acc.",
                                          -GLEntryVATAmount, -SrcCurrGLEntryVATAmt, TRUE, TRUE);
                                        InsertGLEntry(TRUE);
                                    END;
                                END;
                            VATPostingSetup."VAT Calculation Type"::"Sales Tax":
                                IF "Use Tax" THEN BEGIN
                                    IF UnrealizedVAT THEN BEGIN
                                        TaxJurisdiction.TESTFIELD("Unreal. Tax Acc. (Purchases)");
                                        InitGLEntry(
                                          TaxJurisdiction."Unreal. Tax Acc. (Purchases)",
                                          GLEntryVATAmount, SrcCurrGLEntryVATAmt, TRUE, TRUE);
                                        SummarizeVAT(
                                          GLSetup."Summarize G/L Entries", GLEntry, TempGLEntryVAT, InsertedTempGLEntryVAT);
                                        TaxJurisdiction.TESTFIELD("Unreal. Rev. Charge (Purch.)");
                                        InitGLEntry(
                                          TaxJurisdiction."Unreal. Rev. Charge (Purch.)",
                                          -GLEntryVATAmount, -SrcCurrGLEntryVATAmt, TRUE, TRUE);
                                        SummarizeVAT(
                                          GLSetup."Summarize G/L Entries", GLEntry, TempGLEntryVAT, InsertedTempGLEntryVAT);
                                    END ELSE BEGIN
                                        TaxJurisdiction.TESTFIELD("Tax Account (Purchases)");
                                        InitGLEntry(
                                          TaxJurisdiction."Tax Account (Purchases)",
                                          GLEntryVATAmount, SrcCurrGLEntryVATAmt, TRUE, TRUE);
                                        SummarizeVAT(
                                          GLSetup."Summarize G/L Entries", GLEntry, TempGLEntryVAT, InsertedTempGLEntryVAT);
                                        TaxJurisdiction.TESTFIELD("Reverse Charge (Purchases)");
                                        InitGLEntry(
                                          TaxJurisdiction."Reverse Charge (Purchases)",
                                          -GLEntryVATAmount, -SrcCurrGLEntryVATAmt, TRUE, TRUE);
                                        SummarizeVAT(
                                          GLSetup."Summarize G/L Entries", GLEntry, TempGLEntryVAT, InsertedTempGLEntryVAT);
                                    END;
                                END ELSE BEGIN
                                    IF UnrealizedVAT THEN BEGIN
                                        TaxJurisdiction.TESTFIELD("Unreal. Tax Acc. (Purchases)");
                                        InitGLEntry(
                                          TaxJurisdiction."Unreal. Tax Acc. (Purchases)",
                                          GLEntryVATAmount, SrcCurrGLEntryVATAmt, TRUE, TRUE);
                                    END ELSE BEGIN
                                        TaxJurisdiction.TESTFIELD("Tax Account (Purchases)");
                                        InitGLEntry(
                                          TaxJurisdiction."Tax Account (Purchases)",
                                          GLEntryVATAmount, SrcCurrGLEntryVATAmt, TRUE, TRUE);
                                    END;
                                    SummarizeVAT(
                                      GLSetup."Summarize G/L Entries", GLEntry, TempGLEntryVAT, InsertedTempGLEntryVAT);
                                END;
                        END;
                    "Gen. Posting Type"::Sale:
                        CASE VATPostingSetup."VAT Calculation Type" OF
                            VATPostingSetup."VAT Calculation Type"::"Normal VAT",
                            VATPostingSetup."VAT Calculation Type"::"Full VAT":
                                BEGIN
                                    IF UnrealizedVAT THEN BEGIN
                                        VATPostingSetup.TESTFIELD("Sales VAT Unreal. Account");
                                        InitGLEntry(
                                          VATPostingSetup."Sales VAT Unreal. Account",
                                          GLEntryVATAmount, SrcCurrGLEntryVATAmt, TRUE, TRUE);
                                    END ELSE BEGIN
                                        VATPostingSetup.TESTFIELD("Sales VAT Account");
                                        InitGLEntry(
                                          VATPostingSetup."Sales VAT Account",
                                          GLEntryVATAmount, SrcCurrGLEntryVATAmt, TRUE, TRUE);
                                    END;
                                    InsertGLEntry(TRUE);
                                END;
                            VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT":
                                ;
                            VATPostingSetup."VAT Calculation Type"::"Sales Tax":
                                BEGIN
                                    IF UnrealizedVAT THEN BEGIN
                                        TaxJurisdiction.TESTFIELD("Unreal. Tax Acc. (Sales)");
                                        InitGLEntry(
                                          TaxJurisdiction."Unreal. Tax Acc. (Sales)",
                                          GLEntryVATAmount, SrcCurrGLEntryVATAmt, TRUE, TRUE);
                                    END ELSE BEGIN
                                        TaxJurisdiction.TESTFIELD("Tax Account (Sales)");
                                        InitGLEntry(
                                          TaxJurisdiction."Tax Account (Sales)",
                                          GLEntryVATAmount, SrcCurrGLEntryVATAmt, TRUE, TRUE);
                                    END;
                                    SummarizeVAT(
                                      GLSetup."Summarize G/L Entries", GLEntry, TempGLEntryVAT, InsertedTempGLEntryVAT);
                                END;
                        END;
                END;
            END;
        END;
    end;

    procedure SummarizeVAT(SummarizeGLEntries: Boolean; var GLEntry: Record "G/L Entry"; var TempGLEntryVAT: Record "G/L Entry"; var InsertedTempGLEntryVAT: Integer)
    var
        InsertedTempVAT: Boolean;
    begin
        InsertedTempVAT := FALSE;
        IF SummarizeGLEntries THEN
            IF TempGLEntryVAT.FINDSET THEN
                REPEAT
                    IF (TempGLEntryVAT."G/L Account No." = GLEntry."G/L Account No.") AND
                       (TempGLEntryVAT."Bal. Account No." = GLEntry."Bal. Account No.")
                    THEN BEGIN
                        TempGLEntryVAT.Amount := TempGLEntryVAT.Amount + GLEntry.Amount;
                        TempGLEntryVAT."Additional-Currency Amount" :=
                          TempGLEntryVAT."Additional-Currency Amount" + GLEntry."Additional-Currency Amount";
                        TempGLEntryVAT.MODIFY;
                        InsertedTempVAT := TRUE;
                    END;
                UNTIL (TempGLEntryVAT.NEXT = 0) OR InsertedTempVAT;
        IF NOT InsertedTempVAT OR NOT SummarizeGLEntries THEN BEGIN
            TempGLEntryVAT := GLEntry;
            TempGLEntryVAT."Entry No." :=
              TempGLEntryVAT."Entry No." + InsertedTempGLEntryVAT;
            TempGLEntryVAT.INSERT;
            InsertedTempGLEntryVAT := InsertedTempGLEntryVAT + 1;
        END;
    end;

    procedure InsertSummarizedVAT()
    begin
        IF TempGLEntryVAT.FINDSET THEN BEGIN
            REPEAT
                GLEntry := TempGLEntryVAT;
                InsertGLEntry(TRUE);
            UNTIL TempGLEntryVAT.NEXT = 0;
            TempGLEntryVAT.DELETEALL;
            InsertedTempGLEntryVAT := 0;
        END;
        NextConnectionNo := NextConnectionNo + 1;
    end;

    local procedure PostGLAcc()
    var
        GLSetupRec: Record "General Ledger Setup";
        GLAccount: Record "G/L Account";
        IBUDebitAcc: Boolean;
        IBUCreditAcc: Boolean;
        AgreementChargeAmt: Record "50504";
        AgreementCharges: Record "50504";
        LMLine: Record "50501";
        LeaseMgmtSalesLine: Record "50505";
    begin
        WITH GenJnlLine DO BEGIN
            //APNT-IBU1.0
            GLSetupRec.GET;
            //APNT-IC1.1 -
            IF GLAccount.GET(GLSetup."IBU Debit Account") THEN
                IBUDebitAcc := GLAccount."Direct Posting";

            IF GLAccount.GET(GLSetup."IBU Credit Account") THEN
                IBUCreditAcc := GLAccount."Direct Posting";
            //APNT-IC1.1 +

            IF GLAccount.GET(GLSetup."IBU Debit Account") THEN BEGIN
                GLAccount."Direct Posting" := TRUE;
                GLAccount.MODIFY;
            END;

            IF GLAccount.GET(GLSetup."IBU Credit Account") THEN BEGIN
                GLAccount."Direct Posting" := TRUE;
                GLAccount.MODIFY;
            END;
            //APNT-IBU1.0

            // Post G/L entry
            InitGLEntry(
              "Account No.", "Amount (LCY)",
              "Source Currency Amount", TRUE, "System-Created Entry");
            IF NOT "System-Created Entry" THEN
                IF "Posting Date" = NORMALDATE("Posting Date") THEN
                    GLAcc.TESTFIELD("Direct Posting", TRUE);
            GLEntry."Gen. Posting Type" := "Gen. Posting Type";
            GLEntry."Bal. Account Type" := "Bal. Account Type";
            GLEntry."Reason Code" := "Reason Code";  //LS
            GLEntry."Bal. Account No." := "Bal. Account No.";
            GLEntry."No. Series" := "Posting No. Series";
            //APNT-AT1.0
            GLEntry."FA Posting Type" := "FA Posting Type";
            //APNT-AT1.0

            IF "Additional-Currency Posting" =
               "Additional-Currency Posting"::"Additional-Currency Amount Only"
            THEN BEGIN
                GLEntry."Additional-Currency Amount" := Amount;
                GLEntry.Amount := 0;
            END;

            GLEntry.Remarks := GenJnlLine.Remarks; //APNT-PV1.0
                                                   //APNT-FIN1.0
            GLEntry."Facility Type" := GenJnlLine."Facility Type";
            GLEntry."Facility No." := GenJnlLine."Facility No.";
            GLEntry."Charges Type" := GenJnlLine."Charges Type";
            GLEntry."Charge No." := FORMAT(GenJnlLine."Charge No.");
            GLEntry."Loan No." := GenJnlLine."Loan No.";
            GLEntry."Investment Type" := GenJnlLine."Investment Type";
            GLEntry."Investment No." := GenJnlLine."Investment No.";
            GLEntry."Real Estate No." := GenJnlLine."Real Estate No.";
            //APNT-FIN1.0
            //APNT-DT1.0
            GLEntry."Created Date Time" := CURRENTDATETIME;
            //APNT-DT1.0
            //APNT-LM1.0
            GLEntry."Lease Agreement No." := "Lease Agreement No.";
            GLEntry."Lease Agreement Charge Type" := "Lease Agreement Charge Type";
            GLEntry."Lease Agreement Charge No." := "Lease Agreement Charge No.";
            IF "Posted Lease Agmt. No." <> '' THEN
                GLEntry."Lease Agreement No." := "Posted Lease Agmt. No.";
            IF "Posted Lease Agmt. Charge No." <> '' THEN
                GLEntry."Lease Agreement Charge No." := "Posted Lease Agmt. Charge No.";
            //APNT-LM1.0

            InitVat;
            InsertGLEntry(TRUE);
            PostJob;
            PostVAT;
            //APNT-HR1.0
            IF "Employee No." <> '' THEN BEGIN
                PostSettlements;
            END;
            IF ("Bonus Accrual Entry" = TRUE) AND ("Last Bonus Accrued Date" <> 0D) THEN
                PostBonusAccruals;
            //APNT-HR1.0

            //APNT-IBU1.0
            IF GLAccount.GET(GLSetup."IBU Debit Account") THEN BEGIN
                GLAccount."Direct Posting" := IBUDebitAcc;
                GLAccount.MODIFY;
            END;

            IF GLAccount.GET(GLSetup."IBU Credit Account") THEN BEGIN
                GLAccount."Direct Posting" := IBUCreditAcc;
                GLAccount.MODIFY;
            END;
            //APNT-IBU1.0

            //APNT-LM1.0
            IF GenJnlLine."Lease Agreement No." <> '' THEN BEGIN
                LMLine.RESET;
                LMLine.SETRANGE("Document Type", LMLine."Document Type"::"Lease Agreement");
                LMLine.SETRANGE("Document No.", GenJnlLine."Lease Agreement No.");
                LMLine.SETRANGE("Journal No.", GenJnlLine."Document No.");
                LMLine.SETRANGE("End Date", GenJnlLine."Posting Date");
                LMLine.SETRANGE("Line Created", TRUE);
                LMLine.SETRANGE(Posted, FALSE);
                IF LMLine.FIND('-') THEN BEGIN
                    AgreementCharges.RESET;
                    AgreementCharges.SETRANGE("Document Type", AgreementCharges."Document Type"::"Lease Agreement");
                    AgreementCharges.SETRANGE("Document No.", LMLine."Document No.");
                    AgreementCharges.SETRANGE("Charge Type", GenJnlLine."Lease Agreement Charge Type");
                    AgreementCharges.SETRANGE("Charge No.", GenJnlLine."Lease Agreement Charge No.");
                    AgreementCharges.SETRANGE("Next Posting Date", LMLine."Start Date", LMLine."End Date");
                    IF AgreementCharges.FIND('-') THEN
                        REPEAT
                            AgreementCharges."Last Posting Date" := AgreementCharges."Next Posting Date";
                            AgreementCharges."Next Posting Date" := CALCDATE(AgreementCharges."Recurring Frequency",
                                                        AgreementCharges."Next Posting Date");
                            AgreementCharges.MODIFY;
                        UNTIL AgreementCharges.NEXT = 0;
                    REPEAT
                        LMLine.Posted := TRUE;
                        LMLine.MODIFY;
                    UNTIL LMLine.NEXT = 0;
                END ELSE BEGIN
                    IF GenJnlLine."Lease Agreement Charge No." <> '' THEN BEGIN
                        AgreementCharges.RESET;
                        AgreementCharges.SETRANGE("Document Type", AgreementCharges."Document Type"::"Lease Agreement");
                        AgreementCharges.SETRANGE("Document No.", GenJnlLine."Lease Agreement No.");
                        AgreementCharges.SETRANGE("Charge Type", GenJnlLine."Lease Agreement Charge Type");
                        AgreementCharges.SETRANGE("Charge No.", GenJnlLine."Lease Agreement Charge No.");
                        AgreementCharges.SETRANGE("Next Posting Date", 0D, GenJnlLine."Posting Date");
                        IF AgreementCharges.FIND('-') THEN
                            REPEAT
                                AgreementCharges."Last Posting Date" := AgreementCharges."Next Posting Date";
                                AgreementCharges."Next Posting Date" := CALCDATE(AgreementCharges."Recurring Frequency",
                                         AgreementCharges."Next Posting Date");
                                AgreementCharges.MODIFY;
                            UNTIL AgreementCharges.NEXT = 0;
                    END;
                END;

                AgreementChargeAmt.RESET;
                AgreementChargeAmt.SETRANGE("Document Type", AgreementChargeAmt."Document Type"::"Lease Agreement");
                AgreementChargeAmt.SETRANGE("Document No.", GenJnlLine."Lease Agreement No.");
                AgreementChargeAmt.SETRANGE("Charge Type", GenJnlLine."Lease Agreement Charge Type");
                AgreementChargeAmt.SETRANGE("Charge No.", GenJnlLine."Lease Agreement Charge No.");
                IF AgreementChargeAmt.FIND('-') THEN BEGIN
                    AgreementChargeAmt.VALIDATE("Old Prepaid Amount", (AgreementChargeAmt."Old Prepaid Amount" + ABS(Amount)));
                    AgreementChargeAmt.MODIFY;
                END;
            END;
            //APNT-LM1.0
            //APNT-T009612
            LeaseMgmtSalesLine.RESET;
            LeaseMgmtSalesLine.SETRANGE("Document Type", LeaseMgmtSalesLine."Document Type"::"Lease Agreement");
            LeaseMgmtSalesLine.SETRANGE("Document No.", GenJnlLine."Lease Agreement No.");
            LeaseMgmtSalesLine.SETFILTER("Cumulative JV Amount", '>%1', 0);
            LeaseMgmtSalesLine.SETRANGE("Cumulative Journals Created", TRUE);
            LeaseMgmtSalesLine.SETRANGE("Cumulative Amount Posted", FALSE);
            IF LeaseMgmtSalesLine.FINDFIRST THEN
                REPEAT
                    LeaseMgmtSalesLine."Cumulative Amount Posted" := TRUE;
                    LeaseMgmtSalesLine.MODIFY;
                UNTIL LeaseMgmtSalesLine.NEXT = 0;
            //APNT-T009612
        END;
    end;

    local procedure PostCust()
    var
        CustLedgEntry: Record "21";
        OldCustLedgEntry: Record "21";
        CVLedgEntryBuf: Record "382";
        DtldCVLedgEntryBuf: Record "383" temporary;
        DtldCustLedgEntry: Record "379";
    begin
        WITH GenJnlLine DO BEGIN
            //APNT-CP1.0
            StartDate := CALCDATE('-CM', "Posting Date");
            AccountingPeriod.GET(StartDate);
            AccountingPeriod.TESTFIELD("Closed Acc. Receivables", FALSE);
            //APNT-CP1.0
            IF Cust."No." <> "Account No." THEN
                Cust.GET("Account No.");
            Cust.CheckBlockedCustOnJnls(Cust, "Document Type", TRUE);

            IF "Posting Group" = '' THEN BEGIN
                Cust.TESTFIELD("Customer Posting Group");
                "Posting Group" := Cust."Customer Posting Group";
            END;
            CustPostingGr.GET("Posting Group");
            CustPostingGr.TESTFIELD("Receivables Account");

            DtldCustLedgEntry.LOCKTABLE;
            CustLedgEntry.LOCKTABLE;

            CustLedgEntry.INIT;
            CustLedgEntry."Customer No." := "Account No.";
            CustLedgEntry."Posting Date" := "Posting Date";
            CustLedgEntry."Document Date" := "Document Date";
            CustLedgEntry."Document Type" := "Document Type";
            CustLedgEntry."Document No." := "Document No.";
            CustLedgEntry."External Document No." := "External Document No.";
            CustLedgEntry."Statement No." := "Statement No.";  //LS
            CustLedgEntry.Description := Description;
            CustLedgEntry."Currency Code" := "Currency Code";
            CustLedgEntry."Sales (LCY)" := "Sales/Purch. (LCY)";
            CustLedgEntry."Profit (LCY)" := "Profit (LCY)";
            CustLedgEntry."Inv. Discount (LCY)" := "Inv. Discount (LCY)";
            CustLedgEntry."Sell-to Customer No." := "Sell-to/Buy-from No.";
            CustLedgEntry."Customer Posting Group" := "Posting Group";
            CustLedgEntry."Global Dimension 1 Code" := "Shortcut Dimension 1 Code";
            CustLedgEntry."Global Dimension 2 Code" := "Shortcut Dimension 2 Code";
            CustLedgEntry."Salesperson Code" := "Salespers./Purch. Code";
            CustLedgEntry."Source Code" := "Source Code";
            CustLedgEntry."On Hold" := "On Hold";
            CustLedgEntry."Applies-to Doc. Type" := "Applies-to Doc. Type";
            CustLedgEntry."Applies-to Doc. No." := "Applies-to Doc. No.";
            CustLedgEntry."Due Date" := "Due Date";
            CustLedgEntry."Pmt. Discount Date" := "Pmt. Discount Date";
            CustLedgEntry."Applies-to ID" := "Applies-to ID";
            CustLedgEntry."Journal Batch Name" := "Journal Batch Name";
            CustLedgEntry."Reason Code" := "Reason Code";
            CustLedgEntry."Entry No." := NextEntryNo;
            CustLedgEntry."Transaction No." := NextTransactionNo;
            CustLedgEntry."User ID" := USERID;
            CustLedgEntry."Bal. Account Type" := "Bal. Account Type";
            CustLedgEntry."Bal. Account No." := "Bal. Account No.";
            CustLedgEntry."No. Series" := "Posting No. Series";
            CustLedgEntry."IC Partner Code" := "IC Partner Code";
            CustLedgEntry.Prepayment := Prepayment;
            CustLedgEntry."Batch No." := "Batch No.";  //LS
                                                       //APNT-2.0
                                                       //CustLedgEntry."Ship-to Code" := "Ship-to/Order Address Code";
                                                       //APNT-2.0
                                                       //APNT-IBU1.0
            CustLedgEntry."IBU Entry" := "IBU Entry";
            CustLedgEntry."IPC Bal. Account Type" := "IPC Bal. Account Type";
            CustLedgEntry."IPC Bal. Account No." := "IPC Bal. Account No.";
            //APNT-IBU1.0
            //APNT-VAN1.0 +
            CustLedgEntry."VAN Payment Push" := "VAN Payment Push";
            //APNT-VAN1.0 -
            //DP6.01.01 START
            IF "Ref. Document No." <> '' THEN BEGIN
                CustLedgEntry."Ref. Document Type" := "Ref. Document Type";
                CustLedgEntry."Ref. Document No." := "Ref. Document No.";
                CustLedgEntry."Ref. Document Line No." := "Ref. Document Line No.";
            END;
            //DP6.01.01 STOP

            IF NOT Cust."Block Payment Tolerance" AND
               ((CustLedgEntry."Document Type" = CustLedgEntry."Document Type"::Invoice) OR
                (CustLedgEntry."Document Type" = CustLedgEntry."Document Type"::"Credit Memo"))
            THEN BEGIN

                IF (CustLedgEntry."Pmt. Discount Date" <> 0D) THEN
                    CustLedgEntry."Pmt. Disc. Tolerance Date" :=
                      CALCDATE(GLSetup."Payment Discount Grace Period", CustLedgEntry."Pmt. Discount Date")
                ELSE
                    CustLedgEntry."Pmt. Disc. Tolerance Date" := CustLedgEntry."Pmt. Discount Date";

                IF CustLedgEntry."Currency Code" = '' THEN BEGIN
                    IF (GLSetup."Max. Payment Tolerance Amount" <
                       (ABS(GLSetup."Payment Tolerance %" / 100 * "Amount (LCY)"))) OR (GLSetup."Payment Tolerance %" = 0)
                    THEN BEGIN
                        IF (GLSetup."Max. Payment Tolerance Amount" = 0) AND (GLSetup."Payment Tolerance %" > 0) THEN
                            CustLedgEntry."Max. Payment Tolerance" :=
                              ROUND(GLSetup."Payment Tolerance %" * "Amount (LCY)" / 100, GLSetup."Amount Rounding Precision")
                        ELSE
                            IF CustLedgEntry."Document Type" = CustLedgEntry."Document Type"::"Credit Memo" THEN
                                CustLedgEntry."Max. Payment Tolerance" := -GLSetup."Max. Payment Tolerance Amount"
                            ELSE
                                CustLedgEntry."Max. Payment Tolerance" := GLSetup."Max. Payment Tolerance Amount"
                    END ELSE
                        CustLedgEntry."Max. Payment Tolerance" :=
                          GLSetup."Payment Tolerance %" * "Amount (LCY)" / 100
                END ELSE BEGIN
                    IF (Currency."Max. Payment Tolerance Amount" <
                       (ABS(Currency."Payment Tolerance %" / 100 * Amount))) OR (Currency."Payment Tolerance %" = 0)
                    THEN BEGIN
                        IF (Currency."Max. Payment Tolerance Amount" = 0) AND (Currency."Payment Tolerance %" > 0) THEN
                            CustLedgEntry."Max. Payment Tolerance" :=
                              ROUND(Currency."Payment Tolerance %" * Amount / 100, Currency."Amount Rounding Precision")
                        ELSE
                            IF CustLedgEntry."Document Type" = CustLedgEntry."Document Type"::"Credit Memo" THEN
                                CustLedgEntry."Max. Payment Tolerance" := -Currency."Max. Payment Tolerance Amount"
                            ELSE
                                CustLedgEntry."Max. Payment Tolerance" := Currency."Max. Payment Tolerance Amount"
                    END ELSE
                        CustLedgEntry."Max. Payment Tolerance" :=
                          ROUND(Currency."Payment Tolerance %" * Amount / 100, Currency."Amount Rounding Precision");
                END;
                IF ABS(CustLedgEntry."Max. Payment Tolerance") > ABS(Amount) THEN
                    CustLedgEntry."Max. Payment Tolerance" := Amount;

            END;

            DtldCVLedgEntryBuf.DELETEALL;
            DtldCVLedgEntryBuf.INIT;
            DtldCVLedgEntryBuf."Cust. Ledger Entry No." := CustLedgEntry."Entry No.";
            DtldCVLedgEntryBuf."Entry Type" := DtldCVLedgEntryBuf."Entry Type"::"Initial Entry";
            DtldCVLedgEntryBuf."Posting Date" := "Posting Date";
            DtldCVLedgEntryBuf."Document Type" := "Document Type";
            DtldCVLedgEntryBuf."Document No." := "Document No.";
            DtldCVLedgEntryBuf.Amount := Amount;
            DtldCVLedgEntryBuf."Amount (LCY)" := "Amount (LCY)";
            DtldCVLedgEntryBuf."Additional-Currency Amount" := Amount;
            DtldCVLedgEntryBuf."Customer No." := "Account No.";
            DtldCVLedgEntryBuf."Currency Code" := "Currency Code";
            DtldCVLedgEntryBuf."User ID" := USERID;
            DtldCVLedgEntryBuf."Initial Entry Due Date" := "Due Date";
            DtldCVLedgEntryBuf."Initial Entry Global Dim. 1" := "Shortcut Dimension 1 Code";
            DtldCVLedgEntryBuf."Initial Entry Global Dim. 2" := "Shortcut Dimension 2 Code";
            DtldCVLedgEntryBuf."Initial Document Type" := "Document Type";
            //APNT-IBU1.0
            DtldCVLedgEntryBuf."IBU Entry" := "IBU Entry";
            //APNT-IBU1.0

            TransferCustLedgEntry(CVLedgEntryBuf, CustLedgEntry, TRUE);
            InsertDtldCVLedgEntry(DtldCVLedgEntryBuf, CVLedgEntryBuf, TRUE);
            CVLedgEntryBuf.Open := CVLedgEntryBuf."Remaining Amount" <> 0;
            CVLedgEntryBuf.Positive := CVLedgEntryBuf."Remaining Amount" > 0;

            IF "Amount (LCY)" <> 0 THEN BEGIN
                IF GLSetup."Pmt. Disc. Excl. VAT" THEN
                    CVLedgEntryBuf."Original Pmt. Disc. Possible" := "Sales/Purch. (LCY)" * Amount / "Amount (LCY)"
                ELSE
                    CVLedgEntryBuf."Original Pmt. Disc. Possible" := Amount;
                CVLedgEntryBuf."Original Pmt. Disc. Possible" :=
                  ROUND(
                    CVLedgEntryBuf."Original Pmt. Disc. Possible" * "Payment Discount %" / 100,
                    Currency."Amount Rounding Precision");

                CVLedgEntryBuf."Remaining Pmt. Disc. Possible" := CVLedgEntryBuf."Original Pmt. Disc. Possible";
            END;

            IF "Currency Code" <> '' THEN BEGIN
                TESTFIELD("Currency Factor");
                CVLedgEntryBuf."Original Currency Factor" := "Currency Factor"
            END ELSE
                CVLedgEntryBuf."Original Currency Factor" := 1;
            CVLedgEntryBuf."Adjusted Currency Factor" := CVLedgEntryBuf."Original Currency Factor";

            // Check the document no.
            IF "Recurring Method" = 0 THEN
                IF "Document Type" IN
                   ["Document Type"::Invoice,
                    "Document Type"::"Credit Memo",
                    "Document Type"::"Finance Charge Memo",
                    "Document Type"::Reminder]
                THEN BEGIN
                    OldCustLedgEntry.RESET;
                    IF NOT RECORDLEVELLOCKING THEN
                        OldCustLedgEntry.SETCURRENTKEY("Document No.");
                    OldCustLedgEntry.SETRANGE("Document No.", CVLedgEntryBuf."Document No.");
                    OldCustLedgEntry.SETRANGE("Document Type", CVLedgEntryBuf."Document Type");
                    IF NOT OldCustLedgEntry.ISEMPTY THEN
                        ERROR(
                          Text001,
                          "Document Type", "Document No.");

                    IF SalesSetup."Ext. Doc. No. Mandatory" THEN
                        IF "Document Type" IN
                           ["Document Type"::Invoice,
                            "Document Type"::"Credit Memo",
                            "Document Type"::Payment,
                            "Document Type"::Refund,
                            "Document Type"::" "]
                        THEN
                            TESTFIELD("External Document No.");
                END;

            // Post the application
            ApplyCustLedgEntry(
              CVLedgEntryBuf, DtldCVLedgEntryBuf, GenJnlLine, GLSetup."Appln. Rounding Precision");

            // Post customer entry
            TransferCustLedgEntry(CVLedgEntryBuf, CustLedgEntry, FALSE);
            CustLedgEntry."Amount to Apply" := 0;
            CustLedgEntry."Applies-to Doc. No." := '';
            CustLedgEntry.INSERT;

            DimMgt.MoveJnlLineDimToLedgEntryDim(
              TempJnlLineDim, DATABASE::"Cust. Ledger Entry", CustLedgEntry."Entry No.");

            // Post Dtld. customer entry
            PostDtldCustLedgEntries(
              GenJnlLine, DtldCVLedgEntryBuf, CustPostingGr, GLSetup, NextTransactionNo, TRUE);
        END;
    end;

    local procedure PostVend()
    var
        VendLedgEntry: Record "25";
        OldVendLedgEntry: Record "25";
        CVLedgEntryBuf: Record "382";
        DtldCVLedgEntryBuf: Record "383" temporary;
        DtldVendLedgEntry: Record "380";
    begin
        WITH GenJnlLine DO BEGIN
            //APNT-CP1.0
            StartDate := CALCDATE('-CM', "Posting Date");
            AccountingPeriod.GET(StartDate);
            AccountingPeriod.TESTFIELD("Closed Acc. Payable", FALSE);
            //APNT-CP1.0
            IF Vend."No." <> "Account No." THEN
                Vend.GET("Account No.");
            Vend.CheckBlockedVendOnJnls(Vend, "Document Type", TRUE);
            //T044145 -
            CompanyInformation.GET();
            IF CompanyInformation."Enable Vendor Approval Process" THEN
                Vend.CheckVendorStatus(Vend, TRUE);
            //T044145 +

            IF "Posting Group" = '' THEN BEGIN
                Vend.TESTFIELD("Vendor Posting Group");
                "Posting Group" := Vend."Vendor Posting Group";
            END;
            VendPostingGr.GET("Posting Group");
            VendPostingGr.TESTFIELD("Payables Account");

            DtldVendLedgEntry.LOCKTABLE;
            VendLedgEntry.LOCKTABLE;

            VendLedgEntry.INIT;
            VendLedgEntry."Vendor No." := "Account No.";
            VendLedgEntry."Posting Date" := "Posting Date";
            VendLedgEntry."Document Date" := "Document Date";
            VendLedgEntry."Document Type" := "Document Type";
            VendLedgEntry."Document No." := "Document No.";
            VendLedgEntry."External Document No." := "External Document No.";
            VendLedgEntry.Description := Description;
            VendLedgEntry."Currency Code" := "Currency Code";
            VendLedgEntry."Purchase (LCY)" := "Sales/Purch. (LCY)";
            VendLedgEntry."Inv. Discount (LCY)" := "Inv. Discount (LCY)";
            VendLedgEntry."Buy-from Vendor No." := "Sell-to/Buy-from No.";
            VendLedgEntry."Vendor Posting Group" := "Posting Group";
            VendLedgEntry."Global Dimension 1 Code" := "Shortcut Dimension 1 Code";
            VendLedgEntry."Global Dimension 2 Code" := "Shortcut Dimension 2 Code";
            VendLedgEntry."Purchaser Code" := "Salespers./Purch. Code";
            VendLedgEntry."Source Code" := "Source Code";
            VendLedgEntry."On Hold" := "On Hold";
            VendLedgEntry."Applies-to Doc. Type" := "Applies-to Doc. Type";
            VendLedgEntry."Applies-to Doc. No." := "Applies-to Doc. No.";
            VendLedgEntry."Due Date" := "Due Date";
            VendLedgEntry."Pmt. Discount Date" := "Pmt. Discount Date";
            VendLedgEntry."Applies-to ID" := "Applies-to ID";
            VendLedgEntry."Journal Batch Name" := "Journal Batch Name";
            VendLedgEntry."Reason Code" := "Reason Code";
            VendLedgEntry."Entry No." := NextEntryNo;
            VendLedgEntry."Transaction No." := NextTransactionNo;
            VendLedgEntry."User ID" := USERID;
            VendLedgEntry."Bal. Account Type" := "Bal. Account Type";
            VendLedgEntry."Bal. Account No." := "Bal. Account No.";
            VendLedgEntry."No. Series" := "Posting No. Series";
            VendLedgEntry."IC Partner Code" := "IC Partner Code";
            VendLedgEntry.Prepayment := Prepayment;
            //GC++
            VendLedgEntry."Invoice Received Date" := "Invoice Received Date";
            //GC--

            //APNT-IBU1.0
            VendLedgEntry."IBU Entry" := "IBU Entry";
            VendLedgEntry."IPC Bal. Account Type" := "IPC Bal. Account Type";
            VendLedgEntry."IPC Bal. Account No." := "IPC Bal. Account No.";
            //APNT-IBU1.0

            //APNT-FIN1.0
            VendLedgEntry."Facility Type" := GenJnlLine."Facility Type";
            VendLedgEntry."Facility No." := GenJnlLine."Facility No.";
            VendLedgEntry."Charges Type" := GenJnlLine."Charges Type";
            //APNT-FIN1.0
            VendLedgEntry.Remarks := GenJnlLine.Remarks; //APNT-PV1.0
                                                         //DP6.01.01 START
            IF "Ref. Document No." <> '' THEN BEGIN
                VendLedgEntry."Ref. Document Type" := "Ref. Document Type";
                VendLedgEntry."Ref. Document No." := "Ref. Document No.";
                VendLedgEntry."Ref. Document Line No." := "Ref. Document Line No.";
            END;
            //DP6.01.01 STOP

            IF NOT Vend."Block Payment Tolerance" AND
              ((VendLedgEntry."Document Type" = VendLedgEntry."Document Type"::Invoice) OR
              (VendLedgEntry."Document Type" = VendLedgEntry."Document Type"::"Credit Memo"))
            THEN BEGIN

                IF (VendLedgEntry."Pmt. Discount Date" <> 0D) THEN
                    VendLedgEntry."Pmt. Disc. Tolerance Date" :=
                      CALCDATE(GLSetup."Payment Discount Grace Period", VendLedgEntry."Pmt. Discount Date")
                ELSE
                    VendLedgEntry."Pmt. Disc. Tolerance Date" := VendLedgEntry."Pmt. Discount Date";

                IF VendLedgEntry."Currency Code" = '' THEN BEGIN
                    IF (GLSetup."Max. Payment Tolerance Amount" <
                       (ABS(GLSetup."Payment Tolerance %" / 100 * "Amount (LCY)"))) OR (GLSetup."Payment Tolerance %" = 0)
                    THEN BEGIN
                        IF (GLSetup."Max. Payment Tolerance Amount" = 0) AND (GLSetup."Payment Tolerance %" > 0) THEN
                            VendLedgEntry."Max. Payment Tolerance" :=
                              ROUND(GLSetup."Payment Tolerance %" * "Amount (LCY)" / 100, GLSetup."Amount Rounding Precision")
                        ELSE
                            IF VendLedgEntry."Document Type" = VendLedgEntry."Document Type"::"Credit Memo" THEN
                                VendLedgEntry."Max. Payment Tolerance" := GLSetup."Max. Payment Tolerance Amount"
                            ELSE
                                VendLedgEntry."Max. Payment Tolerance" := -GLSetup."Max. Payment Tolerance Amount"
                    END ELSE
                        VendLedgEntry."Max. Payment Tolerance" :=
                          GLSetup."Payment Tolerance %" * "Amount (LCY)" / 100
                END ELSE BEGIN
                    IF (Currency."Max. Payment Tolerance Amount" <
                       (ABS(Currency."Payment Tolerance %" / 100 * Amount))) OR (Currency."Payment Tolerance %" = 0)
                    THEN BEGIN
                        IF (Currency."Max. Payment Tolerance Amount" = 0) AND (Currency."Payment Tolerance %" > 0) THEN
                            VendLedgEntry."Max. Payment Tolerance" :=
                              ROUND(Currency."Payment Tolerance %" * Amount / 100, Currency."Amount Rounding Precision")
                        ELSE
                            IF VendLedgEntry."Document Type" = VendLedgEntry."Document Type"::"Credit Memo" THEN
                                VendLedgEntry."Max. Payment Tolerance" := Currency."Max. Payment Tolerance Amount"
                            ELSE
                                VendLedgEntry."Max. Payment Tolerance" := -Currency."Max. Payment Tolerance Amount"
                    END ELSE
                        VendLedgEntry."Max. Payment Tolerance" :=
                          ROUND(Currency."Payment Tolerance %" * Amount / 100, Currency."Amount Rounding Precision");
                END;
                IF ABS(VendLedgEntry."Max. Payment Tolerance") > ABS(Amount) THEN
                    VendLedgEntry."Max. Payment Tolerance" := Amount;

            END;

            DtldCVLedgEntryBuf.DELETEALL;
            DtldCVLedgEntryBuf.INIT;
            DtldCVLedgEntryBuf."Cust. Ledger Entry No." := VendLedgEntry."Entry No.";
            DtldCVLedgEntryBuf."Entry Type" := DtldCVLedgEntryBuf."Entry Type"::"Initial Entry";
            DtldCVLedgEntryBuf."Posting Date" := "Posting Date";
            DtldCVLedgEntryBuf."Document Type" := "Document Type";
            DtldCVLedgEntryBuf."Document No." := "Document No.";
            DtldCVLedgEntryBuf.Amount := Amount;
            DtldCVLedgEntryBuf."Amount (LCY)" := "Amount (LCY)";
            DtldCVLedgEntryBuf."Additional-Currency Amount" := Amount;
            DtldCVLedgEntryBuf."Customer No." := "Account No.";
            DtldCVLedgEntryBuf."Currency Code" := "Currency Code";
            DtldCVLedgEntryBuf."User ID" := USERID;
            DtldCVLedgEntryBuf."Initial Entry Due Date" := "Due Date";
            DtldCVLedgEntryBuf."Initial Entry Global Dim. 1" := "Shortcut Dimension 1 Code";
            DtldCVLedgEntryBuf."Initial Entry Global Dim. 2" := "Shortcut Dimension 2 Code";
            DtldCVLedgEntryBuf."Initial Document Type" := "Document Type";
            //APNT-IBU1.0
            DtldCVLedgEntryBuf."IBU Entry" := "IBU Entry";
            //APNT-IBU1.0

            TransferVendLedgEntry(CVLedgEntryBuf, VendLedgEntry, TRUE);
            InsertDtldCVLedgEntry(DtldCVLedgEntryBuf, CVLedgEntryBuf, TRUE);
            CVLedgEntryBuf.Open := CVLedgEntryBuf."Remaining Amount" <> 0;
            CVLedgEntryBuf.Positive := CVLedgEntryBuf."Remaining Amount" > 0;

            IF "Amount (LCY)" <> 0 THEN BEGIN
                IF GLSetup."Pmt. Disc. Excl. VAT" THEN
                    CVLedgEntryBuf."Original Pmt. Disc. Possible" := "Sales/Purch. (LCY)" * Amount / "Amount (LCY)"
                ELSE
                    CVLedgEntryBuf."Original Pmt. Disc. Possible" := Amount;

                CVLedgEntryBuf."Original Pmt. Disc. Possible" :=
                  ROUND(
                    CVLedgEntryBuf."Original Pmt. Disc. Possible" * "Payment Discount %" / 100,
                    Currency."Amount Rounding Precision");
                CVLedgEntryBuf."Remaining Pmt. Disc. Possible" := CVLedgEntryBuf."Original Pmt. Disc. Possible";
            END;

            IF "Currency Code" <> '' THEN BEGIN
                TESTFIELD("Currency Factor");
                CVLedgEntryBuf."Adjusted Currency Factor" := "Currency Factor"
            END ELSE
                CVLedgEntryBuf."Adjusted Currency Factor" := 1;
            CVLedgEntryBuf."Original Currency Factor" := CVLedgEntryBuf."Adjusted Currency Factor";

            // Check the document no.
            IF "Recurring Method" = 0 THEN
                IF "Document Type" IN
                   ["Document Type"::Invoice,
                   "Document Type"::"Credit Memo",
                   "Document Type"::"Finance Charge Memo",
                   "Document Type"::Reminder]
                THEN BEGIN
                    // Test Internal number
                    OldVendLedgEntry.RESET;
                    IF NOT RECORDLEVELLOCKING THEN
                        OldVendLedgEntry.SETCURRENTKEY("Document No.");
                    OldVendLedgEntry.SETRANGE("Document No.", CVLedgEntryBuf."Document No.");
                    OldVendLedgEntry.SETRANGE("Document Type", CVLedgEntryBuf."Document Type");
                    IF NOT OldVendLedgEntry.ISEMPTY THEN
                        ERROR(
                          Text002,
                          CVLedgEntryBuf."Document Type", CVLedgEntryBuf."Document No.");

                    IF PurchSetup."Ext. Doc. No. Mandatory" OR
                       (CVLedgEntryBuf."External Document No." <> '')
                    THEN BEGIN
                        // Test vendor number
                        TESTFIELD("External Document No.");
                        OldVendLedgEntry.RESET;
                        IF NOT RECORDLEVELLOCKING THEN
                            OldVendLedgEntry.SETCURRENTKEY("External Document No.");
                        OldVendLedgEntry.SETRANGE("External Document No.", CVLedgEntryBuf."External Document No.");
                        OldVendLedgEntry.SETRANGE("Document Type", CVLedgEntryBuf."Document Type");
                        OldVendLedgEntry.SETRANGE("Vendor No.", CVLedgEntryBuf."CV No.");
                        IF NOT OldVendLedgEntry.ISEMPTY THEN
                            ERROR(
                              Text003,
                              CVLedgEntryBuf."Document Type", CVLedgEntryBuf."External Document No.");
                    END;
                END;

            // Post the application
            ApplyVendLedgEntry(
              CVLedgEntryBuf, DtldCVLedgEntryBuf, GenJnlLine,
              GLSetup."Appln. Rounding Precision");

            // Post Vendor entry
            TransferVendLedgEntry(CVLedgEntryBuf, VendLedgEntry, FALSE);
            VendLedgEntry."Amount to Apply" := 0;
            VendLedgEntry."Applies-to Doc. No." := '';
            VendLedgEntry.INSERT;

            DimMgt.MoveJnlLineDimToLedgEntryDim(
              TempJnlLineDim, DATABASE::"Vendor Ledger Entry", VendLedgEntry."Entry No.");

            // Post Dtld Vendor entry
            PostDtldVendLedgEntries(
              GenJnlLine, DtldCVLedgEntryBuf, VendPostingGr, NextTransactionNo, TRUE);
        END;
    end;

    local procedure PostBankAcc()
    var
        Cheques: Record "50011";
        PostedCheques: Record "50029";
        DocDim: Record "357";
        DimensionManagement: Codeunit "408";
        CompInformation: Record "79";
    begin
        WITH GenJnlLine DO BEGIN
            BankAccLedgEntry.LOCKTABLE;
            IF BankAcc."No." <> "Account No." THEN
                BankAcc.GET("Account No.");
            BankAcc.TESTFIELD(Blocked, FALSE);
            IF "Currency Code" = '' THEN
                BankAcc.TESTFIELD("Currency Code", '')
            ELSE
                IF BankAcc."Currency Code" <> '' THEN
                    TESTFIELD("Currency Code", BankAcc."Currency Code");

            BankAcc.TESTFIELD("Bank Acc. Posting Group");
            BankAccPostingGr.GET(BankAcc."Bank Acc. Posting Group");

            BankAccLedgEntry.INIT;
            BankAccLedgEntry."Bank Account No." := "Account No.";
            BankAccLedgEntry."Posting Date" := "Posting Date";
            BankAccLedgEntry."Document Date" := "Document Date";
            BankAccLedgEntry."Document Type" := "Document Type";
            BankAccLedgEntry."Document No." := "Document No.";
            //APNT-PV1.0 +
            //BankAccLedgEntry."External Document No." := "External Document No.";
            //BankAccLedgEntry."External Document No." := "Cheque No.";
            //APNT-PV1.0 -
            //APNT-PV1.0 +
            CompInformation.GET;
            IF CompInformation."Use Cheque instead of Ext. Doc" THEN BEGIN
                IF "Cheque No." <> '' THEN
                    BankAccLedgEntry."External Document No." := "Cheque No."
                ELSE
                    BankAccLedgEntry."External Document No." := "External Document No."; //T033564
            END ELSE
                BankAccLedgEntry."External Document No." := "External Document No.";
            //APNT-PV1.0 -

            BankAccLedgEntry.Description := Description;
            BankAccLedgEntry."Bank Acc. Posting Group" := BankAcc."Bank Acc. Posting Group";
            BankAccLedgEntry."Global Dimension 1 Code" := "Shortcut Dimension 1 Code";
            BankAccLedgEntry."Global Dimension 2 Code" := "Shortcut Dimension 2 Code";
            BankAccLedgEntry."Our Contact Code" := "Salespers./Purch. Code";
            BankAccLedgEntry."Source Code" := "Source Code";
            BankAccLedgEntry."Journal Batch Name" := "Journal Batch Name";
            BankAccLedgEntry."Reason Code" := "Reason Code";
            BankAccLedgEntry."Entry No." := NextEntryNo;
            BankAccLedgEntry."Transaction No." := NextTransactionNo;
            BankAccLedgEntry."Currency Code" := BankAcc."Currency Code";
            IF BankAcc."Currency Code" <> '' THEN
                BankAccLedgEntry.Amount := Amount
            ELSE
                BankAccLedgEntry.Amount := "Amount (LCY)";
            BankAccLedgEntry."Amount (LCY)" := "Amount (LCY)";
            BankAccLedgEntry."User ID" := USERID;
            IF BankAccLedgEntry.Amount <> 0 THEN BEGIN
                BankAccLedgEntry.Open := TRUE;
                BankAccLedgEntry."Remaining Amount" := BankAccLedgEntry.Amount;
            END;
            BankAccLedgEntry.Positive := BankAccLedgEntry.Amount > 0;
            BankAccLedgEntry."Bal. Account Type" := "Bal. Account Type";
            BankAccLedgEntry."Bal. Account No." := "Bal. Account No.";
            IF (Amount > 0) AND (NOT Correction) OR
               ("Amount (LCY)" > 0) AND (NOT Correction) OR
               (Amount < 0) AND Correction OR
               ("Amount (LCY)" < 0) AND Correction
            THEN BEGIN
                BankAccLedgEntry."Debit Amount" := BankAccLedgEntry.Amount;
                BankAccLedgEntry."Credit Amount" := 0;
                BankAccLedgEntry."Debit Amount (LCY)" := BankAccLedgEntry."Amount (LCY)";
                BankAccLedgEntry."Credit Amount (LCY)" := 0;
            END ELSE BEGIN
                BankAccLedgEntry."Debit Amount" := 0;
                BankAccLedgEntry."Credit Amount" := -BankAccLedgEntry.Amount;
                BankAccLedgEntry."Debit Amount (LCY)" := 0;
                BankAccLedgEntry."Credit Amount (LCY)" := -BankAccLedgEntry."Amount (LCY)";
            END;

            //APNT-FIN1.0
            BankAccLedgEntry."Charges Type" := GenJnlLine."Charges Type";
            BankAccLedgEntry."Facility Type" := GenJnlLine."Facility Type";
            BankAccLedgEntry."Facility No." := GenJnlLine."Facility No.";
            BankAccLedgEntry."LC No." := GenJnlLine."LC No.";
            BankAccLedgEntry."SG No." := GenJnlLine."SG No.";
            /*
            IF GenJnlLine."Charges Type" = GenJnlLine."Charges Type"::" " THEN BEGIN
              IF LCRec.GET(GenJnlLine."LC No.") THEN BEGIN
                LCRec."Amount Posted to Bank" += GenJnlLine.Amount;
                LCRec.MODIFY;
              END;
              IF LCRec2.GET(GenJnlLine."LC No.") THEN BEGIN
                IF LCRec2."Total LC Amount" = ABS(LCRec2."Amount Posted to Vendor") THEN BEGIN
                  LCRec2.Status := LCRec2.Status::Closed;
                  LCRec2.MODIFY;
                END;
              END;
            END;
            */

            IF (GenJnlLine."Facility Type" = GenJnlLine."Facility Type"::Cheque) AND
                                  (GenJnlLine."Facility No." <> '') THEN BEGIN
                Cheques.RESET;
                Cheques.SETCURRENTKEY("Bank No.", "Cheque Book", "Cheque No.");
                Cheques.SETRANGE("Bank No.", "Account No.");
                Cheques.SETRANGE("Cheque No.", GenJnlLine."Facility No.");
                IF Cheques.FINDFIRST THEN BEGIN
                    IF NOT PostedCheques.GET(Cheques."Entry No.") THEN BEGIN
                        PostedCheques.INIT;
                        PostedCheques.TRANSFERFIELDS(Cheques);
                        PostedCheques.Posted := TRUE;
                        PostedCheques.INSERT;

                        DocDim.RESET;
                        DocDim.SETRANGE("Table ID", DATABASE::Cheques);
                        DocDim.SETRANGE("Document No.", FORMAT(Cheques."Entry No."));
                        IF DocDim.FINDSET THEN BEGIN
                            DimensionManagement.MoveDocDimToPostedDocDim(DocDim, DATABASE::"Posted Cheques", FORMAT(Cheques."Entry No."));
                            DocDim.DELETEALL;
                        END;

                        DocDim.RESET;
                        DocDim.SETRANGE("Table ID", DATABASE::"Cheque Allocation");
                        DocDim.SETRANGE("Document No.", FORMAT(Cheques."Entry No."));
                        IF DocDim.FINDSET THEN BEGIN
                            DimensionManagement.MoveDocDimToPostedDocDim(DocDim, DATABASE::"Cheque Allocation", FORMAT(Cheques."Entry No."));
                            DocDim.DELETEALL;
                        END;
                        Cheques.DELETE;
                    END ELSE BEGIN
                        DocDim.RESET;
                        DocDim.SETRANGE("Table ID", DATABASE::Cheques);
                        DocDim.SETRANGE("Document No.", FORMAT(Cheques."Entry No."));
                        IF DocDim.FINDSET THEN
                            DocDim.DELETEALL;

                        DocDim.RESET;
                        DocDim.SETRANGE("Table ID", DATABASE::"Cheque Allocation");
                        DocDim.SETRANGE("Document No.", FORMAT(Cheques."Entry No."));
                        IF DocDim.FINDSET THEN
                            DocDim.DELETEALL;

                        Cheques.DELETE;
                    END;
                END;
            END;
            //APNT-FIN1.0

            BankAccLedgEntry.INSERT;
            DimMgt.MoveJnlLineDimToLedgEntryDim(
              TempJnlLineDim, DATABASE::"Bank Account Ledger Entry", BankAccLedgEntry."Entry No.");

            IF ((Amount <= 0) AND ("Bank Payment Type" = "Bank Payment Type"::"Computer Check") AND "Check Printed") OR
               ((Amount < 0) AND ("Bank Payment Type" = "Bank Payment Type"::"Manual Check"))
            THEN BEGIN
                IF BankAcc."Currency Code" <> "Currency Code" THEN BEGIN
                    IF NOT "Payment Voucher" THEN BEGIN //APNT-PV1.0
                        FIELDERROR(
                          "Bank Payment Type",
                          STRSUBSTNO(
                            Text004,
                            FIELDCAPTION("Currency Code"), TABLECAPTION, BankAcc.TABLECAPTION));
                    END;
                END;
                CASE "Bank Payment Type" OF
                    "Bank Payment Type"::"Computer Check":
                        BEGIN
                            TESTFIELD("Check Printed", TRUE);
                            CheckLedgEntry.LOCKTABLE;
                            CheckLedgEntry.RESET;
                            CheckLedgEntry.SETCURRENTKEY("Bank Account No.", "Entry Status", "Check No.");
                            CheckLedgEntry.SETRANGE("Bank Account No.", "Account No.");
                            CheckLedgEntry.SETRANGE("Entry Status", CheckLedgEntry."Entry Status"::Printed);
                            CheckLedgEntry.SETRANGE("Check No.", "Document No.");
                            IF CheckLedgEntry.FINDSET THEN
                                REPEAT
                                    CheckLedgEntry2 := CheckLedgEntry;
                                    CheckLedgEntry2."Entry Status" := CheckLedgEntry2."Entry Status"::Posted;
                                    CheckLedgEntry2."Bank Account Ledger Entry No." := BankAccLedgEntry."Entry No.";
                                    CheckLedgEntry2.MODIFY;
                                UNTIL CheckLedgEntry.NEXT = 0
                            //APNT-T011400 -
                            ELSE BEGIN
                                CheckLedgEntry.LOCKTABLE;
                                CheckLedgEntry.RESET;
                                CheckLedgEntry.SETCURRENTKEY("Bank Account No.", "Entry Status", "Check No.");
                                CheckLedgEntry.SETRANGE("Bank Account No.", "Account No.");
                                CheckLedgEntry.SETRANGE("Entry Status", CheckLedgEntry."Entry Status"::Printed);
                                CheckLedgEntry.SETRANGE("Check No.", "External Document No.");
                                IF CheckLedgEntry.FINDSET THEN BEGIN
                                    REPEAT
                                        CheckLedgEntry2 := CheckLedgEntry;
                                        CheckLedgEntry2."Entry Status" := CheckLedgEntry2."Entry Status"::Posted;
                                        CheckLedgEntry2."Bank Account Ledger Entry No." := BankAccLedgEntry."Entry No.";
                                        CheckLedgEntry2.MODIFY;
                                    UNTIL CheckLedgEntry.NEXT = 0;
                                END;
                            END;
                            //APNT-T011400 +
                        END;
                    "Bank Payment Type"::"Manual Check":
                        BEGIN
                            IF "Document No." = '' THEN
                                FIELDERROR(
                                  "Document No.",
                                  STRSUBSTNO(
                                    Text005,
                                    FIELDCAPTION("Bank Payment Type"), "Bank Payment Type"));
                            CheckLedgEntry.RESET;
                            IF NextCheckEntryNo = 0 THEN BEGIN
                                CheckLedgEntry.LOCKTABLE;
                                IF CheckLedgEntry.FINDLAST THEN
                                    NextCheckEntryNo := CheckLedgEntry."Entry No." + 1
                                ELSE
                                    //LS -
                                    NextCheckEntryNo := InitEntryNoInStore.GetCurrLocInitEntryNo(DATABASE::"Check Ledger Entry");
                                //NextCheckEntryNo := 1;
                                //LS +
                            END;

                            IF NOT RECORDLEVELLOCKING THEN
                                CheckLedgEntry.SETCURRENTKEY("Bank Account No.", "Entry Status", "Check No.");
                            CheckLedgEntry.SETRANGE("Bank Account No.", "Account No.");
                            CheckLedgEntry.SETFILTER(
                              "Entry Status", '%1|%2|%3',
                              CheckLedgEntry."Entry Status"::Printed,
                              CheckLedgEntry."Entry Status"::Posted,
                              CheckLedgEntry."Entry Status"::"Financially Voided");
                            CheckLedgEntry.SETRANGE("Check No.", "Document No.");
                            IF CheckLedgEntry.FINDFIRST THEN
                                ERROR(Text006, "Document No.");

                            CheckLedgEntry.INIT;
                            CheckLedgEntry."Entry No." := NextCheckEntryNo;
                            CheckLedgEntry."Bank Account No." := BankAccLedgEntry."Bank Account No.";
                            CheckLedgEntry."Bank Account Ledger Entry No." := BankAccLedgEntry."Entry No.";
                            CheckLedgEntry."Posting Date" := BankAccLedgEntry."Posting Date";
                            CheckLedgEntry."Document Type" := BankAccLedgEntry."Document Type";
                            CheckLedgEntry."Document No." := BankAccLedgEntry."Document No.";
                            CheckLedgEntry."External Document No." := BankAccLedgEntry."External Document No.";
                            CheckLedgEntry.Description := BankAccLedgEntry.Description;
                            CheckLedgEntry."Bank Payment Type" := "Bank Payment Type";
                            CheckLedgEntry."Bal. Account Type" := BankAccLedgEntry."Bal. Account Type";
                            CheckLedgEntry."Bal. Account No." := BankAccLedgEntry."Bal. Account No.";
                            CheckLedgEntry."Entry Status" := CheckLedgEntry."Entry Status"::Posted;
                            CheckLedgEntry.Open := TRUE;
                            CheckLedgEntry."User ID" := USERID;
                            CheckLedgEntry."Check Date" := BankAccLedgEntry."Posting Date";
                            CheckLedgEntry."Check No." := BankAccLedgEntry."Document No.";
                            IF BankAcc."Currency Code" <> '' THEN
                                CheckLedgEntry.Amount := -Amount
                            ELSE
                                CheckLedgEntry.Amount := -"Amount (LCY)";
                            CheckLedgEntry.INSERT;
                            NextCheckEntryNo := NextCheckEntryNo + 1;
                        END;
                END;
            END;

            BankAccPostingGr.TESTFIELD("G/L Bank Account No.");
            InitGLEntry(
              BankAccPostingGr."G/L Bank Account No.", "Amount (LCY)", "Source Currency Amount", TRUE, TRUE);
            GLEntry."Bal. Account Type" := "Bal. Account Type";
            GLEntry."Bal. Account No." := "Bal. Account No.";
            InsertGLEntry(TRUE);
        END;

    end;

    local procedure PostFixedAsset()
    var
        TempGLEntry: Record "G/L Entry";
        TempFAGLPostBuf: Record "5637";
        FAReg: Record "5617";
        FAAutomaticEntry: Codeunit "5607";
        ShortcutDim1Code: Code[20];
        ShortcutDim2Code: Code[20];
        Correction2: Boolean;
        NetDisposalNo: Integer;
    begin
        WITH GenJnlLine DO BEGIN
            //APNT-CP1.0
            StartDate := CALCDATE('-CM', "Posting Date");
            AccountingPeriod.GET(StartDate);
            AccountingPeriod.TESTFIELD("Closed Fixed Assets", FALSE);
            //APNT-CP1.0
            InitGLEntry('', "Amount (LCY)", "Source Currency Amount", TRUE, "System-Created Entry");
            GLEntry."Gen. Posting Type" := "Gen. Posting Type";
            GLEntry."Bal. Account Type" := "Bal. Account Type";
            GLEntry."Bal. Account No." := "Bal. Account No.";
            //APNT-AT1.0
            GLEntry."FA Posting Type" := "FA Posting Type";
            //APNT-AT1.0
            InitVat;
            TempGLEntry := GLEntry;
            FAJnlPostLine.GenJnlPostLine(
              GenJnlLine, TempGLEntry.Amount, TempGLEntry."VAT Amount", NextTransactionNo, NextEntryNo, TempJnlLineDim);
            ShortcutDim1Code := "Shortcut Dimension 1 Code";
            ShortcutDim2Code := "Shortcut Dimension 2 Code";
            Correction2 := Correction;
        END;
        WITH TempFAGLPostBuf DO
            IF FAJnlPostLine.FindFirstGLAcc(TempFAGLPostBuf) THEN
                REPEAT
                    GenJnlLine."Shortcut Dimension 1 Code" := "Global Dimension 1 Code";
                    GenJnlLine."Shortcut Dimension 2 Code" := "Global Dimension 2 Code";
                    GenJnlLine.Correction := Correction;
                    FADimAlreadyChecked := TempFAGLPostBuf."FA Posting Group" <> '';
                    IF "Original General Journal Line" THEN
                        InitGLEntry("Account No.", Amount, TempGLEntry."Additional-Currency Amount", TRUE, TRUE)
                    ELSE BEGIN
                        CheckNonAddCurrCodeOccurred('');
                        InitGLEntry("Account No.", Amount, 0, FALSE, TRUE);
                    END;
                    FADimAlreadyChecked := FALSE;
                    GLEntry."Gen. Posting Type" := TempGLEntry."Gen. Posting Type";
                    GLEntry."Gen. Bus. Posting Group" := TempGLEntry."Gen. Bus. Posting Group";
                    GLEntry."Gen. Prod. Posting Group" := TempGLEntry."Gen. Prod. Posting Group";
                    GLEntry."VAT Bus. Posting Group" := TempGLEntry."VAT Bus. Posting Group";
                    GLEntry."VAT Prod. Posting Group" := TempGLEntry."VAT Prod. Posting Group";
                    GLEntry."Tax Area Code" := TempGLEntry."Tax Area Code";
                    GLEntry."Tax Liable" := TempGLEntry."Tax Liable";
                    GLEntry."Tax Group Code" := TempGLEntry."Tax Group Code";
                    GLEntry."Use Tax" := TempGLEntry."Use Tax";
                    GLEntry."VAT Amount" := TempGLEntry."VAT Amount";
                    GLEntry."Bal. Account Type" := TempGLEntry."Bal. Account Type";
                    GLEntry."Bal. Account No." := TempGLEntry."Bal. Account No.";
                    GLEntry."FA Entry Type" := "FA Entry Type";
                    GLEntry."FA Entry No." := "FA Entry No.";
                    //APNT-AT1.0
                    GLEntry."FA Posting Type" := TempGLEntry."FA Posting Type";
                    //APNT-AT1.0
                    IF "Net Disposal" THEN
                        NetDisposalNo := NetDisposalNo + 1
                    ELSE
                        NetDisposalNo := 0;
                    IF "Automatic Entry" AND NOT "Net Disposal" THEN
                        FAAutomaticEntry.AdjustGLEntry(GLEntry);
                    IF NetDisposalNo > 1 THEN
                        GLEntry."VAT Amount" := 0;
                    IF TempFAGLPostBuf."FA Posting Group" <> '' THEN BEGIN
                        FAGLPostBuf := TempFAGLPostBuf;
                        FAGLPostBuf."Entry No." := NextEntryNo;
                        FAGLPostBuf.INSERT;
                    END;
                    InsertGLEntry(TRUE);
                UNTIL FAJnlPostLine.GetNextGLAcc(TempFAGLPostBuf) = 0;
        GenJnlLine."Shortcut Dimension 1 Code" := ShortcutDim1Code;
        GenJnlLine."Shortcut Dimension 2 Code" := ShortcutDim2Code;
        GenJnlLine.Correction := Correction2;
        GLEntry := TempGLEntry;
        GLEntryTmp := GLEntry;
        PostVAT;

        IF FAReg.FINDLAST THEN BEGIN
            FAReg."G/L Register No." := GLReg."No.";
            FAReg.MODIFY;
        END;
    end;

    procedure PostICPartner()
    var
        ICPartner: Record "413";
        AccountNo: Code[30];
    begin
        WITH GenJnlLine DO BEGIN
            IF GenJnlLine."Account No." <> ICPartner.Code THEN
                ICPartner.GET("Account No.");
            IF GenJnlLine.Amount > 0 THEN BEGIN
                ICPartner.TESTFIELD("Receivables Account");
                AccountNo := ICPartner."Receivables Account";
            END ELSE BEGIN
                ICPartner.TESTFIELD("Payables Account");
                AccountNo := ICPartner."Payables Account";
            END;
            InitGLEntry(AccountNo, "Amount (LCY)", "Source Currency Amount", TRUE, TRUE);
            GLEntry."Bal. Account Type" := GenJnlLine."Bal. Account Type";
            GLEntry."Bal. Account No." := GenJnlLine."Bal. Account No.";
            InsertGLEntry(TRUE);
        END;
    end;

    local procedure InitCodeUnit()
    begin
        WITH GenJnlLine DO BEGIN
            IF NextEntryNo = 0 THEN BEGIN
                GLEntry.LOCKTABLE;
                IF GLEntry.FINDLAST THEN BEGIN
                    NextEntryNo := GLEntry."Entry No." + 1;
                    NextTransactionNo := GLEntry."Transaction No." + 1;
                END ELSE BEGIN
                    //LS -
                    NextEntryNo := InitEntryNoInStore.GetCurrLocInitEntryNo(DATABASE::"G/L Entry");
                    NextTransactionNo := NextEntryNo;
                    //NextEntryNo := 1;
                    //NextTransactionNo := 1;
                    //LS +
                END;

                LastDocType := "Document Type";
                LastDocNo := "Document No.";
                LastLineNo := "Line No.";
                LastDate := "Posting Date";
                CurrentBalance := 0;

                AccountingPeriod.RESET;
                AccountingPeriod.SETCURRENTKEY(Closed);
                AccountingPeriod.SETRANGE(Closed, FALSE);
                AccountingPeriod.FINDFIRST;
                FiscalYearStartDate := AccountingPeriod."Starting Date";

                GLSetup.GET;

                SalesSetup.GET;
                PurchSetup.GET;

                IF NOT GenJnlTemplate.GET("Journal Template Name") THEN
                    GenJnlTemplate.INIT;

                VATEntry.LOCKTABLE;
                IF VATEntry.FINDLAST THEN
                    NextVATEntryNo := VATEntry."Entry No." + 1
                ELSE
                    //LS -
                    NextVATEntryNo := InitEntryNoInStore.GetCurrLocInitEntryNo(DATABASE::"VAT Entry");
                //NextVATEntryNo := 1;
                //LS +
                NextConnectionNo := 1;
                FirstNewVATEntryNo := NextVATEntryNo;

                GLReg.LOCKTABLE;
                IF GLReg.FINDLAST THEN
                    GLReg."No." := GLReg."No." + 1
                ELSE
                    //LS -
                    GLReg."No." := InitEntryNoInStore.GetCurrLocInitEntryNo(DATABASE::"G/L Register");
                //GLReg."No." := 1;
                //LS +
                GLReg.INIT;
                GLReg."From Entry No." := NextEntryNo;
                GLReg."From VAT Entry No." := NextVATEntryNo;
                GLReg."Creation Date" := TODAY;
                GLReg."Source Code" := "Source Code";
                GLReg."Journal Batch Name" := "Journal Batch Name";
                GLReg."User ID" := USERID;
            END ELSE
                IF (LastDocType <> "Document Type") OR (LastDocNo <> "Document No.") OR
                   (LastDate <> "Posting Date") OR (CurrentBalance = 0) AND NOT "System-Created Entry"
                THEN BEGIN
                    IF CheckUnrealizedCust THEN BEGIN
                        CustUnrealizedVAT(UnrealizedCustLedgEntry, UnrealizedRemainingAmountCust);
                        CheckUnrealizedCust := FALSE;
                    END;
                    IF CheckUnrealizedVend THEN BEGIN
                        VendUnrealizedVAT(UnrealizedVendLedgEntry, UnrealizedRemainingAmountVend);
                        CheckUnrealizedVend := FALSE;
                    END;
                    //APNT-IBU1.0
                    IF NOT GenJnlLine."IBU Entry" THEN
                        //APNT-IBU1.0
                        NextTransactionNo := NextTransactionNo + 1;
                    LastDocType := "Document Type";
                    LastDocNo := "Document No.";
                    LastLineNo := "Line No.";
                    LastDate := "Posting Date";
                    FirstNewVATEntryNo := NextVATEntryNo;
                END;

            GetCurrencyExchRate;
            GLEntryTmp.DELETEALL;
            IF ("Account No." <> '') AND ("Bal. Account No." = '') THEN BEGIN
                IF "VAT Posting" = "VAT Posting"::"Manual VAT Entry" THEN
                    CurrentBalance := CurrentBalance + "Amount (LCY)" + GenJnlLine."VAT Amount"
                ELSE
                    CurrentBalance := CurrentBalance + "Amount (LCY)";
            END;
            IF ("Account No." = '') AND ("Bal. Account No." <> '') THEN BEGIN
                IF "VAT Posting" = "VAT Posting"::"Manual VAT Entry" THEN
                    CurrentBalance := CurrentBalance - "Amount (LCY)" - "VAT Amount"
                ELSE
                    CurrentBalance := CurrentBalance - "Amount (LCY)";
            END;
        END;
    end;

    local procedure FinishCodeunit()
    begin
        //Unrealized VAT Check
        IF CheckUnrealizedCust AND (CurrentBalance = 0) THEN BEGIN
            CustUnrealizedVAT(UnrealizedCustLedgEntry, UnrealizedRemainingAmountCust);
            CheckUnrealizedCust := FALSE;
        END;
        IF CheckUnrealizedVend AND (CurrentBalance = 0) THEN BEGIN
            VendUnrealizedVAT(UnrealizedVendLedgEntry, UnrealizedRemainingAmountVend);
            CheckUnrealizedVend := FALSE;
        END;

        WITH GenJnlLine DO BEGIN
            IF GLEntryTmp.FINDSET THEN BEGIN
                REPEAT
                    GLEntry := GLEntryTmp;
                    IF GLSetup."Additional Reporting Currency" = '' THEN BEGIN
                        GLEntry."Additional-Currency Amount" := 0;
                        GLEntry."Add.-Currency Debit Amount" := 0;
                        GLEntry."Add.-Currency Credit Amount" := 0;
                    END;

                    //APNT-DT1.0
                    GLEntry."Created Date Time" := CURRENTDATETIME;
                    //APNT-DT1.0
                    GLEntry.INSERT;
                    IF NOT InsertFAAllocDim(GLEntry."Entry No.") THEN
                        DimMgt.MoveJnlLineDimToLedgEntryDim(
                          TempJnlLineDim, DATABASE::"G/L Entry", GLEntry."Entry No.");
                UNTIL GLEntryTmp.NEXT = 0;

                GLReg."To VAT Entry No." := NextVATEntryNo - 1;
                IF GLReg."To Entry No." = 0 THEN BEGIN
                    GLReg."To Entry No." := GLEntry."Entry No.";
                    GLReg.INSERT;
                END ELSE BEGIN
                    GLReg."To Entry No." := GLEntry."Entry No.";
                    GLReg.MODIFY;
                END;
            END;
            GLEntry.CONSISTENT(
              (BalanceCheckAmount = 0) AND (BalanceCheckAmount2 = 0) AND
              (BalanceCheckAddCurrAmount = 0) AND (BalanceCheckAddCurrAmount2 = 0));
        END;
    end;

    local procedure InitGLEntry(GLAccNo: Code[20]; Amount: Decimal; AmountAddCurr: Decimal; UseAmountAddCurr: Boolean; SystemCreatedEntry: Boolean)
    var
        TableID: array[10] of Integer;
        AccNo: array[10] of Code[20];
        JVDocumentCheck: Record "50087";
    begin
        IF GLAccNo <> '' THEN BEGIN
            GLAcc.GET(GLAccNo);
            GLAcc.TESTFIELD(Blocked, FALSE);
            GLAcc.TESTFIELD("Account Type", GLAcc."Account Type"::Posting);

            // Check the Value Posting field on the G/L Account if it is not checked already in Codeunit 11
            IF (NOT
                ((GLAccNo = GenJnlLine."Account No.") AND
                 (GenJnlLine."Account Type" = GenJnlLine."Account Type"::"G/L Account")) OR
                ((GLAccNo = GenJnlLine."Bal. Account No.") AND
                 (GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::"G/L Account"))) AND
               NOT FADimAlreadyChecked
            THEN BEGIN
                TableID[1] := DimMgt.TypeToTableID1(GenJnlLine."Account Type"::"G/L Account");
                AccNo[1] := GLAccNo;
                IF (GenJnlLine.Amount <> 0) OR (GenJnlLine."Amount (LCY)" <> 0) THEN BEGIN
                    IF NOT DimMgt.CheckJnlLineDimValuePosting(TempJnlLineDim, TableID, AccNo) THEN
                        IF GenJnlLine."Line No." <> 0 THEN
                            ERROR(
                              Text013,
                              GenJnlLine.TABLECAPTION, GenJnlLine."Journal Template Name",
                              GenJnlLine."Journal Batch Name", GenJnlLine."Line No.",
                              DimMgt.GetDimValuePostingErr)
                        ELSE
                            ERROR(DimMgt.GetDimValuePostingErr);
                END;
            END;
        END;

        GLEntry.INIT;
        GLEntry."Posting Date" := GenJnlLine."Posting Date";
        GLEntry."Document Date" := GenJnlLine."Document Date";
        GLEntry."Document Type" := GenJnlLine."Document Type";
        GLEntry."Document No." := GenJnlLine."Document No.";
        GLEntry."External Document No." := GenJnlLine."External Document No.";
        GLEntry.Description := GenJnlLine.Description;
        GLEntry."Business Unit Code" := GenJnlLine."Business Unit Code";
        GLEntry."Global Dimension 1 Code" := GenJnlLine."Shortcut Dimension 1 Code";
        GLEntry."Global Dimension 2 Code" := GenJnlLine."Shortcut Dimension 2 Code";

        //APNT-FIN1.0
        GLEntry."Facility Due Date" := GenJnlLine."Facility Due Date";
        GLEntry."Facility Type" := GenJnlLine."Facility Type";
        GLEntry."Facility No." := GenJnlLine."Facility No.";
        GLEntry."Charges Type" := GenJnlLine."Charges Type";
        GLEntry."Charge No." := FORMAT(GenJnlLine."Charge No.");
        GLEntry."Loan No." := GenJnlLine."Loan No.";
        GLEntry."Investment Type" := GenJnlLine."Investment Type";
        GLEntry."Investment No." := GenJnlLine."Investment No.";
        GLEntry."Real Estate No." := GenJnlLine."Real Estate No.";
        //APNT-FIN1.0
        GLEntry.Remarks := GenJnlLine.Remarks;//APNT-PV1.0
        GLEntry."Source Code" := GenJnlLine."Source Code";
        GLEntry."Batch No." := GenJnlLine."Batch No.";  //LS
        IF GenJnlLine."Account Type" = GenJnlLine."Account Type"::"G/L Account" THEN BEGIN
            GLEntry."Source Type" := GenJnlLine."Source Type";
            GLEntry."Source No." := GenJnlLine."Source No.";
        END ELSE BEGIN
            GLEntry."Source Type" := GenJnlLine."Account Type";
            GLEntry."Source No." := GenJnlLine."Account No.";
        END;
        IF (GenJnlLine."Account Type" = GenJnlLine."Account Type"::"IC Partner") OR
          (GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::"IC Partner")
        THEN
            GLEntry."Source Type" := GLEntry."Source Type"::" ";
        GLEntry."Job No." := GenJnlLine."Job No.";
        GLEntry.Quantity := GenJnlLine.Quantity;
        GLEntry."Journal Batch Name" := GenJnlLine."Journal Batch Name";
        GLEntry."Reason Code" := GenJnlLine."Reason Code";
        GLEntry."Entry No." := NextEntryNo;
        GLEntry."Transaction No." := NextTransactionNo;
        GLEntry."G/L Account No." := GLAccNo;
        GLEntry.Amount := Amount;
        GLEntry."User ID" := USERID;
        GLEntry."No. Series" := GenJnlLine."Posting No. Series";
        GLEntry."System-Created Entry" := SystemCreatedEntry;
        GLEntry."Prior-Year Entry" := GLEntry."Posting Date" < FiscalYearStartDate;
        GLEntry."IC Partner Code" := GenJnlLine."IC Partner Code";
        //APNT-IC1.0
        GLEntry."IC Transaction No." := GenJnlLine."IC Transaction No.";
        GLEntry."IC Partner Direction" := GenJnlLine."IC Partner Direction";
        //APNT-IC1.0
        //APNT-AT1.0
        GLEntry."FA Posting Type" := GenJnlLine."FA Posting Type";
        //APNT-AT1.0
        //APNT-HR1.0
        GLEntry."Employee No." := GenJnlLine."Employee No.";
        GLEntry."Payroll Type" := GenJnlLine."Payroll Type";
        GLEntry."Payroll Parameter" := GenJnlLine."Payroll Parameter";
        GLEntry."Payroll A/C No." := GenJnlLine."Payroll A/C No.";
        GLEntry."Bonus Accrual Entry" := GenJnlLine."Bonus Accrual Entry";
        GLEntry."Last Bonus Accrued Date" := GenJnlLine."Last Bonus Accrued Date";
        //APNT-HR1.0

        //APNT-IBU1.1 -
        IF GenJnlLine."IBU Transaction No." <> 0 THEN
            GLEntry."Transaction No." := GenJnlLine."IBU Transaction No.";
        IF GenJnlLine."IBU User ID" <> '' THEN
            GLEntry."User ID" := GenJnlLine."IBU User ID";
        //APNT-IBU1.1 +

        //DP6.01.01 START
        IF GenJnlLine."Ref. Document No." <> '' THEN BEGIN
            GLEntry."Ref. Document Type" := GenJnlLine."Ref. Document Type";
            GLEntry."Ref. Document No." := GenJnlLine."Ref. Document No.";
            GLEntry."Ref. Document Line No." := GenJnlLine."Ref. Document Line No.";
            GLEntry."Chq No." := GenJnlLine."Chq No.";
            GLEntry."Chq Date" := GenJnlLine."Chq Date";
            GLEntry."Chq Amount" := GenJnlLine."Chq Amount";
            GLEntry."Issuing Bank Name" := GenJnlLine."Issuing Bank Name";
            GLEntry."Issuing Bank Branch" := GenJnlLine."Issuing Bank Branch";
        END;
        //DP6.01.01 STOP
        //GC++
        GLEntry."Invoice Received Date" := GenJnlLine."Invoice Received Date";
        //GC--
        //APNT-1.0 -
        IF NOT JVDocumentCheck.GET(GLEntry."Entry No.") THEN BEGIN
            JVDocumentCheck.INIT;
            JVDocumentCheck."G/L Entry No." := GLEntry."Entry No.";
            JVDocumentCheck."Document No." := GLEntry."Document No.";
            JVDocumentCheck."JV Document No." := GenJnlLine."Jnl Doc. No. Before Posting";
            JVDocumentCheck.INSERT;
        END;//APNT-1.0 +

        GLCalcAddCurrency(AmountAddCurr, UseAmountAddCurr);
    end;

    local procedure InsertGLEntry(CalcAddCurrResiduals: Boolean)
    begin
        GLEntry.TESTFIELD("G/L Account No.");

        IF GLEntry.Amount <> ROUND(GLEntry.Amount) THEN
            GLEntry.FIELDERROR(
              Amount,
              STRSUBSTNO(Text000, GLEntry.Amount));

        IF GLEntry."Posting Date" = NORMALDATE(GLEntry."Posting Date") THEN BEGIN
            BalanceCheckAmount :=
              BalanceCheckAmount + GLEntry.Amount * ((GLEntry."Posting Date" - 01010000D) MOD 99 + 1);
            BalanceCheckAmount2 :=
              BalanceCheckAmount2 + GLEntry.Amount * ((GLEntry."Posting Date" - 01010000D) MOD 98 + 1);
        END ELSE BEGIN
            BalanceCheckAmount :=
              BalanceCheckAmount + GLEntry.Amount * ((NORMALDATE(GLEntry."Posting Date") - 01010000D + 50) MOD 99 + 1);
            BalanceCheckAmount2 :=
              BalanceCheckAmount2 + GLEntry.Amount * ((NORMALDATE(GLEntry."Posting Date") - 01010000D + 50) MOD 98 + 1);
        END;

        IF GLSetup."Additional Reporting Currency" <> '' THEN BEGIN
            IF GLEntry."Posting Date" = NORMALDATE(GLEntry."Posting Date") THEN BEGIN
                BalanceCheckAddCurrAmount :=
                  BalanceCheckAddCurrAmount + GLEntry."Additional-Currency Amount" * ((GLEntry."Posting Date" - 01010000D) MOD 99 + 1);
                BalanceCheckAddCurrAmount2 :=
                  BalanceCheckAddCurrAmount2 + GLEntry."Additional-Currency Amount" * ((GLEntry."Posting Date" - 01010000D) MOD 98 + 1);
            END ELSE BEGIN
                BalanceCheckAddCurrAmount :=
                  BalanceCheckAddCurrAmount +
                  GLEntry."Additional-Currency Amount" * ((NORMALDATE(GLEntry."Posting Date") - 01010000D + 50) MOD 99 + 1);
                BalanceCheckAddCurrAmount2 :=
                  BalanceCheckAddCurrAmount2 +
                  GLEntry."Additional-Currency Amount" * ((NORMALDATE(GLEntry."Posting Date") - 01010000D + 50) MOD 98 + 1);
            END;
        END ELSE BEGIN
            BalanceCheckAddCurrAmount := 0;
            BalanceCheckAddCurrAmount2 := 0;
        END;

        IF ((GLEntry.Amount > 0) AND (NOT GenJnlLine.Correction)) OR
           ((GLEntry.Amount < 0) AND GenJnlLine.Correction)
        THEN BEGIN
            GLEntry."Debit Amount" := GLEntry.Amount;
            GLEntry."Credit Amount" := 0
        END ELSE BEGIN
            GLEntry."Debit Amount" := 0;
            GLEntry."Credit Amount" := -GLEntry.Amount;
        END;

        IF ((GLEntry."Additional-Currency Amount" > 0) AND (NOT GenJnlLine.Correction)) OR
           ((GLEntry."Additional-Currency Amount" < 0) AND GenJnlLine.Correction)
        THEN BEGIN
            GLEntry."Add.-Currency Debit Amount" := GLEntry."Additional-Currency Amount";
            GLEntry."Add.-Currency Credit Amount" := 0
        END ELSE BEGIN
            GLEntry."Add.-Currency Debit Amount" := 0;
            GLEntry."Add.-Currency Credit Amount" := -GLEntry."Additional-Currency Amount";
        END;

        //APNT-DT1.0
        GLEntry."Created Date Time" := CURRENTDATETIME;
        //APNT-DT1.0

        GLEntryTmp := GLEntry;
        GLEntryTmp.INSERT;

        NextEntryNo := NextEntryNo + 1;

        IF CalcAddCurrResiduals THEN
            HandleAddCurrResidualGLEntry;
    end;

    local procedure ApplyCustLedgEntry(var NewCVLedgEntryBuf: Record "382"; var DtldCVLedgEntryBuf: Record "383"; GenJnlLine: Record "Gen. Journal Line"; ApplnRoundingPrecision: Decimal)
    var
        OldCustLedgEntry: Record "21";
        OldCVLedgEntryBuf: Record "382";
        OldCVLedgEntryBuf2: Record "382";
        NewCustLedgEntry: Record "21";
        NewCVLedgEntryBuf2: Record "382";
        OldCVLedgEntryBuf3: Record "382";
        TempOldCustLedgEntry: Record "21" temporary;
        Completed: Boolean;
        AppliedAmount: Decimal;
        AppliedAmountLCY: Decimal;
        OldAppliedAmount: Decimal;
        TempAmount: Decimal;
        NewRemainingAmtBeforeAppln: Decimal;
        OldRemainingAmtBeforeAppln: Decimal;
        ApplyingDate: Date;
        PmtTolAmtToBeApplied: Decimal;
    begin
        IF NewCVLedgEntryBuf."Amount to Apply" = 0 THEN
            EXIT;

        AllApplied := TRUE;
        IF (GenJnlLine."Applies-to Doc. No." = '') AND (GenJnlLine."Applies-to ID" = '') AND
           NOT
             ((Cust."Application Method" = Cust."Application Method"::"Apply to Oldest") AND
              GenJnlLine."Allow Application")
        THEN
            EXIT;

        PmtTolAmtToBeApplied := 0;
        NewRemainingAmtBeforeAppln := NewCVLedgEntryBuf."Remaining Amount";
        NewCVLedgEntryBuf2 := NewCVLedgEntryBuf;

        IF NewCVLedgEntryBuf."Currency Code" <> '' THEN BEGIN
            // Management of application of already posted entries
            IF NewCVLedgEntryBuf."Currency Code" <> ApplnCurrency.Code THEN
                ApplnCurrency.GET(NewCVLedgEntryBuf."Currency Code");
            ApplnRoundingPrecision := ApplnCurrency."Appln. Rounding Precision";
        END ELSE
            ApplnRoundingPrecision := GLSetup."Appln. Rounding Precision";
        ApplyingDate := GenJnlLine."Posting Date";

        IF GenJnlLine."Applies-to Doc. No." <> '' THEN BEGIN
            // Find the entry to be applied to
            OldCustLedgEntry.RESET;
            OldCustLedgEntry.SETCURRENTKEY("Document No.");
            OldCustLedgEntry.SETRANGE("Document No.", GenJnlLine."Applies-to Doc. No.");
            OldCustLedgEntry.SETRANGE("Document Type", GenJnlLine."Applies-to Doc. Type");
            OldCustLedgEntry.SETRANGE("Customer No.", NewCVLedgEntryBuf."CV No.");
            OldCustLedgEntry.SETRANGE(Open, TRUE);

            OldCustLedgEntry.FINDFIRST;
            OldCustLedgEntry.TESTFIELD(Positive, NOT NewCVLedgEntryBuf.Positive);
            IF OldCustLedgEntry."Posting Date" > ApplyingDate THEN
                ApplyingDate := OldCustLedgEntry."Posting Date";
            GenJnlApply.CheckAgainstApplnCurrency(
              NewCVLedgEntryBuf."Currency Code",
              OldCustLedgEntry."Currency Code",
              GenJnlLine."Account Type"::Customer,
              TRUE);
            TempOldCustLedgEntry := OldCustLedgEntry;
            TempOldCustLedgEntry.INSERT;
        END ELSE BEGIN
            // Find the first old entry (Invoice) which the new entry (Payment) should apply to
            OldCustLedgEntry.RESET;
            OldCustLedgEntry.SETCURRENTKEY("Customer No.", "Applies-to ID", Open, Positive, "Due Date");
            TempOldCustLedgEntry.SETCURRENTKEY("Customer No.", "Applies-to ID", Open, Positive, "Due Date");
            OldCustLedgEntry.SETRANGE("Customer No.", NewCVLedgEntryBuf."CV No.");
            OldCustLedgEntry.SETRANGE("Applies-to ID", GenJnlLine."Applies-to ID");
            OldCustLedgEntry.SETRANGE(Open, TRUE);
            OldCustLedgEntry.SETFILTER("Entry No.", '<>%1', NewCVLedgEntryBuf."Entry No.");
            IF NOT (Cust."Application Method" = Cust."Application Method"::"Apply to Oldest") THEN
                OldCustLedgEntry.SETFILTER("Amount to Apply", '<>%1', 0);

            IF Cust."Application Method" = Cust."Application Method"::"Apply to Oldest" THEN
                OldCustLedgEntry.SETFILTER("Posting Date", '..%1', GenJnlLine."Posting Date");

            // Check Cust Ledger Entry and add to Temp.
            IF SalesSetup."Appln. between Currencies" = SalesSetup."Appln. between Currencies"::None THEN
                OldCustLedgEntry.SETRANGE("Currency Code", NewCVLedgEntryBuf."Currency Code");
            IF OldCustLedgEntry.FINDSET(FALSE, FALSE) THEN
                REPEAT
                    IF GenJnlApply.CheckAgainstApplnCurrency(
                      NewCVLedgEntryBuf."Currency Code",
                      OldCustLedgEntry."Currency Code",
                      GenJnlLine."Account Type"::Customer,
                      FALSE)
                    THEN BEGIN
                        IF (OldCustLedgEntry."Posting Date" > ApplyingDate) AND (OldCustLedgEntry."Applies-to ID" <> '') THEN
                            ApplyingDate := OldCustLedgEntry."Posting Date";
                        TempOldCustLedgEntry := OldCustLedgEntry;
                        TempOldCustLedgEntry.INSERT;
                    END;
                UNTIL OldCustLedgEntry.NEXT = 0;

            TempOldCustLedgEntry.SETRANGE(Positive, NewCVLedgEntryBuf."Remaining Amount" > 0);

            IF TempOldCustLedgEntry.FIND('-') THEN BEGIN

                TempAmount := NewCVLedgEntryBuf."Remaining Amount";
                TempOldCustLedgEntry.SETRANGE(Positive);
                TempOldCustLedgEntry.FIND('-');
                REPEAT
                    TempOldCustLedgEntry.CALCFIELDS("Remaining Amount");
                    IF NewCVLedgEntryBuf."Currency Code" <> TempOldCustLedgEntry."Currency Code" THEN BEGIN
                        TempOldCustLedgEntry."Remaining Amount" :=

                          ExchAmount(
                            TempOldCustLedgEntry."Remaining Amount", TempOldCustLedgEntry."Currency Code",
                            NewCVLedgEntryBuf."Currency Code", NewCVLedgEntryBuf."Posting Date");
                        TempOldCustLedgEntry."Remaining Pmt. Disc. Possible" :=
                          ExchAmount(
                            TempOldCustLedgEntry."Remaining Pmt. Disc. Possible", TempOldCustLedgEntry."Currency Code",
                            NewCVLedgEntryBuf."Currency Code", NewCVLedgEntryBuf."Posting Date");
                        TempOldCustLedgEntry."Accepted Payment Tolerance" :=
                          ExchAmount(
                            TempOldCustLedgEntry."Accepted Payment Tolerance", TempOldCustLedgEntry."Currency Code",
                            NewCVLedgEntryBuf."Currency Code", NewCVLedgEntryBuf."Posting Date");
                        TempOldCustLedgEntry."Amount to Apply" :=
                          ExchAmount(
                            TempOldCustLedgEntry."Amount to Apply", TempOldCustLedgEntry."Currency Code",
                            NewCVLedgEntryBuf."Currency Code", NewCVLedgEntryBuf."Posting Date");

                    END;
                    IF CheckCalcPmtDiscCVCust(NewCVLedgEntryBuf, TempOldCustLedgEntry, 0, FALSE, FALSE)
                    THEN
                        TempOldCustLedgEntry."Remaining Amount" :=
                          TempOldCustLedgEntry."Remaining Amount" - TempOldCustLedgEntry."Remaining Pmt. Disc. Possible";

                    TempAmount := TempAmount + TempOldCustLedgEntry."Remaining Amount";

                UNTIL TempOldCustLedgEntry.NEXT = 0;

                TempOldCustLedgEntry.SETRANGE(Positive, TempAmount < 0);
            END ELSE
                TempOldCustLedgEntry.SETRANGE(Positive);

            IF NOT TempOldCustLedgEntry.FIND('-') THEN
                EXIT;
        END;

        GenJnlLine."Posting Date" := ApplyingDate;

        // Apply the new entry (Payment) to the old entries (Invoices) one at a time
        REPEAT
            TempOldCustLedgEntry.CALCFIELDS(
              Amount, "Amount (LCY)", "Remaining Amount", "Remaining Amt. (LCY)",
              "Original Amount", "Original Amt. (LCY)");
            TempOldCustLedgEntry.COPYFILTER(Positive, OldCVLedgEntryBuf.Positive);
            TransferCustLedgEntry(OldCVLedgEntryBuf, TempOldCustLedgEntry, TRUE);

            OldRemainingAmtBeforeAppln := OldCVLedgEntryBuf."Remaining Amount";
            OldCVLedgEntryBuf3 := OldCVLedgEntryBuf;

            // Management of posting in multiple currencies
            OldCVLedgEntryBuf2 := OldCVLedgEntryBuf;
            OldCVLedgEntryBuf.COPYFILTER(Positive, OldCVLedgEntryBuf2.Positive);

            IF NewCVLedgEntryBuf."Currency Code" <> OldCVLedgEntryBuf2."Currency Code" THEN BEGIN
                OldCVLedgEntryBuf2."Remaining Amount" :=
                  ExchAmount(
                    OldCVLedgEntryBuf2."Remaining Amount", OldCVLedgEntryBuf2."Currency Code",
                    NewCVLedgEntryBuf."Currency Code", NewCVLedgEntryBuf."Posting Date");
                OldCVLedgEntryBuf2."Remaining Pmt. Disc. Possible" :=
                  ExchAmount(
                    OldCVLedgEntryBuf2."Remaining Pmt. Disc. Possible", OldCVLedgEntryBuf2."Currency Code",
                    NewCVLedgEntryBuf."Currency Code", NewCVLedgEntryBuf."Posting Date");
                OldCVLedgEntryBuf2."Accepted Payment Tolerance" :=
                  ExchAmount(
                    OldCVLedgEntryBuf2."Accepted Payment Tolerance", OldCVLedgEntryBuf2."Currency Code",
                    NewCVLedgEntryBuf."Currency Code", NewCVLedgEntryBuf."Posting Date");
                OldCVLedgEntryBuf2."Amount to Apply" :=
                  ExchAmount(
                    OldCVLedgEntryBuf2."Amount to Apply", OldCVLedgEntryBuf2."Currency Code",
                    NewCVLedgEntryBuf."Currency Code", NewCVLedgEntryBuf."Posting Date");
            END;

            CalcPmtTolerance(
              NewCVLedgEntryBuf, OldCVLedgEntryBuf, OldCVLedgEntryBuf2, DtldCVLedgEntryBuf, GenJnlLine,
              GLSetup, PmtTolAmtToBeApplied, NextTransactionNo, FirstNewVATEntryNo);

            CalcPmtDisc(
              NewCVLedgEntryBuf, OldCVLedgEntryBuf, OldCVLedgEntryBuf2, DtldCVLedgEntryBuf, GenJnlLine,
              GLSetup, PmtTolAmtToBeApplied, ApplnRoundingPrecision, NextTransactionNo, FirstNewVATEntryNo);

            CalcPmtDiscTolerance(
              NewCVLedgEntryBuf, OldCVLedgEntryBuf, OldCVLedgEntryBuf2, DtldCVLedgEntryBuf, GenJnlLine,
              GLSetup, NextTransactionNo, FirstNewVATEntryNo);

            CalcCurrencyApplnRounding(
              NewCVLedgEntryBuf, OldCVLedgEntryBuf2, DtldCVLedgEntryBuf,
              GenJnlLine, ApplnRoundingPrecision);

            FindAmtForAppln(
              NewCVLedgEntryBuf, OldCVLedgEntryBuf, OldCVLedgEntryBuf2,
              AppliedAmount, AppliedAmountLCY, OldAppliedAmount, ApplnRoundingPrecision);

            CalcCurrencyUnrealizedGainLoss(
              OldCVLedgEntryBuf, DtldCVLedgEntryBuf, GenJnlLine, -OldAppliedAmount, OldRemainingAmtBeforeAppln);

            CalcCurrencyRealizedGainLoss(
              NewCVLedgEntryBuf, DtldCVLedgEntryBuf, GenJnlLine, AppliedAmount, AppliedAmountLCY);

            CalcCurrencyRealizedGainLoss(
              OldCVLedgEntryBuf, DtldCVLedgEntryBuf, GenJnlLine, -OldAppliedAmount, -AppliedAmountLCY);

            CalcApplication(
              NewCVLedgEntryBuf, OldCVLedgEntryBuf, DtldCVLedgEntryBuf,
              GenJnlLine, AppliedAmount, AppliedAmountLCY, OldAppliedAmount,
              NewCVLedgEntryBuf2, OldCVLedgEntryBuf3);

            CalcRemainingPmtDisc(NewCVLedgEntryBuf, OldCVLedgEntryBuf, OldCVLedgEntryBuf2);

            CalcAmtLCYAdjustment(OldCVLedgEntryBuf, DtldCVLedgEntryBuf, GenJnlLine);

            IF NOT OldCVLedgEntryBuf.Open THEN BEGIN
                UpdateCalcInterest(OldCVLedgEntryBuf);
                UpdateCalcInterest2(OldCVLedgEntryBuf, NewCVLedgEntryBuf);
            END;

            TransferCustLedgEntry(OldCVLedgEntryBuf, TempOldCustLedgEntry, FALSE);
            OldCustLedgEntry := TempOldCustLedgEntry;
            OldCustLedgEntry."Applies-to ID" := '';
            OldCustLedgEntry."Amount to Apply" := 0;
            OldCustLedgEntry.MODIFY;

            IF GLSetup."Unrealized VAT" OR
              (GLSetup."Prepayment Unrealized VAT" AND TempOldCustLedgEntry.Prepayment)
            THEN
                IF (TempOldCustLedgEntry."Document Type" IN
                     [TempOldCustLedgEntry."Document Type"::Invoice,
                      TempOldCustLedgEntry."Document Type"::"Credit Memo",
                      TempOldCustLedgEntry."Document Type"::"Finance Charge Memo",
                      TempOldCustLedgEntry."Document Type"::Reminder])
                THEN BEGIN
                    IF TempOldCustLedgEntry."Currency Code" <> NewCVLedgEntryBuf."Currency Code" THEN BEGIN
                        TempOldCustLedgEntry."Remaining Amount" :=
                          ExchAmount(
                            TempOldCustLedgEntry."Remaining Amount", NewCVLedgEntryBuf."Currency Code",
                            TempOldCustLedgEntry."Currency Code", NewCVLedgEntryBuf."Posting Date");
                        TempOldCustLedgEntry."Remaining Pmt. Disc. Possible" :=
                          ExchAmount(
                            TempOldCustLedgEntry."Remaining Pmt. Disc. Possible", NewCVLedgEntryBuf."Currency Code",
                            TempOldCustLedgEntry."Currency Code", NewCVLedgEntryBuf."Posting Date");
                        OldCVLedgEntryBuf."Accepted Payment Tolerance" :=
                          ExchAmount(
                            OldCVLedgEntryBuf."Accepted Payment Tolerance", NewCVLedgEntryBuf."Currency Code",
                            OldCVLedgEntryBuf."Currency Code", NewCVLedgEntryBuf."Posting Date");
                    END;
                    CustUnrealizedVAT(
                      TempOldCustLedgEntry,
                      ExchAmount(
                        AppliedAmount, NewCVLedgEntryBuf."Currency Code",
                        TempOldCustLedgEntry."Currency Code", NewCVLedgEntryBuf."Posting Date"));
                END;

            TempOldCustLedgEntry.DELETE;

            // Find the next old entry for application of the new entry
            IF GenJnlLine."Applies-to Doc. No." <> '' THEN
                Completed := TRUE
            ELSE
                IF TempOldCustLedgEntry.GETFILTER(TempOldCustLedgEntry.Positive) <> '' THEN BEGIN
                    IF TempOldCustLedgEntry.NEXT = 1 THEN
                        Completed := FALSE
                    ELSE BEGIN
                        TempOldCustLedgEntry.SETRANGE(Positive);
                        TempOldCustLedgEntry.FIND('-');
                        TempOldCustLedgEntry.CALCFIELDS("Remaining Amount");
                        Completed := TempOldCustLedgEntry."Remaining Amount" * NewCVLedgEntryBuf."Remaining Amount" >= 0;
                    END
                END ELSE BEGIN
                    IF NewCVLedgEntryBuf.Open THEN BEGIN
                        Completed := TempOldCustLedgEntry.NEXT = 0
                    END ELSE
                        Completed := TRUE;
                END;
        UNTIL Completed;

        DtldCVLedgEntryBuf.SETCURRENTKEY("Cust. Ledger Entry No.", "Entry Type");
        DtldCVLedgEntryBuf.SETRANGE("Cust. Ledger Entry No.", NewCVLedgEntryBuf."Entry No.");
        DtldCVLedgEntryBuf.SETRANGE(
          "Entry Type",
          DtldCVLedgEntryBuf."Entry Type"::Application);
        DtldCVLedgEntryBuf.CALCSUMS("Amount (LCY)", Amount);

        CalcCurrencyUnrealizedGainLoss(
          NewCVLedgEntryBuf, DtldCVLedgEntryBuf, GenJnlLine, DtldCVLedgEntryBuf.Amount, NewRemainingAmtBeforeAppln);

        CalcAmtLCYAdjustment(NewCVLedgEntryBuf, DtldCVLedgEntryBuf, GenJnlLine);

        NewCVLedgEntryBuf."Applies-to ID" := '';
        NewCVLedgEntryBuf."Amount to Apply" := 0;

        IF NOT NewCVLedgEntryBuf.Open THEN
            UpdateCalcInterest(NewCVLedgEntryBuf);

        IF GLSetup."Unrealized VAT" OR
          (GLSetup."Prepayment Unrealized VAT" AND NewCVLedgEntryBuf.Prepayment)
        THEN
            IF (NewCVLedgEntryBuf."Document Type" IN
                 [NewCVLedgEntryBuf."Document Type"::Invoice,
                  NewCVLedgEntryBuf."Document Type"::"Credit Memo",
                  NewCVLedgEntryBuf."Document Type"::"Finance Charge Memo",
                  NewCVLedgEntryBuf."Document Type"::Reminder]) AND
               (NewRemainingAmtBeforeAppln - NewCVLedgEntryBuf."Remaining Amount" <> 0)
            THEN BEGIN
                TransferCustLedgEntry(NewCVLedgEntryBuf, NewCustLedgEntry, FALSE);
                CheckUnrealizedCust := TRUE;
                UnrealizedCustLedgEntry := NewCustLedgEntry;
                UnrealizedRemainingAmountCust := NewCustLedgEntry."Remaining Amount" - NewRemainingAmtBeforeAppln;
            END;
    end;

    local procedure CalcPmtTolerance(var NewCVLedgEntryBuf: Record "382"; var OldCVLedgEntryBuf: Record "382"; var OldCVLedgEntryBuf2: Record "382"; var DtldCVLedgEntryBuf: Record "383"; GenJnlLine: Record "Gen. Journal Line"; GLSetup: Record "General Ledger Setup"; var PmtTolAmtToBeApplied: Decimal; NextTransactionNo: Integer; FirstNewVATEntryNo: Integer)
    var
        PmtTol: Decimal;
        PmtTolLCY: Decimal;
        PmtTolAddCurr: Decimal;
    begin
        IF Cust."Block Payment Tolerance" OR Vend."Block Payment Tolerance" THEN
            EXIT;

        IF OldCVLedgEntryBuf2."Accepted Payment Tolerance" <> 0 THEN BEGIN
            PmtTol := -OldCVLedgEntryBuf2."Accepted Payment Tolerance";
            PmtTolAmtToBeApplied := PmtTolAmtToBeApplied + PmtTol;
            PmtTolLCY :=
              ROUND(
                (NewCVLedgEntryBuf."Original Amount" + PmtTol) / NewCVLedgEntryBuf."Original Currency Factor") -
                NewCVLedgEntryBuf."Original Amt. (LCY)";

            OldCVLedgEntryBuf."Accepted Payment Tolerance" := 0;
            OldCVLedgEntryBuf."Pmt. Tolerance (LCY)" := -PmtTolLCY;

            IF NewCVLedgEntryBuf."Currency Code" = GLSetup."Additional Reporting Currency" THEN
                PmtTolAddCurr := PmtTol
            ELSE
                PmtTolAddCurr := CalcLCYToAddCurr(PmtTolLCY);

            IF NOT GLSetup."Pmt. Disc. Excl. VAT" AND GLSetup."Adjust for Payment Disc." AND (PmtTolLCY <> 0) THEN
                CalcPmtDiscIfAdjVAT(
                  NewCVLedgEntryBuf, OldCVLedgEntryBuf2,
                  DtldCVLedgEntryBuf, GenJnlLine, GLSetup, PmtTolLCY, PmtTolAddCurr,
                  NextTransactionNo, FirstNewVATEntryNo, 3);

            InitNewCVLedgEntry(DtldCVLedgEntryBuf, GenJnlLine);
            InitOldCVLedgEntry(DtldCVLedgEntryBuf, NewCVLedgEntryBuf);
            DtldCVLedgEntryBuf."Entry Type" := DtldCVLedgEntryBuf."Entry Type"::"Payment Tolerance";
            DtldCVLedgEntryBuf.Amount := PmtTol;
            DtldCVLedgEntryBuf."Amount (LCY)" := PmtTolLCY;
            DtldCVLedgEntryBuf."Additional-Currency Amount" := PmtTolAddCurr;
            InsertDtldCVLedgEntry(DtldCVLedgEntryBuf, NewCVLedgEntryBuf, FALSE);
        END;
    end;

    local procedure CalcPmtDisc(var NewCVLedgEntryBuf: Record "382"; var OldCVLedgEntryBuf: Record "382"; var OldCVLedgEntryBuf2: Record "382"; var DtldCVLedgEntryBuf: Record "383"; GenJnlLine: Record "Gen. Journal Line"; GLSetup: Record "General Ledger Setup"; PmtTolAmtToBeApplied: Decimal; ApplnRoundingPrecision: Decimal; NextTransactionNo: Integer; FirstNewVATEntryNo: Integer)
    var
        PmtDisc: Decimal;
        PmtDiscLCY: Decimal;
        PmtDiscAddCurr: Decimal;
    begin
        IF (CheckCalcPmtDisc(NewCVLedgEntryBuf, OldCVLedgEntryBuf2, ApplnRoundingPrecision, TRUE, TRUE) AND
          ((OldCVLedgEntryBuf2."Amount to Apply" = 0) OR (ABS(OldCVLedgEntryBuf2."Amount to Apply") >=
          ABS(OldCVLedgEntryBuf2."Remaining Amount" - OldCVLedgEntryBuf2."Remaining Pmt. Disc. Possible"))) OR
          (CheckCalcPmtDisc(NewCVLedgEntryBuf, OldCVLedgEntryBuf2, ApplnRoundingPrecision, FALSE, FALSE) AND
          (OldCVLedgEntryBuf2."Amount to Apply" <> 0) AND (ABS(OldCVLedgEntryBuf2."Amount to Apply") >=
          ABS(OldCVLedgEntryBuf2."Remaining Amount" - OldCVLedgEntryBuf2."Remaining Pmt. Disc. Possible")) AND
          ((ABS(NewCVLedgEntryBuf."Remaining Amount" + PmtTolAmtToBeApplied) >=
          ABS(OldCVLedgEntryBuf2."Remaining Amount" - OldCVLedgEntryBuf2."Remaining Pmt. Disc. Possible")))))
        THEN BEGIN
            PmtDisc := -OldCVLedgEntryBuf2."Remaining Pmt. Disc. Possible";
            PmtDiscLCY :=
              ROUND(
                (NewCVLedgEntryBuf."Original Amount" + PmtDisc) / NewCVLedgEntryBuf."Original Currency Factor") -
                NewCVLedgEntryBuf."Original Amt. (LCY)";

            OldCVLedgEntryBuf."Pmt. Disc. Given (LCY)" := -PmtDiscLCY;

            IF (NewCVLedgEntryBuf."Currency Code" = GLSetup."Additional Reporting Currency") AND
               (GLSetup."Additional Reporting Currency" <> '') THEN
                PmtDiscAddCurr := PmtDisc
            ELSE
                PmtDiscAddCurr := CalcLCYToAddCurr(PmtDiscLCY);

            IF NOT GLSetup."Pmt. Disc. Excl. VAT" AND GLSetup."Adjust for Payment Disc." AND
               (PmtDiscLCY <> 0)
            THEN
                CalcPmtDiscIfAdjVAT(
                  NewCVLedgEntryBuf, OldCVLedgEntryBuf2,
                  DtldCVLedgEntryBuf, GenJnlLine, GLSetup, PmtDiscLCY, PmtDiscAddCurr,
                  NextTransactionNo, FirstNewVATEntryNo, 1);

            InitNewCVLedgEntry(DtldCVLedgEntryBuf, GenJnlLine);
            InitOldCVLedgEntry(DtldCVLedgEntryBuf, NewCVLedgEntryBuf);
            DtldCVLedgEntryBuf."Entry Type" := DtldCVLedgEntryBuf."Entry Type"::"Payment Discount";
            DtldCVLedgEntryBuf.Amount := PmtDisc;
            DtldCVLedgEntryBuf."Amount (LCY)" := PmtDiscLCY;
            DtldCVLedgEntryBuf."Additional-Currency Amount" := PmtDiscAddCurr;
            InsertDtldCVLedgEntry(DtldCVLedgEntryBuf, NewCVLedgEntryBuf, FALSE);
        END;
    end;

    local procedure CalcPmtDiscIfAdjVAT(var NewCVLedgEntryBuf: Record "382"; var OldCVLedgEntryBuf: Record "382"; var DtldCVLedgEntryBuf: Record "383"; GenJnlLine: Record "Gen. Journal Line"; GLSetup: Record "General Ledger Setup"; var PmtDiscLCY2: Decimal; var PmtDiscAddCurr2: Decimal; NextTransactionNo: Integer; FirstNewVATEntryNo: Integer; EntryType: Integer)
    var
        VATEntry: Record "254";
        VATEntry2: Record "254";
        VATPostingSetup: Record "VAT Posting Setup";
        TaxJurisdiction: Record "320";
        DtldCVLedgEntryBuf2: Record "383";
        OriginalAmountAddCurr: Decimal;
        PmtDiscRounding: Decimal;
        PmtDiscRoundingAddCurr: Decimal;
        PmtDiscFactorLCY: Decimal;
        PmtDiscFactorAddCurr: Decimal;
        VATBase: Decimal;
        VATBaseAddCurr: Decimal;
        VATAmount: Decimal;
        VATAmountAddCurr: Decimal;
        TotalVATAmount: Decimal;
        TempVatEntryNo: Integer;
        LastConnectionNo: Integer;
        VatEntryModifier: Integer;
    begin
        IF OldCVLedgEntryBuf."Original Amt. (LCY)" <> 0 THEN BEGIN
            IF (GLSetup."Additional Reporting Currency" = '') OR
               (GLSetup."Additional Reporting Currency" = OldCVLedgEntryBuf."Currency Code")
            THEN
                OriginalAmountAddCurr := OldCVLedgEntryBuf.Amount
            ELSE
                OriginalAmountAddCurr := CalcLCYToAddCurr(OldCVLedgEntryBuf."Original Amt. (LCY)");
            PmtDiscRounding := PmtDiscLCY2;
            PmtDiscFactorLCY := PmtDiscLCY2 / OldCVLedgEntryBuf."Original Amt. (LCY)";
            IF OriginalAmountAddCurr <> 0 THEN
                PmtDiscFactorAddCurr := PmtDiscAddCurr2 / OriginalAmountAddCurr
            ELSE
                PmtDiscFactorAddCurr := 0;
            VATEntry2.RESET;
            VATEntry2.SETCURRENTKEY("Transaction No.");
            VATEntry2.SETRANGE("Transaction No.", OldCVLedgEntryBuf."Transaction No.");
            IF OldCVLedgEntryBuf."Transaction No." = NextTransactionNo THEN
                VATEntry2.SETRANGE("Entry No.", 0, FirstNewVATEntryNo - 1);
            IF VATEntry2.FINDSET THEN BEGIN
                TotalVATAmount := 0;
                LastConnectionNo := 0;
                REPEAT
                    VATPostingSetup.GET(VATEntry2."VAT Bus. Posting Group", VATEntry2."VAT Prod. Posting Group");
                    IF VATEntry2."VAT Calculation Type" =
                       VATEntry2."VAT Calculation Type"::"Sales Tax"
                    THEN BEGIN
                        TaxJurisdiction.GET(VATEntry2."Tax Jurisdiction Code");
                        VATPostingSetup."Adjust for Payment Discount" :=
                          TaxJurisdiction."Adjust for Payment Discount";
                    END;
                    IF VATPostingSetup."Adjust for Payment Discount" THEN BEGIN
                        IF LastConnectionNo <> VATEntry2."Sales Tax Connection No." THEN BEGIN
                            IF LastConnectionNo <> 0 THEN BEGIN
                                DtldCVLedgEntryBuf := DtldCVLedgEntryBuf2;
                                DtldCVLedgEntryBuf."VAT Amount (LCY)" := -TotalVATAmount;
                                InsertDtldCVLedgEntry(DtldCVLedgEntryBuf, NewCVLedgEntryBuf, FALSE);

                                InsertSummarizedVAT;
                            END;

                            CASE VATEntry2."VAT Calculation Type" OF
                                VATEntry2."VAT Calculation Type"::"Normal VAT",
                                VATEntry2."VAT Calculation Type"::"Reverse Charge VAT",
                                VATEntry2."VAT Calculation Type"::"Full VAT":
                                    BEGIN
                                        VATBase :=
                                          VATEntry2.Base + VATEntry2."Unrealized Base";
                                        VATBaseAddCurr :=
                                          VATEntry2."Additional-Currency Base" +
                                          VATEntry2."Add.-Currency Unrealized Base";
                                    END;
                                VATEntry2."VAT Calculation Type"::"Sales Tax":
                                    BEGIN
                                        VATEntry.RESET;
                                        VATEntry.SETCURRENTKEY(VATEntry."Transaction No.");
                                        VATEntry.SETRANGE("Transaction No.", VATEntry2."Transaction No.");
                                        VATEntry.SETRANGE("Sales Tax Connection No.", VATEntry2."Sales Tax Connection No.");
                                        VATEntry := VATEntry2;
                                        REPEAT
                                            IF VATEntry.Base < 0 THEN
                                                VATEntry.SETFILTER(Base, '>%1', VATEntry.Base)
                                            ELSE
                                                VATEntry.SETFILTER(Base, '<%1', VATEntry.Base);
                                        UNTIL NOT VATEntry.FINDLAST;
                                        VATEntry.RESET;
                                        VATBase :=
                                          VATEntry.Base + VATEntry."Unrealized Base";
                                        VATBaseAddCurr :=
                                          VATEntry."Additional-Currency Base" +
                                          VATEntry."Add.-Currency Unrealized Base";
                                    END;
                            END;

                            PmtDiscRounding := PmtDiscRounding + VATBase * PmtDiscFactorLCY;
                            VATBase := ROUND(PmtDiscRounding - PmtDiscLCY2);
                            PmtDiscLCY2 := PmtDiscLCY2 + VATBase;

                            PmtDiscRoundingAddCurr := PmtDiscRoundingAddCurr + VATBaseAddCurr * PmtDiscFactorAddCurr;
                            VATBaseAddCurr := ROUND(CalcLCYToAddCurr(VATBase), AddCurrency."Amount Rounding Precision");
                            PmtDiscAddCurr2 := PmtDiscAddCurr2 + VATBaseAddCurr;

                            DtldCVLedgEntryBuf2.INIT;
                            DtldCVLedgEntryBuf2."Posting Date" := GenJnlLine."Posting Date";
                            DtldCVLedgEntryBuf2."Document Type" := GenJnlLine."Document Type";
                            DtldCVLedgEntryBuf2."Document No." := GenJnlLine."Document No.";
                            DtldCVLedgEntryBuf2.Amount := 0;
                            DtldCVLedgEntryBuf2."Amount (LCY)" := -VATBase;
                            CASE EntryType OF
                                1:
                                    BEGIN
                                        DtldCVLedgEntryBuf2."Entry Type" :=
                                          DtldCVLedgEntryBuf2."Entry Type"::"Payment Discount (VAT Excl.)";
                                        InitOldCVLedgEntry(DtldCVLedgEntryBuf2, NewCVLedgEntryBuf);
                                        VatEntryModifier := 0;
                                    END;
                                2:
                                    BEGIN
                                        DtldCVLedgEntryBuf2."Entry Type" :=
                                          DtldCVLedgEntryBuf2."Entry Type"::"Payment Discount Tolerance (VAT Excl.)";
                                        InitOldCVLedgEntry(DtldCVLedgEntryBuf2, NewCVLedgEntryBuf);
                                        VatEntryModifier := 1000000;
                                    END;
                                3:
                                    BEGIN
                                        DtldCVLedgEntryBuf2."Entry Type" :=
                                          DtldCVLedgEntryBuf2."Entry Type"::"Payment Tolerance (VAT Excl.)";
                                        InitOldCVLedgEntry(DtldCVLedgEntryBuf2, NewCVLedgEntryBuf);
                                        VatEntryModifier := 2000000;
                                    END;
                            END;
                            // The total payment discount in currency is posted on the entry made in
                            // the function CalcPmtDisc.
                            DtldCVLedgEntryBuf2."User ID" := USERID;
                            DtldCVLedgEntryBuf2."Additional-Currency Amount" := -VATBaseAddCurr;
                            DtldCVLedgEntryBuf2."Gen. Posting Type" := VATEntry2.Type;
                            DtldCVLedgEntryBuf2."Gen. Bus. Posting Group" := VATEntry2."Gen. Bus. Posting Group";
                            DtldCVLedgEntryBuf2."Gen. Prod. Posting Group" := VATEntry2."Gen. Prod. Posting Group";
                            DtldCVLedgEntryBuf2."VAT Bus. Posting Group" := VATEntry2."VAT Bus. Posting Group";
                            DtldCVLedgEntryBuf2."VAT Prod. Posting Group" := VATEntry2."VAT Prod. Posting Group";
                            DtldCVLedgEntryBuf2."Tax Area Code" := VATEntry2."Tax Area Code";
                            DtldCVLedgEntryBuf2."Tax Liable" := VATEntry2."Tax Liable";
                            DtldCVLedgEntryBuf2."Tax Group Code" := VATEntry2."Tax Group Code";
                            DtldCVLedgEntryBuf2."Use Tax" := VATEntry2."Use Tax";
                            TotalVATAmount := 0;
                            LastConnectionNo := VATEntry2."Sales Tax Connection No.";
                        END;

                        IF (VATBase = 0) AND (VATBaseAddCurr = 0) THEN BEGIN
                            VATAmount := 0;
                            VATAmountAddCurr := 0;
                        END ELSE BEGIN
                            CASE VATEntry2."VAT Calculation Type" OF
                                VATEntry2."VAT Calculation Type"::"Normal VAT",
                                VATEntry2."VAT Calculation Type"::"Full VAT":
                                    BEGIN
                                        IF (VATEntry2.Amount + VATEntry2."Unrealized Amount" <> 0) OR
                                           (VATEntry2."Additional-Currency Amount" + VATEntry2."Add.-Currency Unrealized Amt." <> 0)
                                        THEN BEGIN
                                            IF VATBase = 0 THEN
                                                VATAmount := 0
                                            ELSE BEGIN
                                                PmtDiscRounding :=
                                                  PmtDiscRounding +
                                                  (VATEntry2.Amount + VATEntry2."Unrealized Amount") * PmtDiscFactorLCY;
                                                VATAmount := ROUND(PmtDiscRounding - PmtDiscLCY2);
                                                PmtDiscLCY2 := PmtDiscLCY2 + VATAmount;
                                            END;
                                            IF VATBaseAddCurr = 0 THEN
                                                VATAmountAddCurr := 0
                                            ELSE BEGIN
                                                VATAmountAddCurr := ROUND(CalcLCYToAddCurr(VATAmount), AddCurrency."Amount Rounding Precision");
                                                PmtDiscAddCurr2 := PmtDiscAddCurr2 + VATAmountAddCurr;
                                            END;
                                        END ELSE BEGIN
                                            VATAmount := 0;
                                            VATAmountAddCurr := 0;
                                        END;
                                    END;
                                VATEntry2."VAT Calculation Type"::"Reverse Charge VAT":
                                    BEGIN
                                        VATAmount :=
                                          ROUND((VATEntry2.Amount + VATEntry2."Unrealized Amount") * PmtDiscFactorLCY);
                                        VATAmountAddCurr := ROUND(CalcLCYToAddCurr(VATAmount), AddCurrency."Amount Rounding Precision");
                                    END;
                                VATEntry2."VAT Calculation Type"::"Sales Tax":
                                    IF (VATEntry2.Type = VATEntry2.Type::Purchase) AND VATEntry2."Use Tax" THEN BEGIN
                                        VATAmount :=
                                          ROUND((VATEntry2.Amount + VATEntry2."Unrealized Amount") * PmtDiscFactorLCY);
                                        VATAmountAddCurr := ROUND(CalcLCYToAddCurr(VATAmount), AddCurrency."Amount Rounding Precision");
                                    END ELSE BEGIN
                                        IF (VATEntry2.Amount + VATEntry2."Unrealized Amount" <> 0) OR
                                           (VATEntry2."Additional-Currency Amount" + VATEntry2."Add.-Currency Unrealized Amt." <> 0)
                                        THEN BEGIN
                                            IF VATBase = 0 THEN
                                                VATAmount := 0
                                            ELSE BEGIN
                                                PmtDiscRounding :=
                                                  PmtDiscRounding +
                                                  (VATEntry2.Amount + VATEntry2."Unrealized Amount") * PmtDiscFactorLCY;
                                                VATAmount := ROUND(PmtDiscRounding - PmtDiscLCY2);
                                                PmtDiscLCY2 := PmtDiscLCY2 + VATAmount;
                                            END;

                                            IF VATBaseAddCurr = 0 THEN
                                                VATAmountAddCurr := 0
                                            ELSE BEGIN
                                                VATAmountAddCurr := ROUND(CalcLCYToAddCurr(VATAmount), AddCurrency."Amount Rounding Precision");
                                                PmtDiscAddCurr2 := PmtDiscAddCurr2 + VATAmountAddCurr;
                                            END;
                                        END ELSE BEGIN
                                            VATAmount := 0;
                                            VATAmountAddCurr := 0;
                                        END;
                                    END;
                            END;
                        END;
                        TotalVATAmount := TotalVATAmount + VATAmount;

                        IF (PmtDiscAddCurr2 <> 0) AND (PmtDiscLCY2 = 0) THEN BEGIN
                            VATAmountAddCurr := VATAmountAddCurr - PmtDiscAddCurr2;
                            PmtDiscAddCurr2 := 0;
                        END;

                        // Post VAT
                        // VAT for VAT entry
                        IF VATEntry2.Type <> 0 THEN BEGIN
                            TempVatEntry.RESET;
                            TempVatEntry.SETRANGE("Entry No.", VatEntryModifier, VatEntryModifier + 999999);
                            IF TempVatEntry.FINDLAST THEN
                                TempVatEntryNo := TempVatEntry."Entry No." + 1
                            ELSE
                                TempVatEntryNo := VatEntryModifier + 1;
                            TempVatEntry := VATEntry2;
                            TempVatEntry."Entry No." := TempVatEntryNo;
                            TempVatEntry."Posting Date" := GenJnlLine."Posting Date";
                            TempVatEntry."Document No." := GenJnlLine."Document No.";
                            TempVatEntry."External Document No." := GenJnlLine."External Document No.";
                            TempVatEntry."Document Type" := GenJnlLine."Document Type";
                            TempVatEntry."Source Code" := GenJnlLine."Source Code";
                            TempVatEntry."Reason Code" := GenJnlLine."Reason Code";
                            TempVatEntry."Transaction No." := NextTransactionNo;
                            TempVatEntry."Sales Tax Connection No." := NextConnectionNo;
                            TempVatEntry."Unrealized Amount" := 0;
                            TempVatEntry."Unrealized Base" := 0;
                            TempVatEntry."Remaining Unrealized Amount" := 0;
                            TempVatEntry."Remaining Unrealized Base" := 0;
                            TempVatEntry."User ID" := USERID;
                            TempVatEntry."Closed by Entry No." := 0;
                            TempVatEntry.Closed := FALSE;
                            TempVatEntry."Internal Ref. No." := '';
                            TempVatEntry.Amount := VATAmount;
                            TempVatEntry."Additional-Currency Amount" := VATAmountAddCurr;
                            TempVatEntry."VAT Difference" := 0;
                            TempVatEntry."Add.-Curr. VAT Difference" := 0;
                            TempVatEntry."Add.-Currency Unrealized Amt." := 0;
                            TempVatEntry."Add.-Currency Unrealized Base" := 0;
                            IF VATEntry2."Tax on Tax" THEN BEGIN
                                TempVatEntry.Base :=
                                  ROUND((VATEntry2.Base + VATEntry2."Unrealized Base") * PmtDiscFactorLCY);
                                TempVatEntry."Additional-Currency Base" :=
                                  ROUND(
                                    (VATEntry2."Additional-Currency Base" +
                                     VATEntry2."Add.-Currency Unrealized Base") * PmtDiscFactorAddCurr,
                                    AddCurrency."Amount Rounding Precision");
                            END ELSE BEGIN
                                TempVatEntry.Base := VATBase;
                                TempVatEntry."Additional-Currency Base" := VATBaseAddCurr;
                            END;

                            IF GLSetup."Additional Reporting Currency" = '' THEN BEGIN
                                TempVatEntry."Additional-Currency Base" := 0;
                                TempVatEntry."Additional-Currency Amount" := 0;
                                TempVatEntry."Add.-Currency Unrealized Amt." := 0;
                                TempVatEntry."Add.-Currency Unrealized Base" := 0;
                            END;
                            TempVatEntry.INSERT;
                        END;

                        // VAT for G/L entry/entries
                        DtldCVLedgEntryBuf.INIT;
                        CASE EntryType OF
                            1:
                                BEGIN
                                    InitOldCVLedgEntry(DtldCVLedgEntryBuf, NewCVLedgEntryBuf);
                                    DtldCVLedgEntryBuf."Entry Type" :=
                                      DtldCVLedgEntryBuf."Entry Type"::"Payment Discount (VAT Adjustment)";
                                END;
                            2:
                                BEGIN
                                    InitOldCVLedgEntry(DtldCVLedgEntryBuf, NewCVLedgEntryBuf);
                                    DtldCVLedgEntryBuf."Entry Type" :=
                                      DtldCVLedgEntryBuf."Entry Type"::"Payment Discount Tolerance (VAT Adjustment)";
                                END;
                            3:
                                BEGIN
                                    InitOldCVLedgEntry(DtldCVLedgEntryBuf, NewCVLedgEntryBuf);
                                    DtldCVLedgEntryBuf."Entry Type" :=
                                      DtldCVLedgEntryBuf."Entry Type"::"Payment Tolerance (VAT Adjustment)";
                                END;
                        END;
                        DtldCVLedgEntryBuf."Posting Date" := GenJnlLine."Posting Date";
                        DtldCVLedgEntryBuf."Document Type" := GenJnlLine."Document Type";
                        DtldCVLedgEntryBuf."Document No." := GenJnlLine."Document No.";
                        DtldCVLedgEntryBuf.Amount := 0;
                        DtldCVLedgEntryBuf."VAT Bus. Posting Group" := VATEntry2."VAT Bus. Posting Group";
                        DtldCVLedgEntryBuf."VAT Prod. Posting Group" := VATEntry2."VAT Prod. Posting Group";
                        DtldCVLedgEntryBuf."Tax Jurisdiction Code" := VATEntry2."Tax Jurisdiction Code";
                        // The total payment discount in currency is posted on the entry made in
                        // the function CalcPmtDisc.
                        DtldCVLedgEntryBuf."User ID" := USERID;
                        DtldCVLedgEntryBuf."Use Additional-Currency Amount" := TRUE;

                        CASE VATEntry2.Type OF
                            VATEntry2.Type::Purchase:
                                BEGIN
                                    CASE VATEntry2."VAT Calculation Type" OF
                                        VATEntry2."VAT Calculation Type"::"Normal VAT",
                                        VATEntry2."VAT Calculation Type"::"Full VAT":
                                            BEGIN
                                                VATPostingSetup.TESTFIELD("Purchase VAT Account");
                                                InitGLEntry(VATPostingSetup."Purchase VAT Account", VATAmount, 0, FALSE, TRUE);
                                                GLEntry."Additional-Currency Amount" := VATAmountAddCurr;
                                                SummarizeVAT(
                                                  GLSetup."Summarize G/L Entries", GLEntry,
                                                  TempGLEntryVAT, InsertedTempGLEntryVAT);
                                                DtldCVLedgEntryBuf."Amount (LCY)" := -VATAmount;
                                                DtldCVLedgEntryBuf."Additional-Currency Amount" := -VATAmountAddCurr;
                                                InsertDtldCVLedgEntry(DtldCVLedgEntryBuf, NewCVLedgEntryBuf, TRUE);
                                            END;
                                        VATEntry2."VAT Calculation Type"::"Reverse Charge VAT":
                                            BEGIN
                                                VATPostingSetup.TESTFIELD("Purchase VAT Account");
                                                InitGLEntry(VATPostingSetup."Purchase VAT Account", VATAmount, 0, FALSE, TRUE);
                                                GLEntry."Additional-Currency Amount" := VATAmountAddCurr;
                                                SummarizeVAT(
                                                  GLSetup."Summarize G/L Entries", GLEntry,
                                                  TempGLEntryVAT, InsertedTempGLEntryVAT);
                                                VATPostingSetup.TESTFIELD("Reverse Chrg. VAT Acc.");
                                                InitGLEntry(VATPostingSetup."Reverse Chrg. VAT Acc.", -VATAmount, 0, FALSE, TRUE);
                                                GLEntry."Additional-Currency Amount" := -VATAmountAddCurr;
                                                SummarizeVAT(
                                                  GLSetup."Summarize G/L Entries", GLEntry,
                                                  TempGLEntryVAT, InsertedTempGLEntryVAT);
                                            END;
                                        VATEntry2."VAT Calculation Type"::"Sales Tax":
                                            IF (VATEntry2.Type = VATEntry2.Type::Purchase) AND VATEntry2."Use Tax" THEN BEGIN
                                                TaxJurisdiction.TESTFIELD("Tax Account (Purchases)");
                                                InitGLEntry(TaxJurisdiction."Tax Account (Purchases)", VATAmount, 0, FALSE, TRUE);
                                                GLEntry."Additional-Currency Amount" := VATAmountAddCurr;
                                                SummarizeVAT(
                                                  GLSetup."Summarize G/L Entries", GLEntry,
                                                  TempGLEntryVAT, InsertedTempGLEntryVAT);
                                                TaxJurisdiction.TESTFIELD("Reverse Charge (Purchases)");
                                                InitGLEntry(TaxJurisdiction."Reverse Charge (Purchases)", -VATAmount, 0, FALSE, TRUE);
                                                GLEntry."Additional-Currency Amount" := -VATAmountAddCurr;
                                                SummarizeVAT(
                                                  GLSetup."Summarize G/L Entries", GLEntry,
                                                  TempGLEntryVAT, InsertedTempGLEntryVAT);
                                            END ELSE BEGIN
                                                TaxJurisdiction.TESTFIELD("Tax Account (Purchases)");
                                                InitGLEntry(TaxJurisdiction."Tax Account (Purchases)", VATAmount, 0, FALSE, TRUE);
                                                GLEntry."Additional-Currency Amount" := VATAmountAddCurr;
                                                SummarizeVAT(
                                                  GLSetup."Summarize G/L Entries", GLEntry,
                                                  TempGLEntryVAT, InsertedTempGLEntryVAT);
                                                DtldCVLedgEntryBuf."Amount (LCY)" := -VATAmount;
                                                DtldCVLedgEntryBuf."Additional-Currency Amount" := -VATAmountAddCurr;
                                                InsertDtldCVLedgEntry(DtldCVLedgEntryBuf, NewCVLedgEntryBuf, TRUE);
                                            END;
                                    END;
                                END;
                            VATEntry2.Type::Sale:
                                BEGIN
                                    CASE VATEntry2."VAT Calculation Type" OF
                                        VATEntry2."VAT Calculation Type"::"Normal VAT",
                                        VATEntry2."VAT Calculation Type"::"Full VAT":
                                            BEGIN
                                                VATPostingSetup.TESTFIELD("Sales VAT Account");
                                                InitGLEntry(VATPostingSetup."Sales VAT Account", VATAmount, 0, FALSE, TRUE);
                                                GLEntry."Additional-Currency Amount" := VATAmountAddCurr;
                                                SummarizeVAT(
                                                  GLSetup."Summarize G/L Entries", GLEntry,
                                                  TempGLEntryVAT, InsertedTempGLEntryVAT);
                                                DtldCVLedgEntryBuf."Amount (LCY)" := -VATAmount;
                                                DtldCVLedgEntryBuf."Additional-Currency Amount" := -VATAmountAddCurr;
                                                InsertDtldCVLedgEntry(DtldCVLedgEntryBuf, NewCVLedgEntryBuf, TRUE);
                                            END;
                                        VATEntry2."VAT Calculation Type"::"Reverse Charge VAT":
                                            ;
                                        VATEntry2."VAT Calculation Type"::"Sales Tax":
                                            BEGIN
                                                TaxJurisdiction.TESTFIELD("Tax Account (Sales)");
                                                InitGLEntry(TaxJurisdiction."Tax Account (Sales)", VATAmount, 0, FALSE, TRUE);
                                                GLEntry."Additional-Currency Amount" := VATAmountAddCurr;
                                                SummarizeVAT(
                                                  GLSetup."Summarize G/L Entries", GLEntry,
                                                  TempGLEntryVAT, InsertedTempGLEntryVAT);
                                                DtldCVLedgEntryBuf."Amount (LCY)" := -VATAmount;
                                                DtldCVLedgEntryBuf."Additional-Currency Amount" := -VATAmountAddCurr;
                                                InsertDtldCVLedgEntry(DtldCVLedgEntryBuf, NewCVLedgEntryBuf, TRUE);
                                            END;
                                    END;
                                END;
                        END;
                    END;
                UNTIL VATEntry2.NEXT = 0;

                IF LastConnectionNo <> 0 THEN BEGIN
                    DtldCVLedgEntryBuf := DtldCVLedgEntryBuf2;
                    DtldCVLedgEntryBuf."VAT Amount (LCY)" := -TotalVATAmount;
                    InsertDtldCVLedgEntry(DtldCVLedgEntryBuf, NewCVLedgEntryBuf, FALSE);

                    InsertSummarizedVAT;
                END;
            END;
        END;
    end;

    local procedure CalcPmtDiscTolerance(var NewCVLedgEntryBuf: Record "382"; var OldCVLedgEntryBuf: Record "382"; var OldCVLedgEntryBuf2: Record "382"; var DtldCVLedgEntryBuf: Record "383"; GenJnlLine: Record "Gen. Journal Line"; GLSetup: Record "General Ledger Setup"; NextTransactionNo: Integer; FirstNewVATEntryNo: Integer)
    var
        PmtDiscTol: Decimal;
        PmtDiscTolLCY: Decimal;
        PmtDiscTolAddCurr: Decimal;
    begin
        IF Cust."Block Payment Tolerance" OR Vend."Block Payment Tolerance" THEN
            EXIT;
        IF OldCVLedgEntryBuf2."Accepted Pmt. Disc. Tolerance" = TRUE THEN BEGIN
            PmtDiscTol := -OldCVLedgEntryBuf2."Remaining Pmt. Disc. Possible";
            PmtDiscTolLCY :=
              ROUND(
                (NewCVLedgEntryBuf."Original Amount" + PmtDiscTol) / NewCVLedgEntryBuf."Original Currency Factor") -
                NewCVLedgEntryBuf."Original Amt. (LCY)";

            OldCVLedgEntryBuf."Pmt. Disc. Given (LCY)" := -PmtDiscTolLCY;

            IF NewCVLedgEntryBuf."Currency Code" = GLSetup."Additional Reporting Currency" THEN
                PmtDiscTolAddCurr := PmtDiscTol
            ELSE
                PmtDiscTolAddCurr := CalcLCYToAddCurr(PmtDiscTolLCY);

            IF NOT GLSetup."Pmt. Disc. Excl. VAT" AND GLSetup."Adjust for Payment Disc." AND (PmtDiscTolLCY <> 0) THEN
                CalcPmtDiscIfAdjVAT(
                  NewCVLedgEntryBuf, OldCVLedgEntryBuf2,
                  DtldCVLedgEntryBuf, GenJnlLine, GLSetup, PmtDiscTolLCY, PmtDiscTolAddCurr,
                  NextTransactionNo, FirstNewVATEntryNo, 2);

            InitNewCVLedgEntry(DtldCVLedgEntryBuf, GenJnlLine);
            InitOldCVLedgEntry(DtldCVLedgEntryBuf, NewCVLedgEntryBuf);
            DtldCVLedgEntryBuf."Entry Type" := DtldCVLedgEntryBuf."Entry Type"::"Payment Discount Tolerance";
            DtldCVLedgEntryBuf.Amount := PmtDiscTol;
            DtldCVLedgEntryBuf."Amount (LCY)" := PmtDiscTolLCY;
            DtldCVLedgEntryBuf."Additional-Currency Amount" := PmtDiscTolAddCurr;
            InsertDtldCVLedgEntry(DtldCVLedgEntryBuf, NewCVLedgEntryBuf, FALSE);
        END;
    end;

    local procedure CalcCurrencyApplnRounding(var NewCVLedgEntryBuf: Record "382"; var OldCVLedgEntryBuf: Record "382"; var DtldCVLedgEntryBuf: Record "383"; GenJnlLine: Record "Gen. Journal Line"; ApplnRoundingPrecision: Decimal)
    var
        ApplnRounding: Decimal;
        ApplnRoundingLCY: Decimal;
    begin
        IF ((NewCVLedgEntryBuf."Document Type" <> NewCVLedgEntryBuf."Document Type"::Payment) AND
            (NewCVLedgEntryBuf."Document Type" <> NewCVLedgEntryBuf."Document Type"::Refund)) OR
           (NewCVLedgEntryBuf."Currency Code" = OldCVLedgEntryBuf."Currency Code")
        THEN
            EXIT;

        ApplnRounding := -(NewCVLedgEntryBuf."Remaining Amount" + OldCVLedgEntryBuf."Remaining Amount");
        ApplnRoundingLCY := ROUND(ApplnRounding / NewCVLedgEntryBuf."Adjusted Currency Factor");

        IF (ApplnRounding = 0) OR (ABS(ApplnRounding) > ApplnRoundingPrecision) THEN
            EXIT;

        InitNewCVLedgEntry(DtldCVLedgEntryBuf, GenJnlLine);
        InitOldCVLedgEntry(DtldCVLedgEntryBuf, NewCVLedgEntryBuf);
        DtldCVLedgEntryBuf."Entry Type" := DtldCVLedgEntryBuf."Entry Type"::"Appln. Rounding";
        DtldCVLedgEntryBuf.Amount := ApplnRounding;
        DtldCVLedgEntryBuf."Amount (LCY)" := ApplnRoundingLCY;
        DtldCVLedgEntryBuf."Additional-Currency Amount" := ApplnRounding;
        InsertDtldCVLedgEntry(DtldCVLedgEntryBuf, NewCVLedgEntryBuf, FALSE);
    end;

    procedure FindAmtForAppln(var NewCVLedgEntryBuf: Record "382"; var OldCVLedgEntryBuf: Record "382"; var OldCVLedgEntryBuf2: Record "382"; var AppliedAmount: Decimal; var AppliedAmountLCY: Decimal; var OldAppliedAmount: Decimal; ApplnRoundingPrecision: Decimal)
    begin
        IF OldCVLedgEntryBuf2.GETFILTER(Positive) <> '' THEN BEGIN
            IF OldCVLedgEntryBuf2."Amount to Apply" <> 0 THEN
                AppliedAmount := -OldCVLedgEntryBuf2."Amount to Apply"
            ELSE
                AppliedAmount := -OldCVLedgEntryBuf2."Remaining Amount";
        END ELSE BEGIN
            IF (OldCVLedgEntryBuf2."Amount to Apply" <> 0) THEN BEGIN
                IF (CheckCalcPmtDisc(NewCVLedgEntryBuf, OldCVLedgEntryBuf2, ApplnRoundingPrecision, FALSE, FALSE) AND
                   (ABS(OldCVLedgEntryBuf2."Amount to Apply") >=
                   ABS(OldCVLedgEntryBuf2."Remaining Amount" - OldCVLedgEntryBuf2."Remaining Pmt. Disc. Possible")) AND
                   (ABS(NewCVLedgEntryBuf."Remaining Amount") >=
                     ABS(
                       ABSMin(
                         OldCVLedgEntryBuf2."Remaining Amount" - OldCVLedgEntryBuf2."Remaining Pmt. Disc. Possible",
                         OldCVLedgEntryBuf2."Amount to Apply")))) OR
                   (OldCVLedgEntryBuf."Accepted Pmt. Disc. Tolerance" = TRUE)
                THEN BEGIN
                    AppliedAmount := -OldCVLedgEntryBuf2."Remaining Amount";
                    OldCVLedgEntryBuf."Accepted Pmt. Disc. Tolerance" := FALSE;
                END ELSE
                    AppliedAmount := ABSMin(NewCVLedgEntryBuf."Remaining Amount", -OldCVLedgEntryBuf2."Amount to Apply");
            END ELSE
                AppliedAmount := ABSMin(NewCVLedgEntryBuf."Remaining Amount", -OldCVLedgEntryBuf2."Remaining Amount");
        END;

        IF (ABS(OldCVLedgEntryBuf2."Remaining Amount" - OldCVLedgEntryBuf2."Amount to Apply") < ApplnRoundingPrecision) AND
          (ApplnRoundingPrecision <> 0)
        THEN
            AppliedAmount := AppliedAmount - (OldCVLedgEntryBuf2."Remaining Amount" - OldCVLedgEntryBuf2."Amount to Apply");

        IF NewCVLedgEntryBuf."Currency Code" = OldCVLedgEntryBuf2."Currency Code" THEN BEGIN
            AppliedAmountLCY := ROUND(AppliedAmount / OldCVLedgEntryBuf."Original Currency Factor");
            OldAppliedAmount := AppliedAmount;
        END ELSE BEGIN
            // Management of posting in multiple currencies
            IF AppliedAmount = -OldCVLedgEntryBuf2."Remaining Amount" THEN
                OldAppliedAmount := -OldCVLedgEntryBuf."Remaining Amount"
            ELSE
                OldAppliedAmount :=
                  ExchAmount(
                    AppliedAmount, NewCVLedgEntryBuf."Currency Code",
                    OldCVLedgEntryBuf2."Currency Code", NewCVLedgEntryBuf."Posting Date");

            IF NewCVLedgEntryBuf."Currency Code" <> '' THEN
                // Post the realized gain or loss on the NewCVLedgEntryBuf
                AppliedAmountLCY := ROUND(OldAppliedAmount / OldCVLedgEntryBuf."Original Currency Factor")
            ELSE
                // Post the realized gain or loss on the OldCVLedgEntryBuf
                AppliedAmountLCY := ROUND(AppliedAmount / NewCVLedgEntryBuf."Original Currency Factor");
        END;
    end;

    local procedure CalcCurrencyUnrealizedGainLoss(var CVLedgEntryBuf: Record "382"; var DtldCVLedgEntryBuf: Record "383" temporary; GenJnlLine: Record "Gen. Journal Line"; AppliedAmount: Decimal; RemainingAmountBeforeAppln: Decimal)
    var
        UnRealizedGainLossLCY: Decimal;
        DtldCustLedgEntry: Record "379";
        DtldVendLedgEntry: Record "380";
    begin
        IF CVLedgEntryBuf."Currency Code" = '' THEN
            EXIT;

        // Calculate Unrealized GainLoss
        IF (GenJnlLine."Account Type" = GenJnlLine."Account Type"::Customer) THEN BEGIN
            DtldCustLedgEntry.SETCURRENTKEY("Cust. Ledger Entry No.", "Entry Type");
            DtldCustLedgEntry.SETRANGE("Cust. Ledger Entry No.", CVLedgEntryBuf."Entry No.");
            DtldCustLedgEntry.SETRANGE(
              "Entry Type",
              DtldCustLedgEntry."Entry Type"::"Unrealized Loss",
              DtldCustLedgEntry."Entry Type"::"Unrealized Gain");
            DtldCustLedgEntry.CALCSUMS("Amount (LCY)");
            UnRealizedGainLossLCY :=
              ROUND(DtldCustLedgEntry."Amount (LCY)" * ABS(AppliedAmount / RemainingAmountBeforeAppln));
        END ELSE BEGIN
            DtldVendLedgEntry.SETCURRENTKEY("Vendor Ledger Entry No.", "Entry Type");
            DtldVendLedgEntry.SETRANGE("Vendor Ledger Entry No.", CVLedgEntryBuf."Entry No.");
            DtldVendLedgEntry.SETRANGE(
              "Entry Type",
              DtldVendLedgEntry."Entry Type"::"Unrealized Loss",
              DtldVendLedgEntry."Entry Type"::"Unrealized Gain");
            DtldVendLedgEntry.CALCSUMS("Amount (LCY)");
            UnRealizedGainLossLCY :=
              ROUND(DtldVendLedgEntry."Amount (LCY)" * ABS(AppliedAmount / RemainingAmountBeforeAppln));
        END;

        IF UnRealizedGainLossLCY <> 0 THEN BEGIN
            InitNewCVLedgEntry(DtldCVLedgEntryBuf, GenJnlLine);
            InitOldCVLedgEntry(DtldCVLedgEntryBuf, CVLedgEntryBuf);
            IF UnRealizedGainLossLCY < 0 THEN BEGIN
                DtldCVLedgEntryBuf."Entry Type" := DtldCVLedgEntryBuf."Entry Type"::"Unrealized Loss";
                DtldCVLedgEntryBuf."Amount (LCY)" := -UnRealizedGainLossLCY;
                InsertDtldCVLedgEntry(DtldCVLedgEntryBuf, CVLedgEntryBuf, FALSE);
            END ELSE BEGIN
                DtldCVLedgEntryBuf."Entry Type" := DtldCVLedgEntryBuf."Entry Type"::"Unrealized Gain";
                DtldCVLedgEntryBuf."Amount (LCY)" := -UnRealizedGainLossLCY;
                InsertDtldCVLedgEntry(DtldCVLedgEntryBuf, CVLedgEntryBuf, FALSE);
            END;
        END;
    end;

    procedure CalcCurrencyRealizedGainLoss(var CVLedgEntryBuf: Record "382"; var DtldCVLedgEntryBuf: Record "383" temporary; GenJnlLine: Record "Gen. Journal Line"; AppliedAmount: Decimal; AppliedAmountLCY: Decimal)
    var
        RealizedGainLossLCY: Decimal;
    begin
        IF CVLedgEntryBuf."Currency Code" = '' THEN
            EXIT;

        // Calculate Realized GainLoss
        RealizedGainLossLCY :=
          AppliedAmountLCY - ROUND(AppliedAmount / CVLedgEntryBuf."Original Currency Factor");
        IF RealizedGainLossLCY <> 0 THEN BEGIN
            InitNewCVLedgEntry(DtldCVLedgEntryBuf, GenJnlLine);
            InitOldCVLedgEntry(DtldCVLedgEntryBuf, CVLedgEntryBuf);
            IF RealizedGainLossLCY < 0 THEN BEGIN
                DtldCVLedgEntryBuf."Entry Type" := DtldCVLedgEntryBuf."Entry Type"::"Realized Loss";
                DtldCVLedgEntryBuf."Amount (LCY)" := RealizedGainLossLCY;
                InsertDtldCVLedgEntry(DtldCVLedgEntryBuf, CVLedgEntryBuf, FALSE);
            END ELSE BEGIN
                DtldCVLedgEntryBuf."Entry Type" := DtldCVLedgEntryBuf."Entry Type"::"Realized Gain";
                DtldCVLedgEntryBuf."Amount (LCY)" := RealizedGainLossLCY;
                InsertDtldCVLedgEntry(DtldCVLedgEntryBuf, CVLedgEntryBuf, FALSE);
            END;
        END;
    end;

    local procedure CalcApplication(var NewCVLedgEntryBuf: Record "382"; var OldCVLedgEntryBuf: Record "382"; var DtldCVLedgEntryBuf: Record "383"; GenJnlLine: Record "Gen. Journal Line"; AppliedAmount: Decimal; AppliedAmountLCY: Decimal; OldAppliedAmount: Decimal; PrevNewCVLedgEntryBuf: Record "382"; PrevOldCVLedgEntryBuf: Record "382")
    begin
        IF AppliedAmount = 0 THEN
            EXIT;

        InitNewCVLedgEntry(DtldCVLedgEntryBuf, GenJnlLine);
        InitOldCVLedgEntry(DtldCVLedgEntryBuf, OldCVLedgEntryBuf);
        DtldCVLedgEntryBuf."Entry Type" := DtldCVLedgEntryBuf."Entry Type"::Application;
        DtldCVLedgEntryBuf.Amount := OldAppliedAmount;
        DtldCVLedgEntryBuf."Amount (LCY)" := AppliedAmountLCY;
        DtldCVLedgEntryBuf."Applied CV Ledger Entry No." := NewCVLedgEntryBuf."Entry No.";
        DtldCVLedgEntryBuf."Remaining Pmt. Disc. Possible" :=
          PrevOldCVLedgEntryBuf."Remaining Pmt. Disc. Possible";
        DtldCVLedgEntryBuf."Max. Payment Tolerance" := PrevOldCVLedgEntryBuf."Max. Payment Tolerance";
        InsertDtldCVLedgEntry(DtldCVLedgEntryBuf, OldCVLedgEntryBuf, FALSE);

        OldCVLedgEntryBuf.Open := OldCVLedgEntryBuf."Remaining Amount" <> 0;
        IF NOT OldCVLedgEntryBuf.Open THEN BEGIN
            OldCVLedgEntryBuf."Closed by Entry No." := NewCVLedgEntryBuf."Entry No.";
            OldCVLedgEntryBuf."Closed at Date" := GenJnlLine."Posting Date";
            OldCVLedgEntryBuf."Closed by Amount" := -OldAppliedAmount;
            OldCVLedgEntryBuf."Closed by Amount (LCY)" := -AppliedAmountLCY;
            OldCVLedgEntryBuf."Closed by Currency Code" := NewCVLedgEntryBuf."Currency Code";
            OldCVLedgEntryBuf."Closed by Currency Amount" := -AppliedAmount;
        END ELSE
            AllApplied := FALSE;

        InitNewCVLedgEntry(DtldCVLedgEntryBuf, GenJnlLine);
        InitOldCVLedgEntry(DtldCVLedgEntryBuf, NewCVLedgEntryBuf);
        DtldCVLedgEntryBuf."Entry Type" := DtldCVLedgEntryBuf."Entry Type"::Application;
        DtldCVLedgEntryBuf.Amount := -AppliedAmount;
        DtldCVLedgEntryBuf."Amount (LCY)" := -AppliedAmountLCY;
        DtldCVLedgEntryBuf."Applied CV Ledger Entry No." := NewCVLedgEntryBuf."Entry No.";
        DtldCVLedgEntryBuf."Remaining Pmt. Disc. Possible" :=
          PrevNewCVLedgEntryBuf."Remaining Pmt. Disc. Possible";
        DtldCVLedgEntryBuf."Max. Payment Tolerance" := PrevNewCVLedgEntryBuf."Max. Payment Tolerance";
        InsertDtldCVLedgEntry(DtldCVLedgEntryBuf, NewCVLedgEntryBuf, FALSE);

        NewCVLedgEntryBuf.Open := NewCVLedgEntryBuf."Remaining Amount" <> 0;
        IF NOT NewCVLedgEntryBuf.Open AND NOT AllApplied THEN BEGIN
            NewCVLedgEntryBuf."Closed by Entry No." := OldCVLedgEntryBuf."Entry No.";
            NewCVLedgEntryBuf."Closed at Date" := GenJnlLine."Posting Date";
            NewCVLedgEntryBuf."Closed by Amount" := AppliedAmount;
            NewCVLedgEntryBuf."Closed by Amount (LCY)" := AppliedAmountLCY;
            NewCVLedgEntryBuf."Closed by Currency Code" := OldCVLedgEntryBuf."Currency Code";
            NewCVLedgEntryBuf."Closed by Currency Amount" := OldAppliedAmount;
        END;
    end;

    procedure CalcRemainingPmtDisc(var NewCVLedgEntryBuf: Record "382"; var OldCVLedgEntryBuf: Record "382"; var OldCVLedgEntryBuf2: Record "382")
    var
        TempOldCVLedgEntryBuf2: Record "382";
    begin
        IF ((((NewCVLedgEntryBuf."Document Type" = NewCVLedgEntryBuf."Document Type"::"Credit Memo") OR
            (NewCVLedgEntryBuf."Document Type" = NewCVLedgEntryBuf."Document Type"::Invoice)) AND
            ((OldCVLedgEntryBuf."Document Type" = OldCVLedgEntryBuf."Document Type"::Invoice) OR
            (OldCVLedgEntryBuf."Document Type" = OldCVLedgEntryBuf."Document Type"::"Credit Memo"))) AND
            ((OldCVLedgEntryBuf."Remaining Pmt. Disc. Possible" <> 0) AND
            (NewCVLedgEntryBuf."Remaining Pmt. Disc. Possible" <> 0)) OR
            ((OldCVLedgEntryBuf."Document Type" = OldCVLedgEntryBuf."Document Type"::"Credit Memo") AND
            (OldCVLedgEntryBuf."Remaining Pmt. Disc. Possible" <> 0) AND
            (NewCVLedgEntryBuf."Document Type" <> NewCVLedgEntryBuf."Document Type"::Refund)))
        THEN BEGIN
            TempOldCVLedgEntryBuf2 := OldCVLedgEntryBuf2;
            OldCVLedgEntryBuf2."Remaining Pmt. Disc. Possible" :=
              ROUND(OldCVLedgEntryBuf."Original Pmt. Disc. Possible" *
                (OldCVLedgEntryBuf."Remaining Amount" / OldCVLedgEntryBuf."Original Amount"),
                GLSetup."Amount Rounding Precision");
            NewCVLedgEntryBuf."Remaining Pmt. Disc. Possible" :=
              ROUND(NewCVLedgEntryBuf."Original Pmt. Disc. Possible" *
                (NewCVLedgEntryBuf."Remaining Amount" / NewCVLedgEntryBuf."Original Amount"),
                GLSetup."Amount Rounding Precision");

            IF NewCVLedgEntryBuf."Currency Code" = OldCVLedgEntryBuf2."Currency Code" THEN
                OldCVLedgEntryBuf."Remaining Pmt. Disc. Possible" :=
                  OldCVLedgEntryBuf2."Remaining Pmt. Disc. Possible"
            ELSE
                // Management of posting in multiple currencies
                IF OldCVLedgEntryBuf2."Remaining Pmt. Disc. Possible" = 0 THEN
                    OldCVLedgEntryBuf."Remaining Pmt. Disc. Possible" := 0
                ELSE
                    OldCVLedgEntryBuf."Remaining Pmt. Disc. Possible" :=
                      OldCVLedgEntryBuf2."Remaining Pmt. Disc. Possible";
        END;

        IF (OldCVLedgEntryBuf."Document Type" = OldCVLedgEntryBuf."Document Type"::Invoice) OR
          (OldCVLedgEntryBuf."Document Type" = OldCVLedgEntryBuf."Document Type"::"Credit Memo")
        THEN
            IF ABS(OldCVLedgEntryBuf."Remaining Amount") < ABS(OldCVLedgEntryBuf."Max. Payment Tolerance") THEN
                OldCVLedgEntryBuf."Max. Payment Tolerance" := OldCVLedgEntryBuf."Remaining Amount";

        IF NOT NewCVLedgEntryBuf.Open THEN BEGIN
            NewCVLedgEntryBuf."Remaining Pmt. Disc. Possible" := 0;
            NewCVLedgEntryBuf."Max. Payment Tolerance" := 0;
        END;

        IF NOT OldCVLedgEntryBuf.Open THEN BEGIN
            OldCVLedgEntryBuf."Remaining Pmt. Disc. Possible" := 0;
            OldCVLedgEntryBuf."Max. Payment Tolerance" := 0;
        END;
    end;

    local procedure CalcAmtLCYAdjustment(var CVLedgEntryBuf: Record "382"; var DtldCVLedgEntryBuf: Record "383"; GenJnlLine: Record "Gen. Journal Line")
    var
        AdjustedAmountLCY: Decimal;
    begin
        IF CVLedgEntryBuf."Currency Code" = '' THEN
            EXIT;

        AdjustedAmountLCY :=
          ROUND(CVLedgEntryBuf."Remaining Amount" / CVLedgEntryBuf."Adjusted Currency Factor");

        IF AdjustedAmountLCY <> CVLedgEntryBuf."Remaining Amt. (LCY)" THEN BEGIN
            InitNewCVLedgEntry(DtldCVLedgEntryBuf, GenJnlLine);
            InitOldCVLedgEntry(DtldCVLedgEntryBuf, CVLedgEntryBuf);
            DtldCVLedgEntryBuf."Entry Type" :=
              DtldCVLedgEntryBuf."Entry Type"::"Correction of Remaining Amount";
            DtldCVLedgEntryBuf."Amount (LCY)" := AdjustedAmountLCY - CVLedgEntryBuf."Remaining Amt. (LCY)";
            InsertDtldCVLedgEntry(DtldCVLedgEntryBuf, CVLedgEntryBuf, FALSE);
        END;
    end;

    procedure InitNewCVLedgEntry(var InitDtldCVLedgEntryBuf: Record "383"; GenJnlLine: Record "Gen. Journal Line")
    begin
        InitDtldCVLedgEntryBuf.INIT;
        InitDtldCVLedgEntryBuf."Posting Date" := GenJnlLine."Posting Date";
        InitDtldCVLedgEntryBuf."Document Type" := GenJnlLine."Document Type";
        InitDtldCVLedgEntryBuf."Document No." := GenJnlLine."Document No.";
        InitDtldCVLedgEntryBuf."User ID" := USERID;
    end;

    procedure InitOldCVLedgEntry(var InitDtldCVLedgEntryBuf: Record "383"; OldCVLedgEntryBuf: Record "382")
    begin
        InitDtldCVLedgEntryBuf."Cust. Ledger Entry No." := OldCVLedgEntryBuf."Entry No.";
        InitDtldCVLedgEntryBuf."Customer No." := OldCVLedgEntryBuf."CV No.";
        InitDtldCVLedgEntryBuf."Currency Code" := OldCVLedgEntryBuf."Currency Code";
        InitDtldCVLedgEntryBuf."Initial Entry Due Date" := OldCVLedgEntryBuf."Due Date";
        InitDtldCVLedgEntryBuf."Initial Entry Global Dim. 1" := OldCVLedgEntryBuf."Global Dimension 1 Code";
        InitDtldCVLedgEntryBuf."Initial Entry Global Dim. 2" := OldCVLedgEntryBuf."Global Dimension 2 Code";
        InitDtldCVLedgEntryBuf."Initial Document Type" := OldCVLedgEntryBuf."Document Type";
    end;

    local procedure InsertDtldCVLedgEntry(var DtldCVLedgEntryBuf: Record "383"; var CVLedgEntryBuf: Record "382"; InsertZeroAmout: Boolean)
    var
        NewDtldCVLedgEntryBuf: Record "383";
        NextDtldBufferEntryNo: Integer;
    begin
        IF (DtldCVLedgEntryBuf.Amount = 0) AND
           (DtldCVLedgEntryBuf."Amount (LCY)" = 0) AND
           (DtldCVLedgEntryBuf."Additional-Currency Amount" = 0) AND
           (NOT InsertZeroAmout)
        THEN
            EXIT;

        DtldCVLedgEntryBuf.TESTFIELD("Entry Type");

        NewDtldCVLedgEntryBuf.INIT;
        NewDtldCVLedgEntryBuf := DtldCVLedgEntryBuf;

        IF NextDtldBufferEntryNo = 0 THEN BEGIN
            DtldCVLedgEntryBuf.RESET;
            IF DtldCVLedgEntryBuf.FINDLAST THEN
                NextDtldBufferEntryNo := DtldCVLedgEntryBuf."Entry No." + 1
            ELSE
                NextDtldBufferEntryNo := 1;
        END;

        DtldCVLedgEntryBuf.RESET;
        DtldCVLedgEntryBuf.SETRANGE("Cust. Ledger Entry No.", CVLedgEntryBuf."Entry No.");
        DtldCVLedgEntryBuf.SETRANGE("Entry Type", NewDtldCVLedgEntryBuf."Entry Type");
        DtldCVLedgEntryBuf.SETRANGE("Posting Date", NewDtldCVLedgEntryBuf."Posting Date");
        DtldCVLedgEntryBuf.SETRANGE("Document Type", NewDtldCVLedgEntryBuf."Document Type");
        DtldCVLedgEntryBuf.SETRANGE("Document No.", NewDtldCVLedgEntryBuf."Document No.");
        DtldCVLedgEntryBuf.SETRANGE("Customer No.", NewDtldCVLedgEntryBuf."Customer No.");
        DtldCVLedgEntryBuf.SETRANGE("Gen. Posting Type", NewDtldCVLedgEntryBuf."Gen. Posting Type");
        DtldCVLedgEntryBuf.SETRANGE(
          "Gen. Bus. Posting Group", NewDtldCVLedgEntryBuf."Gen. Bus. Posting Group");
        DtldCVLedgEntryBuf.SETRANGE(
          "Gen. Prod. Posting Group", NewDtldCVLedgEntryBuf."Gen. Prod. Posting Group");
        DtldCVLedgEntryBuf.SETRANGE(
          "VAT Bus. Posting Group", NewDtldCVLedgEntryBuf."VAT Bus. Posting Group");
        DtldCVLedgEntryBuf.SETRANGE(
          "VAT Prod. Posting Group", NewDtldCVLedgEntryBuf."VAT Prod. Posting Group");
        DtldCVLedgEntryBuf.SETRANGE("Tax Area Code", NewDtldCVLedgEntryBuf."Tax Area Code");
        DtldCVLedgEntryBuf.SETRANGE("Tax Liable", NewDtldCVLedgEntryBuf."Tax Liable");
        DtldCVLedgEntryBuf.SETRANGE("Tax Group Code", NewDtldCVLedgEntryBuf."Tax Group Code");
        DtldCVLedgEntryBuf.SETRANGE("Use Tax", NewDtldCVLedgEntryBuf."Use Tax");
        DtldCVLedgEntryBuf.SETRANGE(
          "Tax Jurisdiction Code", NewDtldCVLedgEntryBuf."Tax Jurisdiction Code");

        IF DtldCVLedgEntryBuf.FINDFIRST THEN BEGIN
            DtldCVLedgEntryBuf.Amount := DtldCVLedgEntryBuf.Amount + NewDtldCVLedgEntryBuf.Amount;
            DtldCVLedgEntryBuf."Amount (LCY)" :=
              DtldCVLedgEntryBuf."Amount (LCY)" + NewDtldCVLedgEntryBuf."Amount (LCY)";
            DtldCVLedgEntryBuf."VAT Amount (LCY)" :=
              DtldCVLedgEntryBuf."VAT Amount (LCY)" + NewDtldCVLedgEntryBuf."VAT Amount (LCY)";
            DtldCVLedgEntryBuf."Additional-Currency Amount" :=
              DtldCVLedgEntryBuf."Additional-Currency Amount" +
              NewDtldCVLedgEntryBuf."Additional-Currency Amount";
            DtldCVLedgEntryBuf.MODIFY;
        END ELSE BEGIN
            NewDtldCVLedgEntryBuf."Entry No." := NextDtldBufferEntryNo;
            NextDtldBufferEntryNo := NextDtldBufferEntryNo + 1;
            DtldCVLedgEntryBuf := NewDtldCVLedgEntryBuf;
            DtldCVLedgEntryBuf.INSERT;
        END;

        CVLedgEntryBuf."Amount to Apply" := NewDtldCVLedgEntryBuf.Amount + CVLedgEntryBuf."Amount to Apply";
        CVLedgEntryBuf."Remaining Amount" := NewDtldCVLedgEntryBuf.Amount + CVLedgEntryBuf."Remaining Amount";
        CVLedgEntryBuf."Remaining Amt. (LCY)" :=
          NewDtldCVLedgEntryBuf."Amount (LCY)" + CVLedgEntryBuf."Remaining Amt. (LCY)";

        IF DtldCVLedgEntryBuf."Entry Type" = DtldCVLedgEntryBuf."Entry Type"::"Initial Entry" THEN BEGIN
            CVLedgEntryBuf."Original Amount" := NewDtldCVLedgEntryBuf.Amount;
            CVLedgEntryBuf."Original Amt. (LCY)" := NewDtldCVLedgEntryBuf."Amount (LCY)";
        END;
        DtldCVLedgEntryBuf.RESET;
    end;

    local procedure CustUnrealizedVAT(var CustLedgEntry2: Record "21"; SettledAmount: Decimal)
    var
        VATEntry2: Record "254";
        VATPart: Decimal;
        VATAmount: Decimal;
        VATBase: Decimal;
        VATAmountAddCurr: Decimal;
        VATBaseAddCurr: Decimal;
        PaidAmount: Decimal;
        TotalUnrealVATAmountLast: Decimal;
        TotalUnrealVATAmountFirst: Decimal;
        SalesVATAccount: Code[20];
        SalesVATUnrealAccount: Code[20];
        LastConnectionNo: Integer;
    begin
        PaidAmount := CustLedgEntry2."Amount (LCY)" - CustLedgEntry2."Remaining Amt. (LCY)";
        VATEntry2.RESET;
        VATEntry2.SETCURRENTKEY("Transaction No.");
        VATEntry2.SETRANGE("Transaction No.", CustLedgEntry2."Transaction No.");
        IF VATEntry2.FINDSET THEN
            REPEAT
                IF (VATPostingSetup."VAT Bus. Posting Group" <> VATEntry2."VAT Bus. Posting Group") OR
                   (VATPostingSetup."VAT Prod. Posting Group" <> VATEntry2."VAT Prod. Posting Group")
                THEN
                    VATPostingSetup.GET(VATEntry2."VAT Bus. Posting Group", VATEntry2."VAT Prod. Posting Group");
                IF VATPostingSetup."Unrealized VAT Type" IN
                  [VATPostingSetup."Unrealized VAT Type"::Last, VATPostingSetup."Unrealized VAT Type"::"Last (Fully Paid)"] THEN
                    TotalUnrealVATAmountLast := TotalUnrealVATAmountLast - VATEntry2."Remaining Unrealized Amount";
                IF VATPostingSetup."Unrealized VAT Type" IN
                  [VATPostingSetup."Unrealized VAT Type"::First, VATPostingSetup."Unrealized VAT Type"::"First (Fully Paid)"] THEN
                    TotalUnrealVATAmountFirst := TotalUnrealVATAmountFirst - VATEntry2."Remaining Unrealized Amount";
            UNTIL VATEntry2.NEXT = 0;
        IF VATEntry2.FINDSET THEN BEGIN
            LastConnectionNo := 0;
            REPEAT
                IF (VATPostingSetup."VAT Bus. Posting Group" <> VATEntry2."VAT Bus. Posting Group") OR
                   (VATPostingSetup."VAT Prod. Posting Group" <> VATEntry2."VAT Prod. Posting Group")
                THEN
                    VATPostingSetup.GET(VATEntry2."VAT Bus. Posting Group", VATEntry2."VAT Prod. Posting Group");
                IF LastConnectionNo <> VATEntry2."Sales Tax Connection No." THEN BEGIN
                    InsertSummarizedVAT;
                    LastConnectionNo := VATEntry2."Sales Tax Connection No.";
                END;

                VATPart :=
                  VATEntry2.GetUnRealizedVATPart(
                    ROUND(SettledAmount / CustLedgEntry2.GetOriginalCurrencyFactor),
                    PaidAmount,
                    CustLedgEntry2."Original Amt. (LCY)",
                    TotalUnrealVATAmountFirst,
                    TotalUnrealVATAmountLast);

                IF VATPart > 0 THEN BEGIN
                    CASE VATEntry2."VAT Calculation Type" OF
                        VATEntry2."VAT Calculation Type"::"Normal VAT",
                        VATEntry2."VAT Calculation Type"::"Reverse Charge VAT",
                        VATEntry2."VAT Calculation Type"::"Full VAT":
                            BEGIN
                                VATPostingSetup.TESTFIELD("Sales VAT Account");
                                VATPostingSetup.TESTFIELD("Sales VAT Unreal. Account");
                                SalesVATAccount := VATPostingSetup."Sales VAT Account";
                                SalesVATUnrealAccount := VATPostingSetup."Sales VAT Unreal. Account";
                            END;
                        VATEntry2."VAT Calculation Type"::"Sales Tax":
                            BEGIN
                                TaxJurisdiction.GET(VATEntry2."Tax Jurisdiction Code");
                                TaxJurisdiction.TESTFIELD("Tax Account (Sales)");
                                TaxJurisdiction.TESTFIELD("Unreal. Tax Acc. (Sales)");
                                SalesVATAccount := TaxJurisdiction."Tax Account (Sales)";
                                SalesVATUnrealAccount := TaxJurisdiction."Unreal. Tax Acc. (Sales)";
                            END;
                    END;

                    IF VATPart = 1 THEN BEGIN
                        VATAmount := VATEntry2."Remaining Unrealized Amount";
                        VATBase := VATEntry2."Remaining Unrealized Base";
                        VATAmountAddCurr := VATEntry2."Add.-Curr. Rem. Unreal. Amount";
                        VATBaseAddCurr := VATEntry2."Add.-Curr. Rem. Unreal. Base";
                    END ELSE BEGIN
                        VATAmount := ROUND(VATEntry2."Remaining Unrealized Amount" * VATPart);
                        VATBase := ROUND(VATEntry2."Remaining Unrealized Base" * VATPart);
                        VATAmountAddCurr :=
                          ROUND(
                            VATEntry2."Add.-Curr. Rem. Unreal. Amount" * VATPart,
                            AddCurrency."Amount Rounding Precision");
                        VATBaseAddCurr :=
                          ROUND(
                            VATEntry2."Add.-Curr. Rem. Unreal. Base" * VATPart,
                            AddCurrency."Amount Rounding Precision");
                    END;

                    InitGLEntry(SalesVATUnrealAccount, -VATAmount, 0, FALSE, TRUE);
                    GLEntry."Additional-Currency Amount" := -VATAmountAddCurr;
                    GLEntry."Bal. Account No." := SalesVATAccount;
                    SummarizeVAT(
                      GLSetup."Summarize G/L Entries", GLEntry, TempGLEntryVAT, InsertedTempGLEntryVAT);

                    InitGLEntry(SalesVATAccount, VATAmount, 0, FALSE, TRUE);
                    GLEntry."Additional-Currency Amount" := VATAmountAddCurr;
                    GLEntry."Bal. Account No." := SalesVATUnrealAccount;
                    GLEntry."Gen. Posting Type" := VATEntry2.Type;
                    GLEntry."Gen. Bus. Posting Group" := VATEntry2."Gen. Bus. Posting Group";
                    GLEntry."Gen. Prod. Posting Group" := VATEntry2."Gen. Prod. Posting Group";
                    GLEntry."VAT Bus. Posting Group" := VATEntry2."VAT Bus. Posting Group";
                    GLEntry."VAT Prod. Posting Group" := VATEntry2."VAT Prod. Posting Group";
                    GLEntry."Tax Area Code" := VATEntry2."Tax Area Code";
                    GLEntry."Tax Liable" := VATEntry2."Tax Liable";
                    GLEntry."Tax Group Code" := VATEntry2."Tax Group Code";
                    GLEntry."Use Tax" := VATEntry2."Use Tax";
                    SummarizeVAT(
                      GLSetup."Summarize G/L Entries", GLEntry, TempGLEntryVAT, InsertedTempGLEntryVAT);

                    VATEntry.LOCKTABLE;
                    VATEntry := VATEntry2;
                    VATEntry."Entry No." := NextVATEntryNo;
                    VATEntry."Posting Date" := GenJnlLine."Posting Date";
                    VATEntry."Document No." := GenJnlLine."Document No.";
                    VATEntry."External Document No." := GenJnlLine."External Document No.";
                    VATEntry."Document Type" := GenJnlLine."Document Type";
                    VATEntry.Amount := VATAmount;
                    VATEntry.Base := VATBase;
                    VATEntry."Unrealized Amount" := 0;
                    VATEntry."Unrealized Base" := 0;
                    VATEntry."Remaining Unrealized Amount" := 0;
                    VATEntry."Remaining Unrealized Base" := 0;
                    VATEntry."Additional-Currency Amount" := VATAmountAddCurr;
                    VATEntry."Additional-Currency Base" := VATBaseAddCurr;
                    VATEntry."Add.-Currency Unrealized Amt." := 0;
                    VATEntry."Add.-Currency Unrealized Base" := 0;
                    VATEntry."Add.-Curr. Rem. Unreal. Amount" := 0;
                    VATEntry."Add.-Curr. Rem. Unreal. Base" := 0;
                    VATEntry."User ID" := USERID;
                    VATEntry."Source Code" := GenJnlLine."Source Code";
                    VATEntry."Reason Code" := GenJnlLine."Reason Code";
                    VATEntry."Closed by Entry No." := 0;
                    VATEntry.Closed := FALSE;
                    VATEntry."Transaction No." := GLEntry."Transaction No.";
                    VATEntry."Sales Tax Connection No." := NextConnectionNo;
                    VATEntry."Unrealized VAT Entry No." := VATEntry2."Entry No.";
                    VATEntry.INSERT;
                    NextVATEntryNo := NextVATEntryNo + 1;

                    VATEntry2."Remaining Unrealized Amount" :=
                      VATEntry2."Remaining Unrealized Amount" - VATEntry.Amount;
                    VATEntry2."Remaining Unrealized Base" :=
                      VATEntry2."Remaining Unrealized Base" - VATEntry.Base;
                    VATEntry2."Add.-Curr. Rem. Unreal. Amount" :=
                      VATEntry2."Add.-Curr. Rem. Unreal. Amount" - VATEntry."Additional-Currency Amount";
                    VATEntry2."Add.-Curr. Rem. Unreal. Base" :=
                      VATEntry2."Add.-Curr. Rem. Unreal. Base" - VATEntry."Additional-Currency Base";
                    VATEntry2.MODIFY;
                END;
            UNTIL VATEntry2.NEXT = 0;

            InsertSummarizedVAT;
        END;
    end;

    procedure CustPostApplyCustLedgEntry(var GenJnlLinePostApply: Record "Gen. Journal Line"; var CustLedgEntryPostApply: Record "21")
    var
        LedgEntryDim: Record "355";
        CustLedgEntry: Record "21";
        DtldCustLedgEntry: Record "379";
        DtldCVLedgEntryBuf: Record "383" temporary;
        CVLedgEntryBuf: Record "382";
    begin
        GenJnlLine := GenJnlLinePostApply;
        GenJnlLine."Source Currency Code" := CustLedgEntryPostApply."Currency Code";
        GenJnlLine."Applies-to ID" := CustLedgEntryPostApply."Applies-to ID";
        CustLedgEntry.TRANSFERFIELDS(CustLedgEntryPostApply);
        WITH GenJnlLine DO BEGIN
            LedgEntryDim.SETRANGE("Table ID", DATABASE::"Cust. Ledger Entry");
            LedgEntryDim.SETRANGE("Entry No.", CustLedgEntry."Entry No.");
            TempJnlLineDim.RESET;
            TempJnlLineDim.DELETEALL;
            DimMgt.CopyLedgEntryDimToJnlLineDim(LedgEntryDim, TempJnlLineDim);

            GenJnlCheckLine.RunCheck(GenJnlLine, TempJnlLineDim);

            InitCodeUnit;

            IF Cust."No." <> CustLedgEntry."Customer No." THEN
                Cust.GET(CustLedgEntry."Customer No.");
            Cust.CheckBlockedCustOnJnls(Cust, "Document Type", TRUE);

            IF "Posting Group" = '' THEN BEGIN
                Cust.TESTFIELD("Customer Posting Group");
                "Posting Group" := Cust."Customer Posting Group";
            END;
            CustPostingGr.GET("Posting Group");
            CustPostingGr.TESTFIELD("Receivables Account");

            DtldCustLedgEntry.LOCKTABLE;
            CustLedgEntry.LOCKTABLE;

            // Post the application
            CustLedgEntry.CALCFIELDS(
              Amount, "Amount (LCY)", "Remaining Amount", "Remaining Amt. (LCY)",
              "Original Amount", "Original Amt. (LCY)");
            TransferCustLedgEntry(CVLedgEntryBuf, CustLedgEntry, TRUE);
            ApplyCustLedgEntry(
              CVLedgEntryBuf, DtldCVLedgEntryBuf, GenJnlLine, GLSetup."Appln. Rounding Precision");
            TransferCustLedgEntry(CVLedgEntryBuf, CustLedgEntry, FALSE);
            CustLedgEntry.MODIFY;

            // Post the Dtld customer entry
            PostDtldCustLedgEntries(
              GenJnlLine, DtldCVLedgEntryBuf, CustPostingGr, GLSetup, NextTransactionNo, FALSE);
            FinishCodeunit;
        END;
    end;

    procedure UnapplyCustLedgEntry(GenJnlLine2: Record "Gen. Journal Line"; DtldCustLedgEntry: Record "379")
    var
        DtldCustLedgEntry2: Record "379";
        NewDtldCustLedgEntry: Record "379";
        CustLedgEntry: Record "21";
        DtldCVLedgEntryBuf: Record "383";
        VATEntry: Record "254";
        VATPostingSetup: Record "VAT Posting Setup";
        LedgEntryDim: Record "355";
        GenPostingSetup: Record "252";
        VATEntryTemp: Record "254" temporary;
        CurrencyLCY: Record "4";
        VATEntrySaved: Record "254";
        VATEntry2: Record "254";
        TotalAmountLCY: Decimal;
        TotalAmountAddCurr: Decimal;
        NextDtldLedgEntryEntryNo: Integer;
        UnapplyVATEntries: Boolean;
        DebitAddjustment: Decimal;
        DebitAddjustmentAddCurr: Decimal;
        CreditAddjustment: Decimal;
        CreditAddjustmentAddCurr: Decimal;
        PositiveLCYAppAmt: Decimal;
        NegativeLCYAppAmt: Decimal;
        PositiveACYAppAmt: Decimal;
        NegativeACYAppAmt: Decimal;
        VatBaseSum: array[2] of Decimal;
        EntryNoBegin: array[2] of Integer;
        i: Integer;
        TempVatEntryNo: Integer;
    begin
        PositiveLCYAppAmt := 0;
        PositiveACYAppAmt := 0;
        NegativeLCYAppAmt := 0;
        NegativeACYAppAmt := 0;
        GenJnlLine.TRANSFERFIELDS(GenJnlLine2);
        IF GenJnlLine."Document Date" = 0D THEN
            GenJnlLine."Document Date" := GenJnlLine."Posting Date";

        InitCodeUnit;

        IF Cust."No." <> DtldCustLedgEntry."Customer No." THEN
            Cust.GET(DtldCustLedgEntry."Customer No.");
        Cust.CheckBlockedCustOnJnls(Cust, 0, TRUE);

        CustPostingGr.GET(GenJnlLine."Posting Group");
        CustPostingGr.TESTFIELD("Receivables Account");

        VATEntry.LOCKTABLE;
        DtldCustLedgEntry.LOCKTABLE;
        CustLedgEntry.LOCKTABLE;

        DtldCustLedgEntry.TESTFIELD("Entry Type", DtldCustLedgEntry."Entry Type"::Application);

        DtldCustLedgEntry2.RESET;
        DtldCustLedgEntry2.FINDLAST;
        NextDtldLedgEntryEntryNo := DtldCustLedgEntry2."Entry No." + 1;
        DtldCustLedgEntry2.SETCURRENTKEY("Transaction No.", "Customer No.", "Entry Type");
        DtldCustLedgEntry2.SETRANGE("Transaction No.", DtldCustLedgEntry."Transaction No.");
        DtldCustLedgEntry2.SETRANGE("Customer No.", DtldCustLedgEntry."Customer No.");
        DtldCustLedgEntry2.SETFILTER("Entry Type", '>%1', DtldCustLedgEntry."Entry Type"::"Initial Entry");
        UnapplyVATEntries := FALSE;
        DtldCustLedgEntry2.FINDSET;
        REPEAT
            DtldCustLedgEntry2.TESTFIELD(Unapplied, FALSE);
            IF (DtldCustLedgEntry2."Entry Type" = DtldCustLedgEntry2."Entry Type"::"Payment Discount (VAT Adjustment)") OR
               (DtldCustLedgEntry2."Entry Type" = DtldCustLedgEntry2."Entry Type"::"Payment Tolerance (VAT Adjustment)") OR
               (DtldCustLedgEntry2."Entry Type" = DtldCustLedgEntry2."Entry Type"::"Payment Discount Tolerance (VAT Adjustment)")
            THEN
                UnapplyVATEntries := TRUE
        UNTIL DtldCustLedgEntry2.NEXT = 0;

        TempVatEntryNo := 1;
        VATEntry.SETCURRENTKEY(Type, "Bill-to/Pay-to No.", "Transaction No.");
        VATEntry.SETRANGE(Type, VATEntry.Type::Sale);
        VATEntry.SETRANGE("Bill-to/Pay-to No.", DtldCustLedgEntry."Customer No.");
        VATEntry.SETRANGE("Transaction No.", DtldCustLedgEntry."Transaction No.");
        IF VATEntry.FINDSET THEN BEGIN
            VATPostingSetup.GET(VATEntry."VAT Bus. Posting Group", VATEntry."VAT Prod. Posting Group");
            IF (VATPostingSetup."Adjust for Payment Discount") AND
               (VATPostingSetup."VAT Calculation Type" = VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT") AND
               (VATEntry."Document Type" <> VATEntry."Document Type"::"Credit Memo") AND
               (VATEntry."Document Type" <> VATEntry."Document Type"::Invoice) AND
               (VATEntry."Document Type" <> VATEntry."Document Type"::"Finance Charge Memo") AND
               (VATEntry."Document Type" <> VATEntry."Document Type"::Reminder)
            THEN
                UnapplyVATEntries := TRUE;
            REPEAT
                IF UnapplyVATEntries OR (VATEntry."Unrealized VAT Entry No." <> 0) THEN BEGIN
                    TempVatEntry := VATEntry;
                    TempVatEntry."Entry No." := TempVatEntryNo;
                    TempVatEntryNo := TempVatEntryNo + 1;
                    TempVatEntry."Closed by Entry No." := 0;
                    TempVatEntry.Closed := FALSE;
                    TempVatEntry.Base := -VATEntry.Base;
                    TempVatEntry.Amount := -VATEntry.Amount;
                    TempVatEntry."Unrealized Amount" := -VATEntry."Unrealized Amount";
                    TempVatEntry."Unrealized Base" := -VATEntry."Unrealized Base";
                    TempVatEntry."Remaining Unrealized Amount" := -VATEntry."Remaining Unrealized Amount";
                    TempVatEntry."Remaining Unrealized Base" := -VATEntry."Remaining Unrealized Base";
                    TempVatEntry."Additional-Currency Amount" := -VATEntry."Additional-Currency Amount";
                    TempVatEntry."Additional-Currency Base" := -VATEntry."Additional-Currency Base";
                    TempVatEntry."Add.-Currency Unrealized Amt." := -VATEntry."Add.-Currency Unrealized Amt.";
                    TempVatEntry."Add.-Currency Unrealized Base" := -VATEntry."Add.-Currency Unrealized Base";
                    TempVatEntry."Add.-Curr. Rem. Unreal. Amount" := -VATEntry."Add.-Curr. Rem. Unreal. Amount";
                    TempVatEntry."Add.-Curr. Rem. Unreal. Base" := -VATEntry."Add.-Curr. Rem. Unreal. Base";
                    TempVatEntry."Posting Date" := GenJnlLine2."Posting Date";
                    TempVatEntry."Document No." := GenJnlLine2."Document No.";
                    TempVatEntry."User ID" := USERID;
                    TempVatEntry."Transaction No." := NextTransactionNo;
                    TempVatEntry.INSERT;
                    IF VATEntry."Unrealized VAT Entry No." <> 0 THEN BEGIN
                        VATPostingSetup.GET(VATEntry."VAT Bus. Posting Group", VATEntry."VAT Prod. Posting Group");
                        IF VATPostingSetup."VAT Calculation Type" IN
                           [VATPostingSetup."VAT Calculation Type"::"Normal VAT",
                            VATPostingSetup."VAT Calculation Type"::"Full VAT",
                            VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT"]
                        THEN BEGIN
                            VATPostingSetup.TESTFIELD("Sales VAT Unreal. Account");
                            VATPostingSetup.TESTFIELD("Sales VAT Account");
                            PostUnrealVATByUnapply(
                              VATPostingSetup."Sales VAT Unreal. Account",
                              VATPostingSetup."Sales VAT Account",
                              VATEntry, TempVatEntry);
                        END ELSE BEGIN
                            VATEntry.TESTFIELD("Tax Jurisdiction Code");
                            TaxJurisdiction.GET(VATEntry."Tax Jurisdiction Code");
                            TaxJurisdiction.TESTFIELD("Unreal. Tax Acc. (Sales)");
                            TaxJurisdiction.TESTFIELD("Tax Account (Sales)");
                            PostUnrealVATByUnapply(
                              TaxJurisdiction."Unreal. Tax Acc. (Sales)",
                              TaxJurisdiction."Tax Account (Sales)",
                              VATEntry, TempVatEntry);
                        END;
                        VATEntry2 := TempVatEntry;
                        VATEntry2."Entry No." := NextVATEntryNo;
                        NextVATEntryNo := NextVATEntryNo + 1;
                        VATEntry2.INSERT;
                        TempVatEntry.DELETE;
                    END;
                    IF (VATPostingSetup."Adjust for Payment Discount") AND
                       (VATPostingSetup."VAT Calculation Type" =
                         VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT") AND
                       (VATEntry."Unrealized VAT Entry No." = 0) AND
                       (VATEntry."Document Type" <> VATEntry."Document Type"::"Credit Memo") AND
                       (VATEntry."Document Type" <> VATEntry."Document Type"::Invoice) AND
                       (VATEntry."Document Type" <> VATEntry."Document Type"::"Finance Charge Memo") AND
                       (VATEntry."Document Type" <> VATEntry."Document Type"::Reminder)
                    THEN BEGIN
                        VATPostingSetup.TESTFIELD("Sales VAT Account");
                        GenPostingSetup.GET(VATEntry."Gen. Bus. Posting Group", VATEntry."Gen. Prod. Posting Group");
                        PostPmtDiscountVATByUnapply(
                          VATPostingSetup."Reverse Chrg. VAT Acc.",
                          VATPostingSetup."Sales VAT Account",
                          VATEntry);
                    END;
                END;
            UNTIL VATEntry.NEXT = 0;
        END;

        DtldCustLedgEntry2.FINDSET;
        REPEAT
            IF (DtldCustLedgEntry2."Entry Type" IN
                [DtldCustLedgEntry2."Entry Type"::"Payment Discount (VAT Excl.)",
                 DtldCustLedgEntry2."Entry Type"::"Payment Tolerance (VAT Excl.)",
                 DtldCustLedgEntry2."Entry Type"::"Payment Discount Tolerance (VAT Excl.)"])
            THEN BEGIN
                TempVatEntry.RESET;
                TempVatEntry.SETRANGE("Entry No.", 0, 999999);
                TempVatEntry.SETRANGE("Gen. Bus. Posting Group", DtldCustLedgEntry2."Gen. Bus. Posting Group");
                TempVatEntry.SETRANGE("Gen. Prod. Posting Group", DtldCustLedgEntry2."Gen. Prod. Posting Group");
                TempVatEntry.SETRANGE("VAT Bus. Posting Group", DtldCustLedgEntry2."VAT Bus. Posting Group");
                TempVatEntry.SETRANGE("VAT Prod. Posting Group", DtldCustLedgEntry2."VAT Prod. Posting Group");
                IF TempVatEntry.FINDSET THEN BEGIN
                    REPEAT
                        CASE TRUE OF
                            VatBaseSum[2] + TempVatEntry.Base = DtldCustLedgEntry2."Amount (LCY)":
                                i := 3;
                            VatBaseSum[1] + TempVatEntry.Base = DtldCustLedgEntry2."Amount (LCY)":
                                i := 2;
                            TempVatEntry.Base = DtldCustLedgEntry2."Amount (LCY)":
                                i := 1;
                            ELSE
                                i := 0;
                        END;
                        IF i > 0 THEN BEGIN
                            IF i > 1 THEN
                                TempVatEntry.SETRANGE("Entry No.", EntryNoBegin[i - 1], TempVatEntry."Entry No.")
                            ELSE
                                TempVatEntry.SETRANGE("Entry No.", TempVatEntry."Entry No.");
                            TempVatEntry.FINDSET;
                            REPEAT
                                VATEntrySaved := TempVatEntry;
                                CASE DtldCustLedgEntry2."Entry Type" OF
                                    DtldCustLedgEntry2."Entry Type"::"Payment Tolerance (VAT Excl.)":
                                        TempVatEntry.RENAME(TempVatEntry."Entry No." + 2000000);
                                    DtldCustLedgEntry2."Entry Type"::"Payment Discount Tolerance (VAT Excl.)":
                                        TempVatEntry.RENAME(TempVatEntry."Entry No." + 1000000);
                                END;
                                TempVatEntry := VATEntrySaved;
                            UNTIL TempVatEntry.NEXT = 0;
                            FOR i := 1 TO 2 DO BEGIN
                                VatBaseSum[i] := 0;
                                EntryNoBegin[i] := 0;
                            END;
                            TempVatEntry.SETRANGE("Entry No.", 0, 999999);
                        END ELSE BEGIN
                            VatBaseSum[2] := VatBaseSum[1] + TempVatEntry.Base;
                            VatBaseSum[1] := TempVatEntry.Base;
                            EntryNoBegin[2] := EntryNoBegin[1];
                            EntryNoBegin[1] := TempVatEntry."Entry No.";
                        END;
                    UNTIL TempVatEntry.NEXT = 0;
                END;
            END;
        UNTIL DtldCustLedgEntry2.NEXT = 0;

        DtldCustLedgEntry2.FINDSET;
        LedgEntryDim.SETRANGE("Table ID", DATABASE::"Cust. Ledger Entry");
        LedgEntryDim.SETRANGE("Entry No.", DtldCustLedgEntry2."Applied Cust. Ledger Entry No.");
        TempJnlLineDim.RESET;
        TempJnlLineDim.DELETEALL;
        DimMgt.CopyLedgEntryDimToJnlLineDim(LedgEntryDim, TempJnlLineDim);
        IF TempJnlLineDim.GET(DATABASE::"Cust. Ledger Entry", '', '', 0, 0, GLSetup."Global Dimension 1 Code") THEN
            GenJnlLine."Shortcut Dimension 1 Code" := TempJnlLineDim."Dimension Value Code"
        ELSE
            GenJnlLine."Shortcut Dimension 1 Code" := '';
        IF TempJnlLineDim.GET(DATABASE::"Cust. Ledger Entry", '', '', 0, 0, GLSetup."Global Dimension 2 Code") THEN
            GenJnlLine."Shortcut Dimension 2 Code" := TempJnlLineDim."Dimension Value Code"
        ELSE
            GenJnlLine."Shortcut Dimension 2 Code" := '';

        REPEAT
            NewDtldCustLedgEntry := DtldCustLedgEntry2;
            NewDtldCustLedgEntry."Entry No." := NextDtldLedgEntryEntryNo;
            NewDtldCustLedgEntry."Posting Date" := GenJnlLine."Posting Date";
            NewDtldCustLedgEntry."Transaction No." := NextTransactionNo;
            NewDtldCustLedgEntry.Amount := -DtldCustLedgEntry2.Amount;
            NewDtldCustLedgEntry."Amount (LCY)" := -DtldCustLedgEntry2."Amount (LCY)";
            NewDtldCustLedgEntry."Debit Amount" := -DtldCustLedgEntry2."Debit Amount";
            NewDtldCustLedgEntry."Credit Amount" := -DtldCustLedgEntry2."Credit Amount";
            NewDtldCustLedgEntry."Debit Amount (LCY)" := -DtldCustLedgEntry2."Debit Amount (LCY)";
            NewDtldCustLedgEntry."Credit Amount (LCY)" := -DtldCustLedgEntry2."Credit Amount (LCY)";
            NewDtldCustLedgEntry.Unapplied := TRUE;
            NewDtldCustLedgEntry."Unapplied by Entry No." := DtldCustLedgEntry2."Entry No.";
            NewDtldCustLedgEntry."Document No." := GenJnlLine."Document No.";
            NewDtldCustLedgEntry."Source Code" := GenJnlLine."Source Code";
            NewDtldCustLedgEntry."User ID" := USERID;
            NewDtldCustLedgEntry.INSERT;
            NextDtldLedgEntryEntryNo := NextDtldLedgEntryEntryNo + 1;

            DtldCVLedgEntryBuf.TRANSFERFIELDS(NewDtldCustLedgEntry);
            GenJnlLine."Source Currency Code" := DtldCustLedgEntry2."Currency Code";
            IF GLSetup."Additional Reporting Currency" <> DtldCVLedgEntryBuf."Currency Code" THEN
                DtldCVLedgEntryBuf."Additional-Currency Amount" :=
                  CalcAddCurrForUnapplication(DtldCVLedgEntryBuf."Posting Date", DtldCVLedgEntryBuf."Amount (LCY)")
            ELSE
                IF GLSetup."Additional Reporting Currency" <> '' THEN
                    DtldCVLedgEntryBuf."Additional-Currency Amount" := DtldCVLedgEntryBuf.Amount;
            CurrencyLCY.InitRoundingPrecision;

            IF DtldCustLedgEntry2."Entry Type" IN [
              DtldCustLedgEntry2."Entry Type"::"Payment Discount (VAT Excl.)",
              DtldCustLedgEntry2."Entry Type"::"Payment Tolerance (VAT Excl.)",
              DtldCustLedgEntry2."Entry Type"::"Payment Discount Tolerance (VAT Excl.)"]
            THEN BEGIN
                VATEntryTemp.SETRANGE("VAT Bus. Posting Group", DtldCustLedgEntry2."VAT Bus. Posting Group");
                VATEntryTemp.SETRANGE("VAT Prod. Posting Group", DtldCustLedgEntry2."VAT Prod. Posting Group");
                IF NOT VATEntryTemp.FINDFIRST THEN BEGIN
                    VATEntryTemp.RESET;
                    IF VATEntryTemp.FINDLAST THEN
                        VATEntryTemp."Entry No." := VATEntryTemp."Entry No." + 1
                    ELSE
                        VATEntryTemp."Entry No." := 1;
                    VATEntryTemp.INIT;
                    VATEntryTemp."VAT Bus. Posting Group" := DtldCustLedgEntry2."VAT Bus. Posting Group";
                    VATEntryTemp."VAT Prod. Posting Group" := DtldCustLedgEntry2."VAT Prod. Posting Group";

                    VATEntry.SETCURRENTKEY(VATEntry."Transaction No.");
                    VATEntry.SETRANGE("Transaction No.", DtldCustLedgEntry2."Transaction No.");
                    VATEntry.SETRANGE("VAT Bus. Posting Group", DtldCustLedgEntry2."VAT Bus. Posting Group");
                    VATEntry.SETRANGE("VAT Prod. Posting Group", DtldCustLedgEntry2."VAT Prod. Posting Group");
                    IF VATEntry.FINDSET THEN
                        REPEAT
                            IF VATEntry."Unrealized VAT Entry No." = 0 THEN BEGIN
                                VATEntryTemp.Base := VATEntryTemp.Base + VATEntry.Base;
                                VATEntryTemp.Amount := VATEntryTemp.Amount + VATEntry.Amount;
                            END;
                        UNTIL VATEntry.NEXT = 0;
                    CLEAR(VATEntry);
                    VATEntryTemp.INSERT;
                END;
                IF DtldCVLedgEntryBuf."Amount (LCY)" = VATEntryTemp.Base THEN BEGIN
                    DtldCVLedgEntryBuf."VAT Amount (LCY)" := VATEntryTemp.Amount;
                    VATEntryTemp.DELETE;
                END ELSE BEGIN
                    DtldCVLedgEntryBuf."VAT Amount (LCY)" := ROUND(
                      VATEntryTemp.Amount * DtldCVLedgEntryBuf."Amount (LCY)" / VATEntryTemp.Base,
                      CurrencyLCY."Amount Rounding Precision",
                      CurrencyLCY.VATRoundingDirection);
                    VATEntryTemp.Base := VATEntryTemp.Base - DtldCVLedgEntryBuf."Amount (LCY)";
                    VATEntryTemp.Amount := VATEntryTemp.Amount - DtldCVLedgEntryBuf."VAT Amount (LCY)";
                    VATEntryTemp.MODIFY;
                END;
            END;
            TotalAmountLCY := TotalAmountLCY + DtldCVLedgEntryBuf."Amount (LCY)";
            TotalAmountAddCurr := TotalAmountAddCurr + DtldCVLedgEntryBuf."Additional-Currency Amount";
            IF DtldCVLedgEntryBuf."Entry Type" = DtldCVLedgEntryBuf."Entry Type"::Application THEN BEGIN
                IF DtldCVLedgEntryBuf."Amount (LCY)" >= 0 THEN BEGIN
                    PositiveLCYAppAmt := PositiveLCYAppAmt + DtldCVLedgEntryBuf."Amount (LCY)";
                    PositiveACYAppAmt :=
                      PositiveACYAppAmt + DtldCVLedgEntryBuf."Additional-Currency Amount";
                END ELSE BEGIN
                    NegativeLCYAppAmt := NegativeLCYAppAmt + DtldCVLedgEntryBuf."Amount (LCY)";
                    NegativeACYAppAmt :=
                      NegativeACYAppAmt + DtldCVLedgEntryBuf."Additional-Currency Amount";
                END;
            END;
            IF NOT (DtldCVLedgEntryBuf."Entry Type" IN [
              DtldCVLedgEntryBuf."Entry Type"::"Initial Entry",
              DtldCVLedgEntryBuf."Entry Type"::Application]) THEN
                CollectAddjustment(DebitAddjustment, DebitAddjustmentAddCurr,
                  CreditAddjustment, CreditAddjustmentAddCurr,
                  -DtldCVLedgEntryBuf."Amount (LCY)", -DtldCVLedgEntryBuf."Additional-Currency Amount");
            AutoEntrForDtldCustLedgEntries(DtldCVLedgEntryBuf, DtldCustLedgEntry2."Transaction No.");

            DtldCustLedgEntry2.Unapplied := TRUE;
            DtldCustLedgEntry2."Unapplied by Entry No." := NewDtldCustLedgEntry."Entry No.";
            DtldCustLedgEntry2.MODIFY;

            IF DtldCustLedgEntry2."Entry Type" = DtldCustLedgEntry2."Entry Type"::Application THEN BEGIN
                CustLedgEntry.GET(DtldCustLedgEntry2."Cust. Ledger Entry No.");
                CustLedgEntry."Remaining Pmt. Disc. Possible" := DtldCustLedgEntry2."Remaining Pmt. Disc. Possible";
                CustLedgEntry."Max. Payment Tolerance" := DtldCustLedgEntry2."Max. Payment Tolerance";
                CustLedgEntry."Accepted Payment Tolerance" := 0;
                IF NOT CustLedgEntry.Open THEN BEGIN
                    CustLedgEntry.Open := TRUE;
                    CustLedgEntry."Closed by Entry No." := 0;
                    CustLedgEntry."Closed at Date" := 0D;
                    CustLedgEntry."Closed by Amount" := 0;
                    CustLedgEntry."Closed by Amount (LCY)" := 0;
                    CustLedgEntry."Closed by Currency Code" := '';
                    CustLedgEntry."Closed by Currency Amount" := 0;
                    CustLedgEntry."Pmt. Disc. Given (LCY)" := 0;
                    CustLedgEntry."Pmt. Tolerance (LCY)" := 0;
                    CustLedgEntry."Calculate Interest" := FALSE;
                END;
                CustLedgEntry.MODIFY;
            END;
        UNTIL DtldCustLedgEntry2.NEXT = 0;

        IF (TotalAmountLCY <> 0) OR
           (TotalAmountAddCurr <> 0) AND (GLSetup."Additional Reporting Currency" <> '')
        THEN BEGIN
            InitGLEntry(CustPostingGr."Receivables Account", TotalAmountLCY, TotalAmountAddCurr, TRUE, TRUE);
            InsertGLEntry(TRUE);
        END;

        IF NOT GLEntryTmp.FINDFIRST THEN BEGIN
            InitGLEntry(CustPostingGr."Receivables Account", PositiveLCYAppAmt, PositiveACYAppAmt, FALSE, TRUE);
            InsertGLEntry(FALSE);
            InitGLEntry(CustPostingGr."Receivables Account", NegativeLCYAppAmt, NegativeACYAppAmt, FALSE, TRUE);
            InsertGLEntry(FALSE);
        END;

        FinishCodeunit;
    end;

    procedure TransferCustLedgEntry(var CVLedgEntryBuf: Record "382"; var CustLedgEntry: Record "21"; CustToCV: Boolean)
    begin
        IF CustToCV THEN BEGIN
            CVLedgEntryBuf.TRANSFERFIELDS(CustLedgEntry);
            CVLedgEntryBuf.Amount := CustLedgEntry.Amount;
            CVLedgEntryBuf."Amount (LCY)" := CustLedgEntry."Amount (LCY)";
            CVLedgEntryBuf."Remaining Amount" := CustLedgEntry."Remaining Amount";
            CVLedgEntryBuf."Remaining Amt. (LCY)" := CustLedgEntry."Remaining Amt. (LCY)";
            CVLedgEntryBuf."Original Amount" := CustLedgEntry."Original Amount";
            CVLedgEntryBuf."Original Amt. (LCY)" := CustLedgEntry."Original Amt. (LCY)";
        END ELSE BEGIN
            CustLedgEntry.TRANSFERFIELDS(CVLedgEntryBuf);
            CustLedgEntry.Amount := CVLedgEntryBuf.Amount;
            CustLedgEntry."Amount (LCY)" := CVLedgEntryBuf."Amount (LCY)";
            CustLedgEntry."Remaining Amount" := CVLedgEntryBuf."Remaining Amount";
            CustLedgEntry."Remaining Amt. (LCY)" := CVLedgEntryBuf."Remaining Amt. (LCY)";
            CustLedgEntry."Original Amount" := CVLedgEntryBuf."Original Amount";
            CustLedgEntry."Original Amt. (LCY)" := CVLedgEntryBuf."Original Amt. (LCY)";
        END;
    end;

    local procedure PostDtldCustLedgEntries(GenJnlLine2: Record "Gen. Journal Line"; var DtldCVLedgEntryBuf: Record "383"; CustPostingGr: Record "92"; GLSetup: Record "General Ledger Setup"; NextTransactionNo: Integer; CustLedgEntryInserted: Boolean)
    var
        DtldCustLedgEntry: Record "379";
        Currency: Record "4";
        GenPostingSetup: Record "252";
        TotalAmountLCY: Decimal;
        TotalAmountAddCurr: Decimal;
        PaymentDiscAcc: Code[20];
        DtldCustLedgEntryNoOffset: Integer;
        PaymentTolAcc: Code[20];
        SaveEntryNo: Integer;
        DebitAddjustment: Decimal;
        DebitAddjustmentAddCurr: Decimal;
        CreditAddjustment: Decimal;
        CreditAddjustmentAddCurr: Decimal;
        PositiveLCYAppAmt: Decimal;
        NegativeLCYAppAmt: Decimal;
        PositiveACYAppAmt: Decimal;
        NegativeACYAppAmt: Decimal;
        OriginalPostingDate: Date;
        OriginalDateSet: Boolean;
        TotalAmountLCYApplDate: Decimal;
        TotalAmountAddCurrApplDate: Decimal;
        ApplicationDate: Date;
        DebitAddjustmentApplDate: Decimal;
        DebitAddjustmentAddCurrApplDat: Decimal;
        CreditAddjustmentApplDate: Decimal;
        CreditAddjustmentAddCurrApplDa: Decimal;
        SavedEntryUsed: Boolean;
    begin
        TotalAmountLCY := 0;
        TotalAmountAddCurr := 0;
        PositiveLCYAppAmt := 0;
        PositiveACYAppAmt := 0;
        NegativeLCYAppAmt := 0;
        NegativeACYAppAmt := 0;

        IF GenJnlLine2."Account Type" = GenJnlLine2."Account Type"::Customer THEN BEGIN
            IF DtldCustLedgEntry.FINDLAST THEN
                DtldCustLedgEntryNoOffset := DtldCustLedgEntry."Entry No."
            ELSE
                //LS -
                DtldCustLedgEntryNoOffset := InitEntryNoInStore.GetCurrLocInitEntryNo(DATABASE::"Detailed Cust. Ledg. Entry") - 1;
            //DtldCustLedgEntryNoOffset := 0;
            //LS +
            DtldCVLedgEntryBuf.RESET;
            IF DtldCVLedgEntryBuf.FINDSET THEN BEGIN
                IF CustLedgEntryInserted THEN BEGIN
                    SaveEntryNo := NextEntryNo;
                    NextEntryNo := NextEntryNo + 1;
                END;
                REPEAT
                    IF DtldCVLedgEntryBuf."Posting Date" <> GenJnlLine."Posting Date" THEN BEGIN
                        OriginalPostingDate := GenJnlLine."Posting Date";
                        GenJnlLine."Posting Date" := DtldCVLedgEntryBuf."Posting Date";
                        OriginalDateSet := TRUE;
                        ApplicationDate := DtldCVLedgEntryBuf."Posting Date";
                    END;
                    CLEAR(DtldCustLedgEntry);
                    DtldCustLedgEntry.TRANSFERFIELDS(DtldCVLedgEntryBuf);
                    DtldCustLedgEntry."Entry No." :=
                      DtldCustLedgEntryNoOffset + DtldCVLedgEntryBuf."Entry No.";
                    DtldCustLedgEntry."Journal Batch Name" := GenJnlLine2."Journal Batch Name";
                    DtldCustLedgEntry."Reason Code" := GenJnlLine2."Reason Code";
                    DtldCustLedgEntry."Source Code" := GenJnlLine2."Source Code";
                    DtldCustLedgEntry."Transaction No." := NextTransactionNo;
                    CustUpdateDebitCredit(GenJnlLine2.Correction, DtldCustLedgEntry);
                    DtldCustLedgEntry.INSERT;

                    IF OriginalDateSet THEN BEGIN
                        TotalAmountLCYApplDate := TotalAmountLCYApplDate + DtldCVLedgEntryBuf."Amount (LCY)";
                        TotalAmountAddCurrApplDate := TotalAmountAddCurrApplDate + DtldCVLedgEntryBuf."Additional-Currency Amount";
                    END ELSE BEGIN
                        TotalAmountLCY := TotalAmountLCY + DtldCVLedgEntryBuf."Amount (LCY)";
                        TotalAmountAddCurr := TotalAmountAddCurr + DtldCVLedgEntryBuf."Additional-Currency Amount";
                    END;

                    // Post automatic entries.
                    IF (DtldCVLedgEntryBuf."Amount (LCY)" <> 0) OR
                       ((GLSetup."Additional Reporting Currency" <> '') AND
                        (DtldCVLedgEntryBuf."Additional-Currency Amount" <> 0))
                    THEN
                        CASE DtldCVLedgEntryBuf."Entry Type" OF
                            DtldCVLedgEntryBuf."Entry Type"::"Initial Entry":
                                ;
                            DtldCVLedgEntryBuf."Entry Type"::Application:
                                BEGIN
                                    IF DtldCVLedgEntryBuf."Amount (LCY)" >= 0 THEN BEGIN
                                        PositiveLCYAppAmt := PositiveLCYAppAmt + DtldCVLedgEntryBuf."Amount (LCY)";
                                        PositiveACYAppAmt :=
                                          PositiveACYAppAmt + DtldCVLedgEntryBuf."Additional-Currency Amount";
                                    END ELSE BEGIN
                                        NegativeLCYAppAmt := NegativeLCYAppAmt + DtldCVLedgEntryBuf."Amount (LCY)";
                                        NegativeACYAppAmt :=
                                          NegativeACYAppAmt + DtldCVLedgEntryBuf."Additional-Currency Amount";
                                    END;
                                END;
                            DtldCVLedgEntryBuf."Entry Type"::"Unrealized Loss":
                                BEGIN
                                    IF Currency.Code <> DtldCVLedgEntryBuf."Currency Code" THEN BEGIN
                                        IF DtldCVLedgEntryBuf."Currency Code" = '' THEN
                                            CLEAR(Currency)
                                        ELSE
                                            Currency.GET(DtldCVLedgEntryBuf."Currency Code");
                                    END;
                                    CheckNonAddCurrCodeOccurred(Currency.Code);
                                    Currency.TESTFIELD("Unrealized Losses Acc.");
                                    InitGLEntry(
                                      Currency."Unrealized Losses Acc.", -DtldCVLedgEntryBuf."Amount (LCY)",
                                      0, DtldCVLedgEntryBuf."Currency Code" = GLSetup."Additional Reporting Currency",
                                      TRUE);

                                    IF OriginalDateSet THEN
                                        CollectAddjustment(DebitAddjustmentApplDate, DebitAddjustmentAddCurrApplDat,
                                          CreditAddjustmentApplDate, CreditAddjustmentAddCurrApplDa,
                                          GLEntry.Amount, GLEntry."Additional-Currency Amount")
                                    ELSE
                                        CollectAddjustment(DebitAddjustment, DebitAddjustmentAddCurr,
                                          CreditAddjustment, CreditAddjustmentAddCurr,
                                          GLEntry.Amount, GLEntry."Additional-Currency Amount");
                                    InsertGLEntry(TRUE);
                                END;
                            DtldCVLedgEntryBuf."Entry Type"::"Unrealized Gain":
                                BEGIN
                                    IF Currency.Code <> DtldCVLedgEntryBuf."Currency Code" THEN BEGIN
                                        IF DtldCVLedgEntryBuf."Currency Code" = '' THEN
                                            CLEAR(Currency)
                                        ELSE
                                            Currency.GET(DtldCVLedgEntryBuf."Currency Code");
                                    END;
                                    CheckNonAddCurrCodeOccurred(Currency.Code);
                                    Currency.TESTFIELD("Unrealized Gains Acc.");
                                    InitGLEntry(
                                      Currency."Unrealized Gains Acc.", -DtldCVLedgEntryBuf."Amount (LCY)",
                                      0, DtldCVLedgEntryBuf."Currency Code" = GLSetup."Additional Reporting Currency",
                                      TRUE);

                                    IF OriginalDateSet THEN
                                        CollectAddjustment(DebitAddjustmentApplDate, DebitAddjustmentAddCurrApplDat,
                                          CreditAddjustmentApplDate, CreditAddjustmentAddCurrApplDa,
                                          GLEntry.Amount, GLEntry."Additional-Currency Amount")
                                    ELSE
                                        CollectAddjustment(DebitAddjustment, DebitAddjustmentAddCurr,
                                          CreditAddjustment, CreditAddjustmentAddCurr,
                                          GLEntry.Amount, GLEntry."Additional-Currency Amount");
                                    InsertGLEntry(TRUE);
                                END;
                            DtldCVLedgEntryBuf."Entry Type"::"Realized Loss":
                                BEGIN
                                    IF Currency.Code <> DtldCVLedgEntryBuf."Currency Code" THEN BEGIN
                                        IF DtldCVLedgEntryBuf."Currency Code" = '' THEN
                                            CLEAR(Currency)
                                        ELSE
                                            Currency.GET(DtldCVLedgEntryBuf."Currency Code");
                                    END;
                                    CheckNonAddCurrCodeOccurred(Currency.Code);
                                    Currency.TESTFIELD("Realized Losses Acc.");
                                    InitGLEntry(
                                      Currency."Realized Losses Acc.", -DtldCVLedgEntryBuf."Amount (LCY)",
                                      0, DtldCVLedgEntryBuf."Currency Code" = GLSetup."Additional Reporting Currency",
                                      TRUE);

                                    IF OriginalDateSet THEN
                                        CollectAddjustment(DebitAddjustmentApplDate, DebitAddjustmentAddCurrApplDat,
                                          CreditAddjustmentApplDate, CreditAddjustmentAddCurrApplDa,
                                          GLEntry.Amount, GLEntry."Additional-Currency Amount")
                                    ELSE
                                        CollectAddjustment(DebitAddjustment, DebitAddjustmentAddCurr,
                                          CreditAddjustment, CreditAddjustmentAddCurr,
                                          GLEntry.Amount, GLEntry."Additional-Currency Amount");
                                    InsertGLEntry(TRUE);
                                END;
                            DtldCVLedgEntryBuf."Entry Type"::"Realized Gain":
                                BEGIN
                                    IF Currency.Code <> DtldCVLedgEntryBuf."Currency Code" THEN BEGIN
                                        IF DtldCVLedgEntryBuf."Currency Code" = '' THEN
                                            CLEAR(Currency)
                                        ELSE
                                            Currency.GET(DtldCVLedgEntryBuf."Currency Code");
                                    END;
                                    CheckNonAddCurrCodeOccurred(Currency.Code);
                                    Currency.TESTFIELD("Realized Gains Acc.");
                                    InitGLEntry(
                                      Currency."Realized Gains Acc.", -DtldCVLedgEntryBuf."Amount (LCY)",
                                      0, DtldCVLedgEntryBuf."Currency Code" = GLSetup."Additional Reporting Currency",
                                      TRUE);

                                    IF OriginalDateSet THEN
                                        CollectAddjustment(DebitAddjustmentApplDate, DebitAddjustmentAddCurrApplDat,
                                          CreditAddjustmentApplDate, CreditAddjustmentAddCurrApplDa,
                                          GLEntry.Amount, GLEntry."Additional-Currency Amount")
                                    ELSE
                                        CollectAddjustment(DebitAddjustment, DebitAddjustmentAddCurr,
                                          CreditAddjustment, CreditAddjustmentAddCurr,
                                          GLEntry.Amount, GLEntry."Additional-Currency Amount");
                                    InsertGLEntry(TRUE);
                                END;
                            DtldCVLedgEntryBuf."Entry Type"::"Payment Discount":
                                BEGIN
                                    IF (DtldCVLedgEntryBuf."Amount (LCY)" <= 0) THEN BEGIN
                                        CustPostingGr.TESTFIELD("Payment Disc. Debit Acc.");
                                        PaymentDiscAcc := CustPostingGr."Payment Disc. Debit Acc.";
                                    END ELSE BEGIN
                                        CustPostingGr.TESTFIELD("Payment Disc. Credit Acc.");
                                        PaymentDiscAcc := CustPostingGr."Payment Disc. Credit Acc.";
                                    END;
                                    InitGLEntry(
                                      PaymentDiscAcc, -DtldCVLedgEntryBuf."Amount (LCY)",
                                      0, FALSE, TRUE);
                                    GLEntry."Additional-Currency Amount" :=
                                      -DtldCVLedgEntryBuf."Additional-Currency Amount";

                                    IF OriginalDateSet THEN
                                        CollectAddjustment(DebitAddjustmentApplDate, DebitAddjustmentAddCurrApplDat,
                                          CreditAddjustmentApplDate, CreditAddjustmentAddCurrApplDa,
                                          GLEntry.Amount, GLEntry."Additional-Currency Amount")
                                    ELSE
                                        CollectAddjustment(DebitAddjustment, DebitAddjustmentAddCurr,
                                          CreditAddjustment, CreditAddjustmentAddCurr,
                                          GLEntry.Amount, GLEntry."Additional-Currency Amount");
                                    InsertGLEntry(TRUE);
                                END;
                            DtldCVLedgEntryBuf."Entry Type"::"Payment Discount (VAT Excl.)":
                                BEGIN
                                    GenPostingSetup.GET(
                                      DtldCVLedgEntryBuf."Gen. Bus. Posting Group",
                                      DtldCVLedgEntryBuf."Gen. Prod. Posting Group");
                                    IF (DtldCVLedgEntryBuf."Amount (LCY)" <= 0) THEN BEGIN
                                        GenPostingSetup.TESTFIELD("Sales Pmt. Disc. Debit Acc.");
                                        PaymentDiscAcc := GenPostingSetup."Sales Pmt. Disc. Debit Acc.";
                                    END ELSE BEGIN
                                        GenPostingSetup.TESTFIELD("Sales Pmt. Disc. Credit Acc.");
                                        PaymentDiscAcc := GenPostingSetup."Sales Pmt. Disc. Credit Acc.";
                                    END;
                                    InitGLEntry(PaymentDiscAcc, -DtldCVLedgEntryBuf."Amount (LCY)", 0, FALSE, TRUE);
                                    GLEntry."Additional-Currency Amount" := -DtldCVLedgEntryBuf."Additional-Currency Amount";
                                    GLEntry."VAT Amount" := -DtldCVLedgEntryBuf."VAT Amount (LCY)";
                                    GLEntry."Gen. Posting Type" := DtldCVLedgEntryBuf."Gen. Posting Type";
                                    GLEntry."Gen. Bus. Posting Group" := DtldCVLedgEntryBuf."Gen. Bus. Posting Group";
                                    GLEntry."Gen. Prod. Posting Group" := DtldCVLedgEntryBuf."Gen. Prod. Posting Group";
                                    GLEntry."VAT Bus. Posting Group" := DtldCVLedgEntryBuf."VAT Bus. Posting Group";
                                    GLEntry."VAT Prod. Posting Group" := DtldCVLedgEntryBuf."VAT Prod. Posting Group";
                                    GLEntry."Tax Area Code" := DtldCVLedgEntryBuf."Tax Area Code";
                                    GLEntry."Tax Liable" := DtldCVLedgEntryBuf."Tax Liable";
                                    GLEntry."Tax Group Code" := DtldCVLedgEntryBuf."Tax Group Code";
                                    GLEntry."Use Tax" := DtldCVLedgEntryBuf."Use Tax";

                                    IF OriginalDateSet THEN
                                        CollectAddjustment(DebitAddjustmentApplDate, DebitAddjustmentAddCurrApplDat,
                                          CreditAddjustmentApplDate, CreditAddjustmentAddCurrApplDa,
                                          GLEntry.Amount, GLEntry."Additional-Currency Amount")
                                    ELSE
                                        CollectAddjustment(DebitAddjustment, DebitAddjustmentAddCurr,
                                          CreditAddjustment, CreditAddjustmentAddCurr,
                                          GLEntry.Amount, GLEntry."Additional-Currency Amount");
                                    InsertGLEntry(TRUE);

                                    InsertVatEntriesFromTemp(DtldCVLedgEntryBuf);
                                END;
                            DtldCVLedgEntryBuf."Entry Type"::"Payment Discount (VAT Adjustment)":
                                BEGIN
                                    // The g/l entries for this entry type are posted by the VAT functions.
                                END;
                            DtldCVLedgEntryBuf."Entry Type"::"Appln. Rounding":
                                BEGIN
                                    IF -DtldCVLedgEntryBuf."Amount (LCY)" > 0 THEN BEGIN
                                        CustPostingGr.TESTFIELD("Debit Curr. Appln. Rndg. Acc.");
                                        InitGLEntry(
                                          CustPostingGr."Debit Curr. Appln. Rndg. Acc.",
                                          -DtldCVLedgEntryBuf."Amount (LCY)",
                                          -DtldCVLedgEntryBuf."Additional-Currency Amount",
                                          TRUE, TRUE);

                                        IF OriginalDateSet THEN
                                            CollectAddjustment(DebitAddjustmentApplDate, DebitAddjustmentAddCurrApplDat,
                                              CreditAddjustmentApplDate, CreditAddjustmentAddCurrApplDa,
                                              GLEntry.Amount, GLEntry."Additional-Currency Amount")
                                        ELSE
                                            CollectAddjustment(DebitAddjustment, DebitAddjustmentAddCurr,
                                              CreditAddjustment, CreditAddjustmentAddCurr,
                                              GLEntry.Amount, GLEntry."Additional-Currency Amount");
                                        InsertGLEntry(TRUE);
                                    END;
                                    IF -DtldCVLedgEntryBuf."Amount (LCY)" < 0 THEN BEGIN
                                        CustPostingGr.TESTFIELD("Credit Curr. Appln. Rndg. Acc.");
                                        InitGLEntry(
                                          CustPostingGr."Credit Curr. Appln. Rndg. Acc.",
                                          -DtldCVLedgEntryBuf."Amount (LCY)",
                                          -DtldCVLedgEntryBuf."Additional-Currency Amount",
                                          TRUE, TRUE);

                                        IF OriginalDateSet THEN
                                            CollectAddjustment(DebitAddjustmentApplDate, DebitAddjustmentAddCurrApplDat,
                                              CreditAddjustmentApplDate, CreditAddjustmentAddCurrApplDa,
                                              GLEntry.Amount, GLEntry."Additional-Currency Amount")
                                        ELSE
                                            CollectAddjustment(DebitAddjustment, DebitAddjustmentAddCurr,
                                              CreditAddjustment, CreditAddjustmentAddCurr,
                                              GLEntry.Amount, GLEntry."Additional-Currency Amount");
                                        InsertGLEntry(TRUE);
                                    END;
                                END;
                            DtldCVLedgEntryBuf."Entry Type"::"Correction of Remaining Amount":
                                BEGIN
                                    IF -DtldCVLedgEntryBuf."Amount (LCY)" > 0 THEN BEGIN
                                        CustPostingGr.TESTFIELD("Debit Rounding Account");
                                        InitGLEntry(
                                          CustPostingGr."Debit Rounding Account", -DtldCVLedgEntryBuf."Amount (LCY)",
                                          0, FALSE, TRUE);
                                        GLEntry."Additional-Currency Amount" := 0;

                                        IF OriginalDateSet THEN
                                            CollectAddjustment(DebitAddjustmentApplDate, DebitAddjustmentAddCurrApplDat,
                                              CreditAddjustmentApplDate, CreditAddjustmentAddCurrApplDa,
                                              GLEntry.Amount, GLEntry."Additional-Currency Amount")
                                        ELSE
                                            CollectAddjustment(DebitAddjustment, DebitAddjustmentAddCurr,
                                              CreditAddjustment, CreditAddjustmentAddCurr,
                                              GLEntry.Amount, GLEntry."Additional-Currency Amount");
                                        InsertGLEntry(TRUE);
                                    END;
                                    IF -DtldCVLedgEntryBuf."Amount (LCY)" < 0 THEN BEGIN
                                        CustPostingGr.TESTFIELD("Credit Rounding Account");
                                        InitGLEntry(
                                          CustPostingGr."Credit Rounding Account", -DtldCVLedgEntryBuf."Amount (LCY)",
                                          0, FALSE, TRUE);
                                        GLEntry."Additional-Currency Amount" := 0;

                                        IF OriginalDateSet THEN
                                            CollectAddjustment(DebitAddjustmentApplDate, DebitAddjustmentAddCurrApplDat,
                                              CreditAddjustmentApplDate, CreditAddjustmentAddCurrApplDa,
                                              GLEntry.Amount, GLEntry."Additional-Currency Amount")
                                        ELSE
                                            CollectAddjustment(DebitAddjustment, DebitAddjustmentAddCurr,
                                              CreditAddjustment, CreditAddjustmentAddCurr,
                                              GLEntry.Amount, GLEntry."Additional-Currency Amount");
                                        InsertGLEntry(TRUE);
                                    END;
                                END;
                            DtldCVLedgEntryBuf."Entry Type"::"Payment Discount Tolerance":
                                BEGIN
                                    IF GLSetup."Pmt. Disc. Tolerance Posting" =
                                      GLSetup."Pmt. Disc. Tolerance Posting"::"Payment Tolerance Accounts"
                                    THEN BEGIN
                                        IF (DtldCVLedgEntryBuf."Amount (LCY)" <= 0) THEN BEGIN
                                            CustPostingGr.TESTFIELD("Payment Tolerance Debit Acc.");
                                            PaymentTolAcc := CustPostingGr."Payment Tolerance Debit Acc.";
                                        END ELSE BEGIN
                                            CustPostingGr.TESTFIELD("Payment Tolerance Credit Acc.");
                                            PaymentTolAcc := CustPostingGr."Payment Tolerance Credit Acc.";
                                        END;
                                    END ELSE
                                        IF GLSetup."Pmt. Disc. Tolerance Posting" =
                                 GLSetup."Pmt. Disc. Tolerance Posting"::"Payment Discount Accounts"
                               THEN BEGIN
                                            IF (DtldCVLedgEntryBuf."Amount (LCY)" <= 0) THEN BEGIN
                                                CustPostingGr.TESTFIELD("Payment Disc. Debit Acc.");
                                                PaymentTolAcc := CustPostingGr."Payment Disc. Debit Acc.";
                                            END ELSE BEGIN
                                                CustPostingGr.TESTFIELD("Payment Disc. Credit Acc.");
                                                PaymentTolAcc := CustPostingGr."Payment Disc. Credit Acc.";
                                            END;
                                        END;
                                    InitGLEntry(
                                      PaymentTolAcc, -DtldCVLedgEntryBuf."Amount (LCY)",
                                      0, FALSE, TRUE);
                                    GLEntry."Additional-Currency Amount" :=
                                      -DtldCVLedgEntryBuf."Additional-Currency Amount";

                                    IF OriginalDateSet THEN
                                        CollectAddjustment(DebitAddjustmentApplDate, DebitAddjustmentAddCurrApplDat,
                                          CreditAddjustmentApplDate, CreditAddjustmentAddCurrApplDa,
                                          GLEntry.Amount, GLEntry."Additional-Currency Amount")
                                    ELSE
                                        CollectAddjustment(DebitAddjustment, DebitAddjustmentAddCurr,
                                          CreditAddjustment, CreditAddjustmentAddCurr,
                                          GLEntry.Amount, GLEntry."Additional-Currency Amount");
                                    InsertGLEntry(TRUE);
                                END;
                            DtldCVLedgEntryBuf."Entry Type"::"Payment Tolerance":
                                BEGIN
                                    IF GLSetup."Payment Tolerance Posting" =
                                      GLSetup."Payment Tolerance Posting"::"Payment Tolerance Accounts"
                                    THEN BEGIN
                                        IF (DtldCVLedgEntryBuf."Amount (LCY)" <= 0) THEN BEGIN
                                            CustPostingGr.TESTFIELD("Payment Tolerance Debit Acc.");
                                            PaymentTolAcc := CustPostingGr."Payment Tolerance Debit Acc.";
                                        END ELSE BEGIN
                                            CustPostingGr.TESTFIELD("Payment Tolerance Credit Acc.");
                                            PaymentTolAcc := CustPostingGr."Payment Tolerance Credit Acc.";
                                        END;
                                    END ELSE
                                        IF GLSetup."Payment Tolerance Posting" =
                                 GLSetup."Payment Tolerance Posting"::"Payment Discount Accounts"
                               THEN BEGIN
                                            IF (DtldCVLedgEntryBuf."Amount (LCY)" <= 0) THEN BEGIN
                                                CustPostingGr.TESTFIELD("Payment Disc. Debit Acc.");
                                                PaymentTolAcc := CustPostingGr."Payment Disc. Debit Acc.";
                                            END ELSE BEGIN
                                                CustPostingGr.TESTFIELD("Payment Disc. Credit Acc.");
                                                PaymentTolAcc := CustPostingGr."Payment Disc. Credit Acc.";
                                            END;
                                        END;
                                    InitGLEntry(
                                      PaymentTolAcc, -DtldCVLedgEntryBuf."Amount (LCY)",
                                      0, FALSE, TRUE);
                                    GLEntry."Additional-Currency Amount" :=
                                      -DtldCVLedgEntryBuf."Additional-Currency Amount";

                                    IF OriginalDateSet THEN
                                        CollectAddjustment(DebitAddjustmentApplDate, DebitAddjustmentAddCurrApplDat,
                                          CreditAddjustmentApplDate, CreditAddjustmentAddCurrApplDa,
                                          GLEntry.Amount, GLEntry."Additional-Currency Amount")
                                    ELSE
                                        CollectAddjustment(DebitAddjustment, DebitAddjustmentAddCurr,
                                          CreditAddjustment, CreditAddjustmentAddCurr,
                                          GLEntry.Amount, GLEntry."Additional-Currency Amount");
                                    InsertGLEntry(TRUE);
                                END;
                            DtldCVLedgEntryBuf."Entry Type"::"Payment Tolerance (VAT Excl.)":
                                BEGIN
                                    GenPostingSetup.GET(
                                      DtldCVLedgEntryBuf."Gen. Bus. Posting Group",
                                      DtldCVLedgEntryBuf."Gen. Prod. Posting Group");
                                    IF GLSetup."Payment Tolerance Posting" =
                                      GLSetup."Payment Tolerance Posting"::"Payment Tolerance Accounts"
                                    THEN BEGIN
                                        IF (DtldCVLedgEntryBuf."Amount (LCY)" <= 0) THEN BEGIN
                                            GenPostingSetup.TESTFIELD("Sales Pmt. Tol. Debit Acc.");
                                            PaymentTolAcc := GenPostingSetup."Sales Pmt. Tol. Debit Acc.";
                                        END ELSE BEGIN
                                            GenPostingSetup.TESTFIELD("Sales Pmt. Tol. Credit Acc.");
                                            PaymentTolAcc := GenPostingSetup."Sales Pmt. Tol. Credit Acc.";
                                        END;
                                    END ELSE
                                        IF GLSetup."Payment Tolerance Posting" =
                                 GLSetup."Payment Tolerance Posting"::"Payment Discount Accounts"
                               THEN BEGIN
                                            IF (DtldCVLedgEntryBuf."Amount (LCY)" <= 0) THEN BEGIN
                                                GenPostingSetup.TESTFIELD("Sales Pmt. Disc. Debit Acc.");
                                                PaymentTolAcc := GenPostingSetup."Sales Pmt. Disc. Debit Acc.";
                                            END ELSE BEGIN
                                                GenPostingSetup.TESTFIELD("Sales Pmt. Disc. Credit Acc.");
                                                PaymentTolAcc := GenPostingSetup."Sales Pmt. Disc. Credit Acc.";
                                            END;
                                        END;
                                    InitGLEntry(PaymentTolAcc, -DtldCVLedgEntryBuf."Amount (LCY)", 0, FALSE, TRUE);
                                    GLEntry."Additional-Currency Amount" := -DtldCVLedgEntryBuf."Additional-Currency Amount";
                                    GLEntry."VAT Amount" := -DtldCVLedgEntryBuf."VAT Amount (LCY)";
                                    GLEntry."Gen. Posting Type" := DtldCVLedgEntryBuf."Gen. Posting Type";
                                    GLEntry."Gen. Bus. Posting Group" := DtldCVLedgEntryBuf."Gen. Bus. Posting Group";
                                    GLEntry."Gen. Prod. Posting Group" := DtldCVLedgEntryBuf."Gen. Prod. Posting Group";
                                    GLEntry."VAT Bus. Posting Group" := DtldCVLedgEntryBuf."VAT Bus. Posting Group";
                                    GLEntry."VAT Prod. Posting Group" := DtldCVLedgEntryBuf."VAT Prod. Posting Group";
                                    GLEntry."Tax Area Code" := DtldCVLedgEntryBuf."Tax Area Code";
                                    GLEntry."Tax Liable" := DtldCVLedgEntryBuf."Tax Liable";
                                    GLEntry."Tax Group Code" := DtldCVLedgEntryBuf."Tax Group Code";
                                    GLEntry."Use Tax" := DtldCVLedgEntryBuf."Use Tax";

                                    IF OriginalDateSet THEN
                                        CollectAddjustment(DebitAddjustmentApplDate, DebitAddjustmentAddCurrApplDat,
                                          CreditAddjustmentApplDate, CreditAddjustmentAddCurrApplDa,
                                          GLEntry.Amount, GLEntry."Additional-Currency Amount")
                                    ELSE
                                        CollectAddjustment(DebitAddjustment, DebitAddjustmentAddCurr,
                                          CreditAddjustment, CreditAddjustmentAddCurr,
                                          GLEntry.Amount, GLEntry."Additional-Currency Amount");
                                    InsertGLEntry(TRUE);

                                    InsertVatEntriesFromTemp(DtldCVLedgEntryBuf);
                                END;
                            DtldCVLedgEntryBuf."Entry Type"::"Payment Discount Tolerance (VAT Excl.)":
                                BEGIN
                                    GenPostingSetup.GET(
                                      DtldCVLedgEntryBuf."Gen. Bus. Posting Group",
                                      DtldCVLedgEntryBuf."Gen. Prod. Posting Group");
                                    IF GLSetup."Pmt. Disc. Tolerance Posting" =
                                      GLSetup."Pmt. Disc. Tolerance Posting"::"Payment Tolerance Accounts"
                                    THEN BEGIN
                                        IF (DtldCVLedgEntryBuf."Amount (LCY)" <= 0) THEN BEGIN
                                            GenPostingSetup.TESTFIELD("Sales Pmt. Tol. Debit Acc.");
                                            PaymentTolAcc := GenPostingSetup."Sales Pmt. Tol. Debit Acc.";
                                        END ELSE BEGIN
                                            GenPostingSetup.TESTFIELD("Sales Pmt. Tol. Credit Acc.");
                                            PaymentTolAcc := GenPostingSetup."Sales Pmt. Tol. Credit Acc.";
                                        END;
                                    END ELSE
                                        IF GLSetup."Pmt. Disc. Tolerance Posting" =
                                 GLSetup."Pmt. Disc. Tolerance Posting"::"Payment Discount Accounts"
                               THEN BEGIN
                                            IF (DtldCVLedgEntryBuf."Amount (LCY)" <= 0) THEN BEGIN
                                                GenPostingSetup.TESTFIELD("Sales Pmt. Disc. Debit Acc.");
                                                PaymentTolAcc := GenPostingSetup."Sales Pmt. Disc. Debit Acc.";
                                            END ELSE BEGIN
                                                GenPostingSetup.TESTFIELD("Sales Pmt. Disc. Credit Acc.");
                                                PaymentTolAcc := GenPostingSetup."Sales Pmt. Disc. Credit Acc.";
                                            END;
                                        END;
                                    InitGLEntry(PaymentTolAcc, -DtldCVLedgEntryBuf."Amount (LCY)", 0, FALSE, TRUE);
                                    GLEntry."Additional-Currency Amount" := -DtldCVLedgEntryBuf."Additional-Currency Amount";
                                    GLEntry."VAT Amount" := -DtldCVLedgEntryBuf."VAT Amount (LCY)";
                                    GLEntry."Gen. Posting Type" := DtldCVLedgEntryBuf."Gen. Posting Type";
                                    GLEntry."Gen. Bus. Posting Group" := DtldCVLedgEntryBuf."Gen. Bus. Posting Group";
                                    GLEntry."Gen. Prod. Posting Group" := DtldCVLedgEntryBuf."Gen. Prod. Posting Group";
                                    GLEntry."VAT Bus. Posting Group" := DtldCVLedgEntryBuf."VAT Bus. Posting Group";
                                    GLEntry."VAT Prod. Posting Group" := DtldCVLedgEntryBuf."VAT Prod. Posting Group";
                                    GLEntry."Tax Area Code" := DtldCVLedgEntryBuf."Tax Area Code";
                                    GLEntry."Tax Liable" := DtldCVLedgEntryBuf."Tax Liable";
                                    GLEntry."Tax Group Code" := DtldCVLedgEntryBuf."Tax Group Code";
                                    GLEntry."Use Tax" := DtldCVLedgEntryBuf."Use Tax";

                                    IF OriginalDateSet THEN
                                        CollectAddjustment(DebitAddjustmentApplDate, DebitAddjustmentAddCurrApplDat,
                                          CreditAddjustmentApplDate, CreditAddjustmentAddCurrApplDa,
                                          GLEntry.Amount, GLEntry."Additional-Currency Amount")
                                    ELSE
                                        CollectAddjustment(DebitAddjustment, DebitAddjustmentAddCurr,
                                          CreditAddjustment, CreditAddjustmentAddCurr,
                                          GLEntry.Amount, GLEntry."Additional-Currency Amount");
                                    InsertGLEntry(TRUE);

                                    InsertVatEntriesFromTemp(DtldCVLedgEntryBuf);
                                END;
                            DtldCVLedgEntryBuf."Entry Type"::"Payment Tolerance (VAT Adjustment)",
                            DtldCVLedgEntryBuf."Entry Type"::"Payment Discount Tolerance (VAT Adjustment)":
                                BEGIN
                                    // The g/l entries for this entry type are posted by the VAT functions.
                                END;
                            ELSE
                                DtldCVLedgEntryBuf.FIELDERROR("Entry Type");
                        END;
                    //APNT-IBU1.0
                    IF DtldCVLedgEntryBuf."IBU Entry" = TRUE THEN BEGIN
                        DtldCustLedgEntryNoOffset += 1;
                        DtldCustLedgEntry.INIT;
                        DtldCustLedgEntry.TRANSFERFIELDS(DtldCVLedgEntryBuf);
                        DtldCustLedgEntry."Entry No." := DtldCustLedgEntryNoOffset + DtldCVLedgEntryBuf."Entry No.";
                        DtldCustLedgEntry."Entry Type" := DtldCustLedgEntry."Entry Type"::Application;
                        DtldCustLedgEntry."Journal Batch Name" := GenJnlLine."Journal Batch Name";
                        DtldCustLedgEntry."Reason Code" := GenJnlLine."Reason Code";
                        DtldCustLedgEntry."Source Code" := GenJnlLine."Source Code";
                        DtldCustLedgEntry."Transaction No." := NextTransactionNo;
                        DtldCustLedgEntry.Amount := -DtldCVLedgEntryBuf.Amount;
                        DtldCustLedgEntry."Amount (LCY)" := -DtldCVLedgEntryBuf."Amount (LCY)";
                        DtldCustLedgEntry."Debit Amount" := DtldCVLedgEntryBuf."Credit Amount";
                        DtldCustLedgEntry."Credit Amount" := DtldCVLedgEntryBuf."Debit Amount";
                        DtldCustLedgEntry."Debit Amount (LCY)" := DtldCVLedgEntryBuf."Credit Amount (LCY)";
                        DtldCustLedgEntry."Credit Amount (LCY)" := DtldCVLedgEntryBuf."Debit Amount (LCY)";
                        CustUpdateDebitCredit(GenJnlLine.Correction, DtldCustLedgEntry);
                        IF DtldCustLedgEntry.Amount <> 0 THEN //APNT-RBT1.0
                            DtldCustLedgEntry.INSERT;

                        CustLedgEntryRec2.GET(DtldCVLedgEntryBuf."Cust. Ledger Entry No.");
                        CustLedgEntryRec2.Open := FALSE;
                        CustLedgEntryRec2.MODIFY;
                    END;
                    //APNT-IBU1.0

                    IF OriginalDateSet THEN BEGIN
                        GenJnlLine."Posting Date" := OriginalPostingDate;
                        OriginalDateSet := FALSE;
                    END;
                UNTIL DtldCVLedgEntryBuf.NEXT = 0;
            END;

            IF CustLedgEntryInserted OR (TotalAmountLCY <> 0) OR
               (TotalAmountAddCurr <> 0) AND (GLSetup."Additional Reporting Currency" <> '')
            THEN BEGIN
                HandlDtlAddjustment(DebitAddjustment, DebitAddjustmentAddCurr, CreditAddjustment, CreditAddjustmentAddCurr,
                  TotalAmountLCY, TotalAmountAddCurr, CustPostingGr."Receivables Account");
                GLEntry."Bal. Account Type" := GenJnlLine2."Bal. Account Type";
                GLEntry."Bal. Account No." := GenJnlLine2."Bal. Account No.";
                IF CustLedgEntryInserted THEN BEGIN
                    GLEntry."Entry No." := SaveEntryNo;
                    NextEntryNo := NextEntryNo - 1;
                    SavedEntryUsed := TRUE;
                END;
                InsertGLEntry(TRUE);
            END;

            IF (TotalAmountLCYApplDate <> 0) OR
               (TotalAmountAddCurrApplDate <> 0) AND (GLSetup."Additional Reporting Currency" <> '')
            THEN BEGIN
                GenJnlLine."Posting Date" := ApplicationDate;
                HandlDtlAddjustment(DebitAddjustmentApplDate,
                  DebitAddjustmentAddCurrApplDat,
                  CreditAddjustmentApplDate,
                  CreditAddjustmentAddCurrApplDa,
                  TotalAmountLCYApplDate,
                  TotalAmountAddCurrApplDate,
                  CustPostingGr."Receivables Account");
                IF CustLedgEntryInserted AND NOT SavedEntryUsed THEN BEGIN
                    GLEntry."Entry No." := SaveEntryNo;
                    NextEntryNo := NextEntryNo - 1;
                END;
                InsertGLEntry(TRUE);
                GenJnlLine."Posting Date" := OriginalPostingDate;
            END;

            IF NOT GLEntryTmp.FINDFIRST AND DtldCVLedgEntryBuf.FINDFIRST THEN BEGIN
                InitGLEntry(CustPostingGr."Receivables Account", PositiveLCYAppAmt, PositiveACYAppAmt, FALSE, TRUE);
                InsertGLEntry(FALSE);
                InitGLEntry(CustPostingGr."Receivables Account", NegativeLCYAppAmt, NegativeACYAppAmt, FALSE, TRUE);
                InsertGLEntry(FALSE);
            END;
            DtldCVLedgEntryBuf.DELETEALL;
        END;
    end;

    local procedure AutoEntrForDtldCustLedgEntries(DtldCVLedgEntryBuf: Record "383"; OriginalTransactionNo: Integer)
    var
        GenPostingSetup: Record "252";
        VATPostingSetup: Record "VAT Posting Setup";
        TaxJurisdiction: Record "320";
        AccNo: Code[20];
    begin
        IF (DtldCVLedgEntryBuf."Amount (LCY)" = 0) AND
           ((GLSetup."Additional Reporting Currency" = '') OR
            (DtldCVLedgEntryBuf."Additional-Currency Amount" = 0))
        THEN
            EXIT;

        CASE DtldCVLedgEntryBuf."Entry Type" OF
            DtldCVLedgEntryBuf."Entry Type"::"Initial Entry":
                ;
            DtldCVLedgEntryBuf."Entry Type"::Application:
                ;
            DtldCVLedgEntryBuf."Entry Type"::"Unrealized Loss":
                BEGIN
                    IF Currency.Code <> DtldCVLedgEntryBuf."Currency Code" THEN BEGIN
                        IF DtldCVLedgEntryBuf."Currency Code" = '' THEN
                            CLEAR(Currency)
                        ELSE
                            Currency.GET(DtldCVLedgEntryBuf."Currency Code");
                    END;
                    CheckNonAddCurrCodeOccurred(Currency.Code);
                    Currency.TESTFIELD("Unrealized Losses Acc.");
                    InitGLEntry(
                      Currency."Unrealized Losses Acc.", -DtldCVLedgEntryBuf."Amount (LCY)",
                      0, DtldCVLedgEntryBuf."Currency Code" = GLSetup."Additional Reporting Currency",
                      TRUE);
                    InsertGLEntry(TRUE);
                END;
            DtldCVLedgEntryBuf."Entry Type"::"Unrealized Gain":
                BEGIN
                    IF Currency.Code <> DtldCVLedgEntryBuf."Currency Code" THEN BEGIN
                        IF DtldCVLedgEntryBuf."Currency Code" = '' THEN
                            CLEAR(Currency)
                        ELSE
                            Currency.GET(DtldCVLedgEntryBuf."Currency Code");
                    END;
                    CheckNonAddCurrCodeOccurred(Currency.Code);
                    Currency.TESTFIELD("Unrealized Gains Acc.");
                    InitGLEntry(
                      Currency."Unrealized Gains Acc.", -DtldCVLedgEntryBuf."Amount (LCY)",
                      0, DtldCVLedgEntryBuf."Currency Code" = GLSetup."Additional Reporting Currency",
                      TRUE);
                    InsertGLEntry(TRUE);
                END;
            DtldCVLedgEntryBuf."Entry Type"::"Realized Loss":
                BEGIN
                    IF Currency.Code <> DtldCVLedgEntryBuf."Currency Code" THEN BEGIN
                        IF DtldCVLedgEntryBuf."Currency Code" = '' THEN
                            CLEAR(Currency)
                        ELSE
                            Currency.GET(DtldCVLedgEntryBuf."Currency Code");
                    END;
                    CheckNonAddCurrCodeOccurred(Currency.Code);
                    Currency.TESTFIELD("Realized Losses Acc.");
                    InitGLEntry(
                      Currency."Realized Losses Acc.", -DtldCVLedgEntryBuf."Amount (LCY)",
                      0, DtldCVLedgEntryBuf."Currency Code" = GLSetup."Additional Reporting Currency",
                      TRUE);
                    InsertGLEntry(TRUE);
                END;
            DtldCVLedgEntryBuf."Entry Type"::"Realized Gain":
                BEGIN
                    IF Currency.Code <> DtldCVLedgEntryBuf."Currency Code" THEN BEGIN
                        IF DtldCVLedgEntryBuf."Currency Code" = '' THEN
                            CLEAR(Currency)
                        ELSE
                            Currency.GET(DtldCVLedgEntryBuf."Currency Code");
                    END;
                    CheckNonAddCurrCodeOccurred(Currency.Code);
                    Currency.TESTFIELD("Realized Gains Acc.");
                    InitGLEntry(
                      Currency."Realized Gains Acc.", -DtldCVLedgEntryBuf."Amount (LCY)",
                      0, DtldCVLedgEntryBuf."Currency Code" = GLSetup."Additional Reporting Currency",
                      TRUE);
                    InsertGLEntry(TRUE);
                END;
            DtldCVLedgEntryBuf."Entry Type"::"Payment Discount":
                BEGIN
                    IF DtldCVLedgEntryBuf."Amount (LCY)" > 0 THEN BEGIN
                        CustPostingGr.TESTFIELD("Payment Disc. Debit Acc.");
                        AccNo := CustPostingGr."Payment Disc. Debit Acc.";
                    END ELSE BEGIN
                        CustPostingGr.TESTFIELD("Payment Disc. Credit Acc.");
                        AccNo := CustPostingGr."Payment Disc. Credit Acc.";
                    END;
                    InitGLEntry(AccNo, -DtldCVLedgEntryBuf."Amount (LCY)", 0, FALSE, TRUE);
                    GLEntry."Additional-Currency Amount" := -DtldCVLedgEntryBuf."Additional-Currency Amount";
                    InsertGLEntry(TRUE);
                END;
            DtldCVLedgEntryBuf."Entry Type"::"Payment Discount (VAT Excl.)":
                BEGIN
                    DtldCVLedgEntryBuf.TESTFIELD("Gen. Prod. Posting Group");
                    GenPostingSetup.GET(
                      DtldCVLedgEntryBuf."Gen. Bus. Posting Group",
                      DtldCVLedgEntryBuf."Gen. Prod. Posting Group");
                    IF DtldCVLedgEntryBuf."Amount (LCY)" > 0 THEN BEGIN
                        GenPostingSetup.TESTFIELD("Sales Pmt. Disc. Debit Acc.");
                        AccNo := GenPostingSetup."Sales Pmt. Disc. Debit Acc.";
                    END ELSE BEGIN
                        GenPostingSetup.TESTFIELD("Sales Pmt. Disc. Credit Acc.");
                        AccNo := GenPostingSetup."Sales Pmt. Disc. Credit Acc.";
                    END;
                    InitGLEntry(AccNo, -DtldCVLedgEntryBuf."Amount (LCY)", 0, FALSE, TRUE);
                    GLEntry."Additional-Currency Amount" := -DtldCVLedgEntryBuf."Additional-Currency Amount";
                    GLEntry."VAT Amount" := -DtldCVLedgEntryBuf."VAT Amount (LCY)";
                    GLEntry."Gen. Posting Type" := GLEntry."Gen. Posting Type"::Sale;
                    GLEntry."Gen. Bus. Posting Group" := DtldCVLedgEntryBuf."Gen. Bus. Posting Group";
                    GLEntry."Gen. Prod. Posting Group" := DtldCVLedgEntryBuf."Gen. Prod. Posting Group";
                    GLEntry."VAT Bus. Posting Group" := DtldCVLedgEntryBuf."VAT Bus. Posting Group";
                    GLEntry."VAT Prod. Posting Group" := DtldCVLedgEntryBuf."VAT Prod. Posting Group";
                    GLEntry."Tax Area Code" := DtldCVLedgEntryBuf."Tax Area Code";
                    GLEntry."Tax Liable" := DtldCVLedgEntryBuf."Tax Liable";
                    GLEntry."Tax Group Code" := DtldCVLedgEntryBuf."Tax Group Code";
                    GLEntry."Use Tax" := DtldCVLedgEntryBuf."Use Tax";
                    InsertGLEntry(TRUE);

                    InsertVatEntriesFromTemp(DtldCVLedgEntryBuf);
                END;
            DtldCVLedgEntryBuf."Entry Type"::"Payment Discount (VAT Adjustment)",
            DtldCVLedgEntryBuf."Entry Type"::"Payment Tolerance (VAT Adjustment)",
            DtldCVLedgEntryBuf."Entry Type"::"Payment Discount Tolerance (VAT Adjustment)":
                BEGIN
                    VATEntry.SETRANGE("Transaction No.", OriginalTransactionNo);
                    VATEntry.SETRANGE("VAT Bus. Posting Group", DtldCVLedgEntryBuf."VAT Bus. Posting Group");
                    VATEntry.SETRANGE("VAT Prod. Posting Group", DtldCVLedgEntryBuf."VAT Prod. Posting Group");
                    VATEntry.FINDFIRST;

                    VATPostingSetup.GET(
                      DtldCVLedgEntryBuf."VAT Bus. Posting Group",
                      DtldCVLedgEntryBuf."VAT Prod. Posting Group");
                    VATPostingSetup.TESTFIELD("VAT Calculation Type", VATEntry."VAT Calculation Type");
                    CLEAR(VATEntry);

                    CASE VATPostingSetup."VAT Calculation Type" OF
                        VATPostingSetup."VAT Calculation Type"::"Normal VAT",
                        VATPostingSetup."VAT Calculation Type"::"Full VAT":
                            BEGIN
                                VATPostingSetup.TESTFIELD("Sales VAT Account");
                                AccNo := VATPostingSetup."Sales VAT Account";
                            END;
                        VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT":
                            ;
                        VATPostingSetup."VAT Calculation Type"::"Sales Tax":
                            BEGIN
                                DtldCVLedgEntryBuf.TESTFIELD("Tax Jurisdiction Code");
                                TaxJurisdiction.GET(DtldCVLedgEntryBuf."Tax Jurisdiction Code");
                                TaxJurisdiction.TESTFIELD("Tax Account (Sales)");
                                AccNo := TaxJurisdiction."Tax Account (Sales)"
                            END;
                    END;
                    InitGLEntry(
                      AccNo, -DtldCVLedgEntryBuf."Amount (LCY)", 0, FALSE, TRUE);
                    GLEntry."Additional-Currency Amount" := -DtldCVLedgEntryBuf."Additional-Currency Amount";
                    InsertGLEntry(TRUE);
                END;
            DtldCVLedgEntryBuf."Entry Type"::"Appln. Rounding":
                IF -DtldCVLedgEntryBuf."Amount (LCY)" <> 0 THEN BEGIN
                    CASE TRUE OF
                        -DtldCVLedgEntryBuf."Amount (LCY)" < 0:
                            BEGIN
                                CustPostingGr.TESTFIELD("Debit Curr. Appln. Rndg. Acc.");
                                AccNo := CustPostingGr."Debit Curr. Appln. Rndg. Acc.";
                            END;
                        -DtldCVLedgEntryBuf."Amount (LCY)" > 0:
                            BEGIN
                                CustPostingGr.TESTFIELD("Credit Curr. Appln. Rndg. Acc.");
                                AccNo := CustPostingGr."Credit Curr. Appln. Rndg. Acc.";
                            END;
                    END;
                    InitGLEntry(
                      AccNo,
                      -DtldCVLedgEntryBuf."Amount (LCY)",
                      -DtldCVLedgEntryBuf."Additional-Currency Amount",
                      TRUE, TRUE);
                    InsertGLEntry(TRUE);
                END;
            DtldCVLedgEntryBuf."Entry Type"::"Correction of Remaining Amount":
                IF -DtldCVLedgEntryBuf."Amount (LCY)" <> 0 THEN BEGIN
                    CASE TRUE OF
                        -DtldCVLedgEntryBuf."Amount (LCY)" < 0:
                            BEGIN
                                CustPostingGr.TESTFIELD("Debit Rounding Account");
                                AccNo := CustPostingGr."Debit Rounding Account";
                            END;
                        -DtldCVLedgEntryBuf."Amount (LCY)" > 0:
                            BEGIN
                                CustPostingGr.TESTFIELD("Credit Rounding Account");
                                AccNo := CustPostingGr."Credit Rounding Account";
                            END;
                    END;
                    InitGLEntry(
                      AccNo, -DtldCVLedgEntryBuf."Amount (LCY)", 0, FALSE, TRUE);
                    GLEntry."Additional-Currency Amount" := 0;
                    InsertGLEntry(TRUE);
                END;
            DtldCVLedgEntryBuf."Entry Type"::"Payment Discount Tolerance":
                BEGIN
                    CASE GLSetup."Pmt. Disc. Tolerance Posting" OF
                        GLSetup."Pmt. Disc. Tolerance Posting"::"Payment Tolerance Accounts":
                            IF DtldCVLedgEntryBuf."Amount (LCY)" > 0 THEN BEGIN
                                CustPostingGr.TESTFIELD("Payment Tolerance Debit Acc.");
                                AccNo := CustPostingGr."Payment Tolerance Debit Acc.";
                            END ELSE BEGIN
                                CustPostingGr.TESTFIELD("Payment Tolerance Credit Acc.");
                                AccNo := CustPostingGr."Payment Tolerance Credit Acc.";
                            END;
                        GLSetup."Pmt. Disc. Tolerance Posting"::"Payment Discount Accounts":
                            IF DtldCVLedgEntryBuf."Amount (LCY)" > 0 THEN BEGIN
                                CustPostingGr.TESTFIELD("Payment Disc. Debit Acc.");
                                AccNo := CustPostingGr."Payment Disc. Debit Acc.";
                            END ELSE BEGIN
                                CustPostingGr.TESTFIELD("Payment Disc. Credit Acc.");
                                AccNo := CustPostingGr."Payment Disc. Credit Acc.";
                            END;
                    END;
                    InitGLEntry(
                      AccNo, -DtldCVLedgEntryBuf."Amount (LCY)", 0, FALSE, TRUE);
                    GLEntry."Additional-Currency Amount" := -DtldCVLedgEntryBuf."Additional-Currency Amount";
                    InsertGLEntry(TRUE);
                END;
            DtldCVLedgEntryBuf."Entry Type"::"Payment Tolerance":
                BEGIN
                    CASE GLSetup."Payment Tolerance Posting" OF
                        GLSetup."Payment Tolerance Posting"::"Payment Tolerance Accounts":
                            IF DtldCVLedgEntryBuf."Amount (LCY)" > 0 THEN BEGIN
                                CustPostingGr.TESTFIELD("Payment Tolerance Debit Acc.");
                                AccNo := CustPostingGr."Payment Tolerance Debit Acc.";
                            END ELSE BEGIN
                                CustPostingGr.TESTFIELD("Payment Tolerance Credit Acc.");
                                AccNo := CustPostingGr."Payment Tolerance Credit Acc.";
                            END;
                        GLSetup."Payment Tolerance Posting"::"Payment Discount Accounts":
                            IF DtldCVLedgEntryBuf."Amount (LCY)" > 0 THEN BEGIN
                                CustPostingGr.TESTFIELD("Payment Disc. Debit Acc.");
                                AccNo := CustPostingGr."Payment Disc. Debit Acc.";
                            END ELSE BEGIN
                                CustPostingGr.TESTFIELD("Payment Disc. Credit Acc.");
                                AccNo := CustPostingGr."Payment Disc. Credit Acc.";
                            END;
                    END;
                    InitGLEntry(
                      AccNo, -DtldCVLedgEntryBuf."Amount (LCY)", 0, FALSE, TRUE);
                    GLEntry."Additional-Currency Amount" :=
                      -DtldCVLedgEntryBuf."Additional-Currency Amount";
                    InsertGLEntry(TRUE);
                END;
            DtldCVLedgEntryBuf."Entry Type"::"Payment Tolerance (VAT Excl.)":
                BEGIN
                    DtldCVLedgEntryBuf.TESTFIELD("Gen. Prod. Posting Group");
                    GenPostingSetup.GET(
                      DtldCVLedgEntryBuf."Gen. Bus. Posting Group",
                      DtldCVLedgEntryBuf."Gen. Prod. Posting Group");
                    CASE GLSetup."Payment Tolerance Posting" OF
                        GLSetup."Payment Tolerance Posting"::"Payment Tolerance Accounts":
                            IF DtldCVLedgEntryBuf."Amount (LCY)" > 0 THEN BEGIN
                                GenPostingSetup.TESTFIELD("Sales Pmt. Tol. Debit Acc.");
                                AccNo := GenPostingSetup."Sales Pmt. Tol. Debit Acc.";
                            END ELSE BEGIN
                                GenPostingSetup.TESTFIELD("Sales Pmt. Tol. Credit Acc.");
                                AccNo := GenPostingSetup."Sales Pmt. Tol. Credit Acc.";
                            END;
                        GLSetup."Payment Tolerance Posting"::"Payment Discount Accounts":
                            IF DtldCVLedgEntryBuf."Amount (LCY)" > 0 THEN BEGIN
                                GenPostingSetup.TESTFIELD("Sales Pmt. Disc. Debit Acc.");
                                AccNo := GenPostingSetup."Sales Pmt. Disc. Debit Acc.";
                            END ELSE BEGIN
                                GenPostingSetup.TESTFIELD("Sales Pmt. Disc. Credit Acc.");
                                AccNo := GenPostingSetup."Sales Pmt. Disc. Credit Acc.";
                            END;
                    END;
                    InitGLEntry(AccNo, -DtldCVLedgEntryBuf."Amount (LCY)", 0, FALSE, TRUE);
                    GLEntry."Additional-Currency Amount" := -DtldCVLedgEntryBuf."Additional-Currency Amount";
                    GLEntry."Gen. Posting Type" := GLEntry."Gen. Posting Type"::Sale;
                    GLEntry."Gen. Bus. Posting Group" := DtldCVLedgEntryBuf."Gen. Bus. Posting Group";
                    GLEntry."Gen. Prod. Posting Group" := DtldCVLedgEntryBuf."Gen. Prod. Posting Group";
                    GLEntry."VAT Bus. Posting Group" := DtldCVLedgEntryBuf."VAT Bus. Posting Group";
                    GLEntry."VAT Prod. Posting Group" := DtldCVLedgEntryBuf."VAT Prod. Posting Group";
                    GLEntry."Tax Area Code" := DtldCVLedgEntryBuf."Tax Area Code";
                    GLEntry."Tax Liable" := DtldCVLedgEntryBuf."Tax Liable";
                    GLEntry."Tax Group Code" := DtldCVLedgEntryBuf."Tax Group Code";
                    GLEntry."Use Tax" := DtldCVLedgEntryBuf."Use Tax";
                    InsertGLEntry(TRUE);

                    InsertVatEntriesFromTemp(DtldCVLedgEntryBuf);
                END;
            DtldCVLedgEntryBuf."Entry Type"::"Payment Discount Tolerance (VAT Excl.)":
                BEGIN
                    GenPostingSetup.GET(
                      DtldCVLedgEntryBuf."Gen. Bus. Posting Group",
                      DtldCVLedgEntryBuf."Gen. Prod. Posting Group");
                    CASE GLSetup."Pmt. Disc. Tolerance Posting" OF
                        GLSetup."Pmt. Disc. Tolerance Posting"::"Payment Tolerance Accounts":
                            IF DtldCVLedgEntryBuf."Amount (LCY)" > 0 THEN BEGIN
                                GenPostingSetup.TESTFIELD("Sales Pmt. Tol. Debit Acc.");
                                AccNo := GenPostingSetup."Sales Pmt. Tol. Debit Acc.";
                            END ELSE BEGIN
                                GenPostingSetup.TESTFIELD("Sales Pmt. Tol. Credit Acc.");
                                AccNo := GenPostingSetup."Sales Pmt. Tol. Credit Acc.";
                            END;
                        GLSetup."Pmt. Disc. Tolerance Posting"::"Payment Discount Accounts":
                            IF DtldCVLedgEntryBuf."Amount (LCY)" > 0 THEN BEGIN
                                GenPostingSetup.TESTFIELD("Sales Pmt. Disc. Debit Acc.");
                                AccNo := GenPostingSetup."Sales Pmt. Disc. Debit Acc.";
                            END ELSE BEGIN
                                GenPostingSetup.TESTFIELD("Sales Pmt. Disc. Credit Acc.");
                                AccNo := GenPostingSetup."Sales Pmt. Disc. Credit Acc.";
                            END;
                    END;
                    InitGLEntry(AccNo, -DtldCVLedgEntryBuf."Amount (LCY)", 0, FALSE, TRUE);
                    GLEntry."Additional-Currency Amount" := -DtldCVLedgEntryBuf."Additional-Currency Amount";
                    GLEntry."Gen. Posting Type" := GLEntry."Gen. Posting Type"::Sale;
                    GLEntry."Gen. Bus. Posting Group" := DtldCVLedgEntryBuf."Gen. Bus. Posting Group";
                    GLEntry."Gen. Prod. Posting Group" := DtldCVLedgEntryBuf."Gen. Prod. Posting Group";
                    GLEntry."VAT Bus. Posting Group" := DtldCVLedgEntryBuf."VAT Bus. Posting Group";
                    GLEntry."VAT Prod. Posting Group" := DtldCVLedgEntryBuf."VAT Prod. Posting Group";
                    GLEntry."Tax Area Code" := DtldCVLedgEntryBuf."Tax Area Code";
                    GLEntry."Tax Liable" := DtldCVLedgEntryBuf."Tax Liable";
                    GLEntry."Tax Group Code" := DtldCVLedgEntryBuf."Tax Group Code";
                    GLEntry."Use Tax" := DtldCVLedgEntryBuf."Use Tax";
                    InsertGLEntry(TRUE);

                    InsertVatEntriesFromTemp(DtldCVLedgEntryBuf);
                END;
            ELSE
                DtldCVLedgEntryBuf.FIELDERROR("Entry Type");
        END;
    end;

    local procedure CustUpdateDebitCredit(Correction: Boolean; var DtldCustLedgEntry: Record "379")
    begin
        WITH DtldCustLedgEntry DO BEGIN
            IF ((Amount > 0) OR ("Amount (LCY)" > 0)) AND NOT Correction OR
               ((Amount < 0) OR ("Amount (LCY)" < 0)) AND Correction
            THEN BEGIN
                "Debit Amount" := Amount;
                "Credit Amount" := 0;
                "Debit Amount (LCY)" := "Amount (LCY)";
                "Credit Amount (LCY)" := 0;
            END ELSE BEGIN
                "Debit Amount" := 0;
                "Credit Amount" := -Amount;
                "Debit Amount (LCY)" := 0;
                "Credit Amount (LCY)" := -"Amount (LCY)";
            END;
        END;
    end;

    local procedure ApplyVendLedgEntry(var NewCVLedgEntryBuf: Record "382"; var DtldCVLedgEntryBuf: Record "383"; GenJnlLine: Record "Gen. Journal Line"; ApplnRoundingPrecision: Decimal)
    var
        OldVendLedgEntry: Record "25";
        OldCVLedgEntryBuf: Record "382";
        OldCVLedgEntryBuf2: Record "382";
        NewVendLedgEntry: Record "25";
        NewCVLedgEntryBuf2: Record "382";
        OldCVLedgEntryBuf3: Record "382";
        TempOldVendLedgEntry: Record "25" temporary;
        Completed: Boolean;
        AppliedAmount: Decimal;
        AppliedAmountLCY: Decimal;
        OldAppliedAmount: Decimal;
        TempAmount: Decimal;
        NewRemainingAmtBeforeAppln: Decimal;
        OldRemainingAmtBeforeAppln: Decimal;
        ApplyingDate: Date;
        PmtTolAmtToBeApplied: Decimal;
    begin
        IF NewCVLedgEntryBuf."Amount to Apply" = 0 THEN
            EXIT;

        AllApplied := TRUE;
        IF (GenJnlLine."Applies-to Doc. No." = '') AND (GenJnlLine."Applies-to ID" = '') AND
           NOT
             ((Vend."Application Method" = Vend."Application Method"::"Apply to Oldest") AND
              GenJnlLine."Allow Application")
        THEN
            EXIT;

        PmtTolAmtToBeApplied := 0;
        NewRemainingAmtBeforeAppln := NewCVLedgEntryBuf."Remaining Amount";
        NewCVLedgEntryBuf2 := NewCVLedgEntryBuf;

        IF NewCVLedgEntryBuf."Currency Code" <> '' THEN BEGIN
            // Management of application of already posted entries
            IF NewCVLedgEntryBuf."Currency Code" <> ApplnCurrency.Code THEN
                ApplnCurrency.GET(NewCVLedgEntryBuf."Currency Code");
            ApplnRoundingPrecision := ApplnCurrency."Appln. Rounding Precision";
        END ELSE
            ApplnRoundingPrecision := GLSetup."Appln. Rounding Precision";
        ApplyingDate := GenJnlLine."Posting Date";

        IF GenJnlLine."Applies-to Doc. No." <> '' THEN BEGIN
            // Find the entry to be applied to
            OldVendLedgEntry.RESET;
            OldVendLedgEntry.SETCURRENTKEY("Document No.");
            OldVendLedgEntry.SETRANGE("Document No.", GenJnlLine."Applies-to Doc. No.");
            OldVendLedgEntry.SETRANGE("Document Type", GenJnlLine."Applies-to Doc. Type");
            OldVendLedgEntry.SETRANGE("Vendor No.", NewCVLedgEntryBuf."CV No.");
            OldVendLedgEntry.SETRANGE(Open, TRUE);
            OldVendLedgEntry.FINDFIRST;
            OldVendLedgEntry.TESTFIELD(Positive, NOT NewCVLedgEntryBuf.Positive);
            IF OldVendLedgEntry."Posting Date" > ApplyingDate THEN
                ApplyingDate := OldVendLedgEntry."Posting Date";
            GenJnlApply.CheckAgainstApplnCurrency(
              NewCVLedgEntryBuf."Currency Code",
              OldVendLedgEntry."Currency Code",
              GenJnlLine."Account Type"::Vendor,
              TRUE);
            TempOldVendLedgEntry := OldVendLedgEntry;
            TempOldVendLedgEntry.INSERT;
        END ELSE BEGIN
            // Find the first old entry (Invoice) which the new entry (Payment) should apply to
            OldVendLedgEntry.RESET;
            OldVendLedgEntry.SETCURRENTKEY("Vendor No.", "Applies-to ID", Open, Positive, "Due Date");
            TempOldVendLedgEntry.SETCURRENTKEY("Vendor No.", "Applies-to ID", Open, Positive, "Due Date");
            OldVendLedgEntry.SETRANGE("Vendor No.", NewCVLedgEntryBuf."CV No.");
            OldVendLedgEntry.SETRANGE("Applies-to ID", GenJnlLine."Applies-to ID");
            OldVendLedgEntry.SETRANGE(Open, TRUE);
            OldVendLedgEntry.SETFILTER("Entry No.", '<>%1', NewCVLedgEntryBuf."Entry No.");
            IF NOT (Vend."Application Method" = Vend."Application Method"::"Apply to Oldest") THEN
                OldVendLedgEntry.SETFILTER("Amount to Apply", '<>%1', 0);

            IF Vend."Application Method" = Vend."Application Method"::"Apply to Oldest" THEN
                OldVendLedgEntry.SETFILTER("Posting Date", '..%1', GenJnlLine."Posting Date");

            //Check and Move Ledger Entries to Temp
            IF PurchSetup."Appln. between Currencies" = PurchSetup."Appln. between Currencies"::None THEN
                OldVendLedgEntry.SETRANGE("Currency Code", NewCVLedgEntryBuf."Currency Code");
            IF OldVendLedgEntry.FINDSET(FALSE, FALSE) THEN
                REPEAT
                    IF GenJnlApply.CheckAgainstApplnCurrency(
                         NewCVLedgEntryBuf."Currency Code",
                         OldVendLedgEntry."Currency Code",
                         GenJnlLine."Account Type"::Vendor,
                         FALSE)
                    THEN BEGIN
                        IF (OldVendLedgEntry."Posting Date" > ApplyingDate) AND (OldVendLedgEntry."Applies-to ID" <> '') THEN
                            ApplyingDate := OldVendLedgEntry."Posting Date";
                        TempOldVendLedgEntry := OldVendLedgEntry;
                        TempOldVendLedgEntry.INSERT;
                    END;
                UNTIL OldVendLedgEntry.NEXT = 0;

            TempOldVendLedgEntry.SETRANGE(Positive, NewCVLedgEntryBuf."Remaining Amount" > 0);

            IF TempOldVendLedgEntry.FIND('-') THEN BEGIN
                TempAmount := NewCVLedgEntryBuf."Remaining Amount";
                TempOldVendLedgEntry.SETRANGE(Positive);
                TempOldVendLedgEntry.FIND('-');
                REPEAT
                    TempOldVendLedgEntry.CALCFIELDS("Remaining Amount");
                    IF NewCVLedgEntryBuf."Currency Code" <> TempOldVendLedgEntry."Currency Code" THEN BEGIN
                        TempOldVendLedgEntry."Remaining Amount" :=
                          ExchAmount(
                            TempOldVendLedgEntry."Remaining Amount", TempOldVendLedgEntry."Currency Code",
                            NewCVLedgEntryBuf."Currency Code", NewCVLedgEntryBuf."Posting Date");
                        TempOldVendLedgEntry."Remaining Pmt. Disc. Possible" :=
                          ExchAmount(
                            TempOldVendLedgEntry."Remaining Pmt. Disc. Possible", TempOldVendLedgEntry."Currency Code",
                            NewCVLedgEntryBuf."Currency Code", NewCVLedgEntryBuf."Posting Date");
                        TempOldVendLedgEntry."Accepted Payment Tolerance" :=
                          ExchAmount(
                            TempOldVendLedgEntry."Accepted Payment Tolerance", TempOldVendLedgEntry."Currency Code",
                            NewCVLedgEntryBuf."Currency Code", NewCVLedgEntryBuf."Posting Date");
                        TempOldVendLedgEntry."Amount to Apply" :=
                          ExchAmount(
                            TempOldVendLedgEntry."Amount to Apply", TempOldVendLedgEntry."Currency Code",
                            NewCVLedgEntryBuf."Currency Code", NewCVLedgEntryBuf."Posting Date");

                    END;
                    IF CheckCalcPmtDiscCVVend(NewCVLedgEntryBuf, TempOldVendLedgEntry, 0, FALSE, FALSE)
                    THEN
                        TempOldVendLedgEntry."Remaining Amount" :=
                          TempOldVendLedgEntry."Remaining Amount" - TempOldVendLedgEntry."Remaining Pmt. Disc. Possible";

                    TempAmount := TempAmount + TempOldVendLedgEntry."Remaining Amount";

                UNTIL TempOldVendLedgEntry.NEXT = 0;
                TempOldVendLedgEntry.SETRANGE(Positive, TempAmount < 0);
            END ELSE
                TempOldVendLedgEntry.SETRANGE(Positive);

            IF NOT TempOldVendLedgEntry.FIND('-') THEN
                EXIT;
        END;
        GenJnlLine."Posting Date" := ApplyingDate;
        // Apply the new entry (Payment) to the old entries (Invoices) one at a time
        REPEAT
            TempOldVendLedgEntry.CALCFIELDS(
              Amount, "Amount (LCY)", "Remaining Amount", "Remaining Amt. (LCY)",
              "Original Amount", "Original Amt. (LCY)");
            TransferVendLedgEntry(OldCVLedgEntryBuf, TempOldVendLedgEntry, TRUE);
            TempOldVendLedgEntry.COPYFILTER(Positive, OldCVLedgEntryBuf.Positive);

            OldRemainingAmtBeforeAppln := OldCVLedgEntryBuf."Remaining Amount";
            OldCVLedgEntryBuf3 := OldCVLedgEntryBuf;

            // Management of posting in multiple currencies
            OldCVLedgEntryBuf2 := OldCVLedgEntryBuf;
            OldCVLedgEntryBuf.COPYFILTER(Positive, OldCVLedgEntryBuf2.Positive);
            IF NewCVLedgEntryBuf."Currency Code" <> OldCVLedgEntryBuf2."Currency Code" THEN BEGIN
                OldCVLedgEntryBuf2."Remaining Amount" :=
                  ExchAmount(
                    OldCVLedgEntryBuf2."Remaining Amount", OldCVLedgEntryBuf2."Currency Code",
                    NewCVLedgEntryBuf."Currency Code", NewCVLedgEntryBuf."Posting Date");
                OldCVLedgEntryBuf2."Remaining Pmt. Disc. Possible" :=
                  ExchAmount(
                    OldCVLedgEntryBuf2."Remaining Pmt. Disc. Possible", OldCVLedgEntryBuf2."Currency Code",
                    NewCVLedgEntryBuf."Currency Code", NewCVLedgEntryBuf."Posting Date");
                OldCVLedgEntryBuf2."Accepted Payment Tolerance" :=
                  ExchAmount(
                    OldCVLedgEntryBuf2."Accepted Payment Tolerance", OldCVLedgEntryBuf2."Currency Code",
                    NewCVLedgEntryBuf."Currency Code", NewCVLedgEntryBuf."Posting Date");
                OldCVLedgEntryBuf2."Amount to Apply" :=
                  ExchAmount(
                    OldCVLedgEntryBuf2."Amount to Apply", OldCVLedgEntryBuf2."Currency Code",
                    NewCVLedgEntryBuf."Currency Code", NewCVLedgEntryBuf."Posting Date");
            END;

            CalcPmtTolerance(
              NewCVLedgEntryBuf, OldCVLedgEntryBuf, OldCVLedgEntryBuf2, DtldCVLedgEntryBuf, GenJnlLine,
              GLSetup, PmtTolAmtToBeApplied, NextTransactionNo, FirstNewVATEntryNo);

            CalcPmtDisc(
              NewCVLedgEntryBuf, OldCVLedgEntryBuf, OldCVLedgEntryBuf2, DtldCVLedgEntryBuf, GenJnlLine,
              GLSetup, PmtTolAmtToBeApplied, ApplnRoundingPrecision, NextTransactionNo, FirstNewVATEntryNo);

            CalcPmtDiscTolerance(
              NewCVLedgEntryBuf, OldCVLedgEntryBuf, OldCVLedgEntryBuf2, DtldCVLedgEntryBuf, GenJnlLine,
              GLSetup, NextTransactionNo, FirstNewVATEntryNo);

            CalcCurrencyApplnRounding(
              NewCVLedgEntryBuf, OldCVLedgEntryBuf2, DtldCVLedgEntryBuf,
              GenJnlLine, ApplnRoundingPrecision);

            FindAmtForAppln(
              NewCVLedgEntryBuf, OldCVLedgEntryBuf, OldCVLedgEntryBuf2,
              AppliedAmount, AppliedAmountLCY, OldAppliedAmount, ApplnRoundingPrecision);

            CalcCurrencyUnrealizedGainLoss(
              OldCVLedgEntryBuf, DtldCVLedgEntryBuf, GenJnlLine, -OldAppliedAmount, OldRemainingAmtBeforeAppln);

            CalcCurrencyRealizedGainLoss(
              NewCVLedgEntryBuf, DtldCVLedgEntryBuf, GenJnlLine, AppliedAmount, AppliedAmountLCY);

            CalcCurrencyRealizedGainLoss(
              OldCVLedgEntryBuf, DtldCVLedgEntryBuf, GenJnlLine, -OldAppliedAmount, -AppliedAmountLCY);

            CalcApplication(
              NewCVLedgEntryBuf, OldCVLedgEntryBuf, DtldCVLedgEntryBuf,
              GenJnlLine, AppliedAmount, AppliedAmountLCY, OldAppliedAmount,
              NewCVLedgEntryBuf2, OldCVLedgEntryBuf3);

            CalcRemainingPmtDisc(NewCVLedgEntryBuf, OldCVLedgEntryBuf, OldCVLedgEntryBuf2);

            CalcAmtLCYAdjustment(OldCVLedgEntryBuf, DtldCVLedgEntryBuf, GenJnlLine);

            // Update the Old Entry
            TransferVendLedgEntry(OldCVLedgEntryBuf, TempOldVendLedgEntry, FALSE);

            OldVendLedgEntry := TempOldVendLedgEntry;
            OldVendLedgEntry."Applies-to ID" := '';
            OldVendLedgEntry."Amount to Apply" := 0;
            OldVendLedgEntry.MODIFY;

            IF GLSetup."Unrealized VAT" OR
              (GLSetup."Prepayment Unrealized VAT" AND TempOldVendLedgEntry.Prepayment)
            THEN
                IF (TempOldVendLedgEntry."Document Type" IN
                     [TempOldVendLedgEntry."Document Type"::Invoice,
                      TempOldVendLedgEntry."Document Type"::"Credit Memo",
                      TempOldVendLedgEntry."Document Type"::"Finance Charge Memo",
                      TempOldVendLedgEntry."Document Type"::Reminder])
                THEN BEGIN
                    IF TempOldVendLedgEntry."Currency Code" <> NewCVLedgEntryBuf."Currency Code" THEN BEGIN
                        TempOldVendLedgEntry."Remaining Amount" :=
                          ExchAmount(
                            TempOldVendLedgEntry."Remaining Amount", NewCVLedgEntryBuf."Currency Code",
                            TempOldVendLedgEntry."Currency Code", NewCVLedgEntryBuf."Posting Date");
                        TempOldVendLedgEntry."Remaining Pmt. Disc. Possible" :=
                          ExchAmount(
                            TempOldVendLedgEntry."Remaining Pmt. Disc. Possible", NewCVLedgEntryBuf."Currency Code",
                            TempOldVendLedgEntry."Currency Code", NewCVLedgEntryBuf."Posting Date");
                        TempOldVendLedgEntry."Accepted Payment Tolerance" :=
                          ExchAmount(
                            TempOldVendLedgEntry."Accepted Payment Tolerance", NewCVLedgEntryBuf."Currency Code",
                            TempOldVendLedgEntry."Currency Code", NewCVLedgEntryBuf."Posting Date");
                        TempOldVendLedgEntry."Amount to Apply" :=
                          ExchAmount(
                            TempOldVendLedgEntry."Amount to Apply", NewCVLedgEntryBuf."Currency Code",
                            TempOldVendLedgEntry."Currency Code", NewCVLedgEntryBuf."Posting Date");

                    END;
                    VendUnrealizedVAT(
                      TempOldVendLedgEntry,
                      ExchAmount(
                        AppliedAmount, NewCVLedgEntryBuf."Currency Code",
                        TempOldVendLedgEntry."Currency Code", NewCVLedgEntryBuf."Posting Date"));
                END;

            TempOldVendLedgEntry.DELETE;

            // Find the next old entry to apply to the new entry
            IF GenJnlLine."Applies-to Doc. No." <> '' THEN
                Completed := TRUE
            ELSE
                IF TempOldVendLedgEntry.GETFILTER(TempOldVendLedgEntry.Positive) <> '' THEN BEGIN
                    IF TempOldVendLedgEntry.NEXT = 1 THEN
                        Completed := FALSE
                    ELSE BEGIN
                        TempOldVendLedgEntry.SETRANGE(Positive);
                        TempOldVendLedgEntry.FIND('-');
                        TempOldVendLedgEntry.CALCFIELDS("Remaining Amount");
                        Completed := TempOldVendLedgEntry."Remaining Amount" * NewCVLedgEntryBuf."Remaining Amount" >= 0;
                    END
                END ELSE BEGIN
                    IF NewCVLedgEntryBuf.Open THEN BEGIN
                        Completed := TempOldVendLedgEntry.NEXT = 0;
                    END ELSE
                        Completed := TRUE;
                END;
        UNTIL Completed;

        DtldCVLedgEntryBuf.SETCURRENTKEY("Cust. Ledger Entry No.", "Entry Type");
        DtldCVLedgEntryBuf.SETRANGE("Cust. Ledger Entry No.", NewCVLedgEntryBuf."Entry No.");
        DtldCVLedgEntryBuf.SETRANGE(
          "Entry Type",
          DtldCVLedgEntryBuf."Entry Type"::Application);
        DtldCVLedgEntryBuf.CALCSUMS("Amount (LCY)", Amount);

        CalcCurrencyUnrealizedGainLoss(
          NewCVLedgEntryBuf, DtldCVLedgEntryBuf, GenJnlLine, DtldCVLedgEntryBuf.Amount, NewRemainingAmtBeforeAppln);

        CalcAmtLCYAdjustment(NewCVLedgEntryBuf, DtldCVLedgEntryBuf, GenJnlLine);

        NewCVLedgEntryBuf."Applies-to ID" := '';
        NewCVLedgEntryBuf."Amount to Apply" := 0;

        IF GLSetup."Unrealized VAT" OR
          (GLSetup."Prepayment Unrealized VAT" AND NewCVLedgEntryBuf.Prepayment)
        THEN
            IF (NewCVLedgEntryBuf."Document Type" IN
                 [NewCVLedgEntryBuf."Document Type"::Invoice,
                  NewCVLedgEntryBuf."Document Type"::"Credit Memo",
                  NewCVLedgEntryBuf."Document Type"::"Finance Charge Memo",
                  NewCVLedgEntryBuf."Document Type"::Reminder]) AND
               (NewRemainingAmtBeforeAppln - NewCVLedgEntryBuf."Remaining Amount" <> 0)
            THEN BEGIN
                TransferVendLedgEntry(NewCVLedgEntryBuf, NewVendLedgEntry, FALSE);
                CheckUnrealizedVend := TRUE;
                UnrealizedVendLedgEntry := NewVendLedgEntry;
                UnrealizedRemainingAmountVend := -(NewRemainingAmtBeforeAppln - NewVendLedgEntry."Remaining Amount");
            END;
    end;

    procedure VendPostApplyVendLedgEntry(var GenJnlLinePostApply: Record "Gen. Journal Line"; var VendLedgEntryPostApply: Record "25")
    var
        LedgEntryDim: Record "355";
        VendLedgEntry: Record "25";
        DtldVendLedgEntry: Record "380";
        DtldCVLedgEntryBuf: Record "383" temporary;
        CVLedgEntryBuf: Record "382";
    begin
        GenJnlLine := GenJnlLinePostApply;
        GenJnlLine."Source Currency Code" := VendLedgEntryPostApply."Currency Code";
        GenJnlLine."Applies-to ID" := VendLedgEntryPostApply."Applies-to ID";
        VendLedgEntry.TRANSFERFIELDS(VendLedgEntryPostApply);
        WITH GenJnlLine DO BEGIN
            LedgEntryDim.SETRANGE("Table ID", DATABASE::"Vendor Ledger Entry");
            LedgEntryDim.SETRANGE("Entry No.", VendLedgEntry."Entry No.");
            TempJnlLineDim.RESET;
            TempJnlLineDim.DELETEALL;
            DimMgt.CopyLedgEntryDimToJnlLineDim(LedgEntryDim, TempJnlLineDim);

            GenJnlCheckLine.RunCheck(GenJnlLine, TempJnlLineDim);

            InitCodeUnit;

            IF Vend."No." <> VendLedgEntry."Vendor No." THEN
                Vend.GET(VendLedgEntry."Vendor No.");
            Vend.CheckBlockedVendOnJnls(Vend, "Document Type", TRUE);
            //T044145 -
            CompanyInformation.GET();
            IF CompanyInformation."Enable Vendor Approval Process" THEN
                Vend.CheckVendorStatus(Vend, TRUE);
            //T044145 +

            IF "Posting Group" = '' THEN BEGIN
                Vend.TESTFIELD("Vendor Posting Group");
                "Posting Group" := Vend."Vendor Posting Group";
            END;
            VendPostingGr.GET("Posting Group");
            VendPostingGr.TESTFIELD("Payables Account");

            DtldVendLedgEntry.LOCKTABLE;
            VendLedgEntry.LOCKTABLE;

            // Post the application
            VendLedgEntry.CALCFIELDS(
              Amount, "Amount (LCY)", "Remaining Amount", "Remaining Amt. (LCY)",
              "Original Amount", "Original Amt. (LCY)");
            TransferVendLedgEntry(CVLedgEntryBuf, VendLedgEntry, TRUE);
            ApplyVendLedgEntry(
              CVLedgEntryBuf, DtldCVLedgEntryBuf, GenJnlLine, GLSetup."Appln. Rounding Precision");
            TransferVendLedgEntry(CVLedgEntryBuf, VendLedgEntry, FALSE);
            VendLedgEntry.MODIFY;

            // Post Dtld vendor entry
            PostDtldVendLedgEntries(
              GenJnlLine, DtldCVLedgEntryBuf, VendPostingGr, NextTransactionNo, FALSE);
            FinishCodeunit;
        END;
    end;

    procedure UnapplyVendLedgEntry(GenJnlLine2: Record "Gen. Journal Line"; DtldVendLedgEntry: Record "380")
    var
        DtldVendLedgEntry2: Record "380";
        NewDtldVendLedgEntry: Record "380";
        VendLedgEntry: Record "25";
        DtldCVLedgEntryBuf: Record "383";
        VATEntry: Record "254";
        VATPostingSetup: Record "VAT Posting Setup";
        LedgEntryDim: Record "355";
        GenPostingSetup: Record "252";
        VATEntryTemp: Record "254" temporary;
        CurrencyLCY: Record "4";
        VATEntrySaved: Record "254";
        VatEntry2: Record "254";
        TotalAmountLCY: Decimal;
        TotalAmountAddCurr: Decimal;
        NextDtldLedgEntryEntryNo: Integer;
        UnapplyVATEntries: Boolean;
        DebitAddjustment: Decimal;
        DebitAddjustmentAddCurr: Decimal;
        CreditAddjustment: Decimal;
        CreditAddjustmentAddCurr: Decimal;
        PositiveLCYAppAmt: Decimal;
        NegativeLCYAppAmt: Decimal;
        PositiveACYAppAmt: Decimal;
        NegativeACYAppAmt: Decimal;
        VatBaseSum: array[2] of Decimal;
        EntryNoBegin: array[2] of Integer;
        i: Integer;
        TempVatEntryNo: Integer;
    begin
        PositiveLCYAppAmt := 0;
        PositiveACYAppAmt := 0;
        NegativeLCYAppAmt := 0;
        NegativeACYAppAmt := 0;
        GenJnlLine.TRANSFERFIELDS(GenJnlLine2);
        IF GenJnlLine."Document Date" = 0D THEN
            GenJnlLine."Document Date" := GenJnlLine."Posting Date";

        InitCodeUnit;

        IF Vend."No." <> DtldVendLedgEntry."Vendor No." THEN
            Vend.GET(DtldVendLedgEntry."Vendor No.");
        Vend.CheckBlockedVendOnJnls(Vend, 0, TRUE);
        //T044145 -
        CompanyInformation.GET();
        IF CompanyInformation."Enable Vendor Approval Process" THEN
            Vend.CheckVendorStatus(Vend, TRUE);
        //T044145 +

        VendPostingGr.GET(GenJnlLine."Posting Group");
        VendPostingGr.TESTFIELD("Payables Account");

        VATEntry.LOCKTABLE;
        DtldVendLedgEntry.LOCKTABLE;
        VendLedgEntry.LOCKTABLE;

        DtldVendLedgEntry.TESTFIELD("Entry Type", DtldVendLedgEntry."Entry Type"::Application);

        DtldVendLedgEntry2.RESET;
        DtldVendLedgEntry2.FINDLAST;
        NextDtldLedgEntryEntryNo := DtldVendLedgEntry2."Entry No." + 1;
        DtldVendLedgEntry2.SETCURRENTKEY("Transaction No.", "Vendor No.", "Entry Type");
        DtldVendLedgEntry2.SETRANGE("Transaction No.", DtldVendLedgEntry."Transaction No.");
        DtldVendLedgEntry2.SETRANGE("Vendor No.", DtldVendLedgEntry."Vendor No.");
        DtldVendLedgEntry2.SETFILTER("Entry Type", '>%1', DtldVendLedgEntry."Entry Type"::"Initial Entry");
        DtldVendLedgEntry2.FINDSET;
        UnapplyVATEntries := FALSE;
        REPEAT
            IF (DtldVendLedgEntry2."Entry Type" = DtldVendLedgEntry2."Entry Type"::"Payment Discount (VAT Adjustment)") OR
               (DtldVendLedgEntry2."Entry Type" = DtldVendLedgEntry2."Entry Type"::"Payment Tolerance (VAT Adjustment)") OR
               (DtldVendLedgEntry2."Entry Type" = DtldVendLedgEntry2."Entry Type"::"Payment Discount Tolerance (VAT Adjustment)")
            THEN
                UnapplyVATEntries := TRUE
        UNTIL DtldVendLedgEntry2.NEXT = 0;

        TempVatEntryNo := 1;
        VATEntry.SETCURRENTKEY(Type, "Bill-to/Pay-to No.", "Transaction No.");
        VATEntry.SETRANGE(Type, VATEntry.Type::Purchase);
        VATEntry.SETRANGE("Bill-to/Pay-to No.", DtldVendLedgEntry."Vendor No.");
        VATEntry.SETRANGE("Transaction No.", DtldVendLedgEntry."Transaction No.");
        IF VATEntry.FINDSET THEN BEGIN
            VATPostingSetup.GET(VATEntry."VAT Bus. Posting Group", VATEntry."VAT Prod. Posting Group");
            IF (VATPostingSetup."Adjust for Payment Discount") AND
               (VATPostingSetup."VAT Calculation Type" = VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT") AND
               (VATEntry."Document Type" <> VATEntry."Document Type"::"Credit Memo") AND
               (VATEntry."Document Type" <> VATEntry."Document Type"::Invoice)
            THEN
                UnapplyVATEntries := TRUE;
            REPEAT
                IF UnapplyVATEntries OR (VATEntry."Unrealized VAT Entry No." <> 0) THEN BEGIN
                    TempVatEntry := VATEntry;
                    TempVatEntry."Entry No." := TempVatEntryNo;
                    TempVatEntryNo := TempVatEntryNo + 1;
                    TempVatEntry."Closed by Entry No." := 0;
                    TempVatEntry.Closed := FALSE;
                    TempVatEntry.Base := -VATEntry.Base;
                    TempVatEntry.Amount := -VATEntry.Amount;
                    TempVatEntry."Unrealized Amount" := -VATEntry."Unrealized Amount";
                    TempVatEntry."Unrealized Base" := -VATEntry."Unrealized Base";
                    TempVatEntry."Remaining Unrealized Amount" := -VATEntry."Remaining Unrealized Amount";
                    TempVatEntry."Remaining Unrealized Base" := -VATEntry."Remaining Unrealized Base";
                    TempVatEntry."Additional-Currency Amount" := -VATEntry."Additional-Currency Amount";
                    TempVatEntry."Additional-Currency Base" := -VATEntry."Additional-Currency Base";
                    TempVatEntry."Add.-Currency Unrealized Amt." := -VATEntry."Add.-Currency Unrealized Amt.";
                    TempVatEntry."Add.-Currency Unrealized Base" := -VATEntry."Add.-Currency Unrealized Base";
                    TempVatEntry."Add.-Curr. Rem. Unreal. Amount" := -VATEntry."Add.-Curr. Rem. Unreal. Amount";
                    TempVatEntry."Add.-Curr. Rem. Unreal. Base" := -VATEntry."Add.-Curr. Rem. Unreal. Base";
                    TempVatEntry."Posting Date" := GenJnlLine2."Posting Date";
                    TempVatEntry."Document No." := GenJnlLine2."Document No.";
                    TempVatEntry."User ID" := USERID;
                    TempVatEntry."Transaction No." := NextTransactionNo;
                    TempVatEntry.INSERT;
                    IF VATEntry."Unrealized VAT Entry No." <> 0 THEN BEGIN
                        VATPostingSetup.GET(VATEntry."VAT Bus. Posting Group", VATEntry."VAT Prod. Posting Group");
                        IF VATPostingSetup."VAT Calculation Type" IN
                           [VATPostingSetup."VAT Calculation Type"::"Normal VAT",
                            VATPostingSetup."VAT Calculation Type"::"Full VAT"]
                        THEN BEGIN
                            VATPostingSetup.TESTFIELD("Purch. VAT Unreal. Account");
                            VATPostingSetup.TESTFIELD("Purchase VAT Account");
                            PostUnrealVATByUnapply(
                              VATPostingSetup."Purch. VAT Unreal. Account",
                              VATPostingSetup."Purchase VAT Account",
                              VATEntry, TempVatEntry);
                        END ELSE
                            IF VATPostingSetup."VAT Calculation Type" = VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT" THEN BEGIN
                                VATPostingSetup.TESTFIELD("Purch. VAT Unreal. Account");
                                VATPostingSetup.TESTFIELD("Purchase VAT Account");
                                PostUnrealVATByUnapply(
                                  VATPostingSetup."Purch. VAT Unreal. Account",
                                  VATPostingSetup."Purchase VAT Account",
                                  VATEntry, TempVatEntry);

                                VATPostingSetup.TESTFIELD("Reverse Chrg. VAT Acc.");
                                VATPostingSetup.TESTFIELD("Reverse Chrg. VAT Unreal. Acc.");

                                InitGLEntry(VATPostingSetup."Reverse Chrg. VAT Unreal. Acc.", -VATEntry.Amount, 0, FALSE, TRUE);
                                GLEntry."Additional-Currency Amount" :=
                                  CalcAddCurrForUnapplication(VATEntry."Posting Date", -VATEntry.Amount);
                                InsertGLEntry(TRUE);

                                InitGLEntry(VATPostingSetup."Reverse Chrg. VAT Acc.", VATEntry.Amount, 0, FALSE, TRUE);
                                GLEntry."Additional-Currency Amount" :=
                                  CalcAddCurrForUnapplication(VATEntry."Posting Date", VATEntry.Amount);
                                InsertGLEntry(TRUE)
                            END ELSE BEGIN
                                VATEntry.TESTFIELD("Tax Jurisdiction Code");
                                TaxJurisdiction.GET(VATEntry."Tax Jurisdiction Code");
                                TaxJurisdiction.TESTFIELD("Unreal. Tax Acc. (Purchases)");
                                TaxJurisdiction.TESTFIELD("Tax Account (Purchases)");
                                PostUnrealVATByUnapply(
                                  TaxJurisdiction."Unreal. Tax Acc. (Purchases)",
                                  TaxJurisdiction."Tax Account (Purchases)",
                                  VATEntry, TempVatEntry);
                            END;
                        VatEntry2 := TempVatEntry;
                        VatEntry2."Entry No." := NextVATEntryNo;
                        NextVATEntryNo := NextVATEntryNo + 1;
                        VatEntry2.INSERT;
                        TempVatEntry.DELETE;
                    END;
                    IF (VATPostingSetup."Adjust for Payment Discount") AND
                       (VATPostingSetup."VAT Calculation Type" =
                         VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT") AND
                       (VATEntry."Unrealized VAT Entry No." = 0) AND
                       (VATEntry."Document Type" <> VATEntry."Document Type"::"Credit Memo") AND
                       (VATEntry."Document Type" <> VATEntry."Document Type"::Invoice)
                    THEN BEGIN
                        VATPostingSetup.TESTFIELD("Purchase VAT Account");
                        GenPostingSetup.GET(VATEntry."Gen. Bus. Posting Group", VATEntry."Gen. Prod. Posting Group");
                        PostPmtDiscountVATByUnapply(
                          VATPostingSetup."Reverse Chrg. VAT Acc.",
                          VATPostingSetup."Purchase VAT Account",
                          VATEntry);
                    END;
                END;
            UNTIL VATEntry.NEXT = 0;
        END;

        DtldVendLedgEntry2.FINDSET;
        REPEAT
            IF (DtldVendLedgEntry2."Entry Type" IN
                [DtldVendLedgEntry2."Entry Type"::"Payment Discount (VAT Excl.)",
                 DtldVendLedgEntry2."Entry Type"::"Payment Tolerance (VAT Excl.)",
                 DtldVendLedgEntry2."Entry Type"::"Payment Discount Tolerance (VAT Excl.)"])
            THEN BEGIN
                TempVatEntry.RESET;
                TempVatEntry.SETRANGE("Entry No.", 0, 999999);
                TempVatEntry.SETRANGE("Gen. Bus. Posting Group", DtldVendLedgEntry2."Gen. Bus. Posting Group");
                TempVatEntry.SETRANGE("Gen. Prod. Posting Group", DtldVendLedgEntry2."Gen. Prod. Posting Group");
                TempVatEntry.SETRANGE("VAT Bus. Posting Group", DtldVendLedgEntry2."VAT Bus. Posting Group");
                TempVatEntry.SETRANGE("VAT Prod. Posting Group", DtldVendLedgEntry2."VAT Prod. Posting Group");
                IF TempVatEntry.FINDSET THEN BEGIN
                    REPEAT
                        CASE TRUE OF
                            VatBaseSum[2] + TempVatEntry.Base = DtldVendLedgEntry2."Amount (LCY)":
                                i := 3;
                            VatBaseSum[1] + TempVatEntry.Base = DtldVendLedgEntry2."Amount (LCY)":
                                i := 2;
                            TempVatEntry.Base = DtldVendLedgEntry2."Amount (LCY)":
                                i := 1;
                            ELSE
                                i := 0;
                        END;
                        IF i > 0 THEN BEGIN
                            TempVatEntry.RESET;
                            IF i > 1 THEN
                                TempVatEntry.SETRANGE("Entry No.", EntryNoBegin[i - 1], TempVatEntry."Entry No.")
                            ELSE
                                TempVatEntry.SETRANGE("Entry No.", TempVatEntry."Entry No.");
                            TempVatEntry.FINDSET;
                            REPEAT
                                VATEntrySaved := TempVatEntry;
                                CASE DtldVendLedgEntry2."Entry Type" OF
                                    DtldVendLedgEntry2."Entry Type"::"Payment Tolerance (VAT Excl.)":
                                        TempVatEntry.RENAME(TempVatEntry."Entry No." + 2000000);
                                    DtldVendLedgEntry2."Entry Type"::"Payment Discount Tolerance (VAT Excl.)":
                                        TempVatEntry.RENAME(TempVatEntry."Entry No." + 1000000);
                                END;
                                TempVatEntry := VATEntrySaved;
                            UNTIL TempVatEntry.NEXT = 0;
                            FOR i := 1 TO 2 DO BEGIN
                                VatBaseSum[i] := 0;
                                EntryNoBegin[i] := 0;
                            END;
                            TempVatEntry.SETRANGE("Entry No.", 0, 999999);
                        END ELSE BEGIN
                            VatBaseSum[2] := VatBaseSum[1] + TempVatEntry.Base;
                            VatBaseSum[1] := TempVatEntry.Base;
                            EntryNoBegin[2] := EntryNoBegin[1];
                            EntryNoBegin[1] := TempVatEntry."Entry No.";
                        END;
                    UNTIL TempVatEntry.NEXT = 0;
                END;
            END;
        UNTIL DtldVendLedgEntry2.NEXT = 0;

        DtldVendLedgEntry2.FINDSET;
        LedgEntryDim.SETRANGE("Table ID", DATABASE::"Vendor Ledger Entry");
        LedgEntryDim.SETRANGE("Entry No.", DtldVendLedgEntry2."Applied Vend. Ledger Entry No.");
        TempJnlLineDim.RESET;
        TempJnlLineDim.DELETEALL;
        DimMgt.CopyLedgEntryDimToJnlLineDim(LedgEntryDim, TempJnlLineDim);
        IF TempJnlLineDim.GET(DATABASE::"Vendor Ledger Entry", '', '', 0, 0, GLSetup."Global Dimension 1 Code") THEN
            GenJnlLine."Shortcut Dimension 1 Code" := TempJnlLineDim."Dimension Value Code"
        ELSE
            GenJnlLine."Shortcut Dimension 1 Code" := '';
        IF TempJnlLineDim.GET(DATABASE::"Vendor Ledger Entry", '', '', 0, 0, GLSetup."Global Dimension 2 Code") THEN
            GenJnlLine."Shortcut Dimension 2 Code" := TempJnlLineDim."Dimension Value Code"
        ELSE
            GenJnlLine."Shortcut Dimension 2 Code" := '';

        REPEAT
            DtldVendLedgEntry2.TESTFIELD(Unapplied, FALSE);

            NewDtldVendLedgEntry := DtldVendLedgEntry2;
            NewDtldVendLedgEntry."Entry No." := NextDtldLedgEntryEntryNo;
            NewDtldVendLedgEntry."Posting Date" := GenJnlLine."Posting Date";
            NewDtldVendLedgEntry."Transaction No." := NextTransactionNo;
            NewDtldVendLedgEntry.Amount := -DtldVendLedgEntry2.Amount;
            NewDtldVendLedgEntry."Amount (LCY)" := -DtldVendLedgEntry2."Amount (LCY)";
            NewDtldVendLedgEntry."Debit Amount" := -DtldVendLedgEntry2."Debit Amount";
            NewDtldVendLedgEntry."Credit Amount" := -DtldVendLedgEntry2."Credit Amount";
            NewDtldVendLedgEntry."Debit Amount (LCY)" := -DtldVendLedgEntry2."Debit Amount (LCY)";
            NewDtldVendLedgEntry."Credit Amount (LCY)" := -DtldVendLedgEntry2."Credit Amount (LCY)";
            NewDtldVendLedgEntry.Unapplied := TRUE;
            NewDtldVendLedgEntry."Unapplied by Entry No." := DtldVendLedgEntry2."Entry No.";
            NewDtldVendLedgEntry."Document No." := GenJnlLine."Document No.";
            NewDtldVendLedgEntry."Source Code" := GenJnlLine."Source Code";
            NewDtldVendLedgEntry."User ID" := USERID;
            NewDtldVendLedgEntry.INSERT;
            NextDtldLedgEntryEntryNo := NextDtldLedgEntryEntryNo + 1;

            DtldCVLedgEntryBuf.TRANSFERFIELDS(NewDtldVendLedgEntry);
            GenJnlLine."Source Currency Code" := DtldVendLedgEntry2."Currency Code";
            IF GLSetup."Additional Reporting Currency" <> DtldCVLedgEntryBuf."Currency Code" THEN
                DtldCVLedgEntryBuf."Additional-Currency Amount" :=
                  CalcAddCurrForUnapplication(DtldCVLedgEntryBuf."Posting Date", DtldCVLedgEntryBuf."Amount (LCY)")
            ELSE
                IF GLSetup."Additional Reporting Currency" <> '' THEN
                    DtldCVLedgEntryBuf."Additional-Currency Amount" := DtldCVLedgEntryBuf.Amount;
            CurrencyLCY.InitRoundingPrecision;

            IF DtldVendLedgEntry2."Entry Type" IN [
              DtldVendLedgEntry2."Entry Type"::"Payment Discount (VAT Excl.)",
              DtldVendLedgEntry2."Entry Type"::"Payment Tolerance (VAT Excl.)",
              DtldVendLedgEntry2."Entry Type"::"Payment Discount Tolerance (VAT Excl.)"]
            THEN BEGIN
                VATEntryTemp.SETRANGE("VAT Bus. Posting Group", DtldVendLedgEntry2."VAT Bus. Posting Group");
                VATEntryTemp.SETRANGE("VAT Prod. Posting Group", DtldVendLedgEntry2."VAT Prod. Posting Group");
                IF NOT VATEntryTemp.FINDFIRST THEN BEGIN
                    VATEntryTemp.RESET;
                    IF VATEntryTemp.FINDLAST THEN
                        VATEntryTemp."Entry No." := VATEntryTemp."Entry No." + 1
                    ELSE
                        VATEntryTemp."Entry No." := 1;
                    VATEntryTemp.INIT;
                    VATEntryTemp."VAT Bus. Posting Group" := DtldVendLedgEntry2."VAT Bus. Posting Group";
                    VATEntryTemp."VAT Prod. Posting Group" := DtldVendLedgEntry2."VAT Prod. Posting Group";

                    VATEntry.SETRANGE("Transaction No.", DtldVendLedgEntry2."Transaction No.");
                    VATEntry.SETRANGE("VAT Bus. Posting Group", DtldVendLedgEntry2."VAT Bus. Posting Group");
                    VATEntry.SETRANGE("VAT Prod. Posting Group", DtldVendLedgEntry2."VAT Prod. Posting Group");
                    IF VATEntry.FINDSET THEN
                        REPEAT
                            IF VATEntry."Unrealized VAT Entry No." = 0 THEN BEGIN
                                VATEntryTemp.Base := VATEntryTemp.Base + VATEntry.Base;
                                VATEntryTemp.Amount := VATEntryTemp.Amount + VATEntry.Amount;
                            END;
                        UNTIL VATEntry.NEXT = 0;
                    CLEAR(VATEntry);
                    VATEntryTemp.INSERT;
                END;
                IF DtldCVLedgEntryBuf."Amount (LCY)" = VATEntryTemp.Base THEN BEGIN
                    DtldCVLedgEntryBuf."VAT Amount (LCY)" := VATEntryTemp.Amount;
                    VATEntryTemp.DELETE;
                END ELSE BEGIN
                    DtldCVLedgEntryBuf."VAT Amount (LCY)" := ROUND(
                      VATEntryTemp.Amount * DtldCVLedgEntryBuf."Amount (LCY)" / VATEntryTemp.Base,
                      CurrencyLCY."Amount Rounding Precision",
                      CurrencyLCY.VATRoundingDirection);
                    VATEntryTemp.Base := VATEntryTemp.Base - DtldCVLedgEntryBuf."Amount (LCY)";
                    VATEntryTemp.Amount := VATEntryTemp.Amount - DtldCVLedgEntryBuf."VAT Amount (LCY)";
                    VATEntryTemp.MODIFY;
                END;
            END;
            TotalAmountLCY := TotalAmountLCY + DtldCVLedgEntryBuf."Amount (LCY)";
            TotalAmountAddCurr := TotalAmountAddCurr + DtldCVLedgEntryBuf."Additional-Currency Amount";
            IF DtldCVLedgEntryBuf."Entry Type" = DtldCVLedgEntryBuf."Entry Type"::Application THEN BEGIN
                IF DtldCVLedgEntryBuf."Amount (LCY)" >= 0 THEN BEGIN
                    PositiveLCYAppAmt := PositiveLCYAppAmt + DtldCVLedgEntryBuf."Amount (LCY)";
                    PositiveACYAppAmt :=
                      PositiveACYAppAmt + DtldCVLedgEntryBuf."Additional-Currency Amount";
                END ELSE BEGIN
                    NegativeLCYAppAmt := NegativeLCYAppAmt + DtldCVLedgEntryBuf."Amount (LCY)";
                    NegativeACYAppAmt :=
                      NegativeACYAppAmt + DtldCVLedgEntryBuf."Additional-Currency Amount";
                END;
            END;

            IF NOT (DtldCVLedgEntryBuf."Entry Type" IN [
              DtldCVLedgEntryBuf."Entry Type"::"Initial Entry",
              DtldCVLedgEntryBuf."Entry Type"::Application]) THEN
                CollectAddjustment(DebitAddjustment, DebitAddjustmentAddCurr,
                  CreditAddjustment, CreditAddjustmentAddCurr,
                  -DtldCVLedgEntryBuf."Amount (LCY)", -DtldCVLedgEntryBuf."Additional-Currency Amount");
            AutoEntrForDtldVendLedgEntries(DtldCVLedgEntryBuf, DtldVendLedgEntry2."Transaction No.");

            DtldVendLedgEntry2.Unapplied := TRUE;
            DtldVendLedgEntry2."Unapplied by Entry No." := NewDtldVendLedgEntry."Entry No.";
            DtldVendLedgEntry2.MODIFY;

            IF DtldVendLedgEntry2."Entry Type" = DtldVendLedgEntry2."Entry Type"::Application THEN BEGIN
                VendLedgEntry.GET(DtldVendLedgEntry2."Vendor Ledger Entry No.");
                VendLedgEntry."Remaining Pmt. Disc. Possible" := DtldVendLedgEntry2."Remaining Pmt. Disc. Possible";
                VendLedgEntry."Max. Payment Tolerance" := DtldVendLedgEntry2."Max. Payment Tolerance";
                VendLedgEntry."Accepted Payment Tolerance" := 0;
                IF NOT VendLedgEntry.Open THEN BEGIN
                    VendLedgEntry.Open := TRUE;
                    VendLedgEntry."Closed by Entry No." := 0;
                    VendLedgEntry."Closed at Date" := 0D;
                    VendLedgEntry."Closed by Amount" := 0;
                    VendLedgEntry."Closed by Amount (LCY)" := 0;
                    VendLedgEntry."Closed by Currency Code" := '';
                    VendLedgEntry."Closed by Currency Amount" := 0;
                    VendLedgEntry."Pmt. Disc. Rcd.(LCY)" := 0;
                    VendLedgEntry."Pmt. Tolerance (LCY)" := 0;
                END;
                VendLedgEntry.MODIFY;
            END;
        UNTIL DtldVendLedgEntry2.NEXT = 0;

        IF (TotalAmountLCY <> 0) OR
           (TotalAmountAddCurr <> 0) AND (GLSetup."Additional Reporting Currency" <> '')
        THEN BEGIN
            HandlDtlAddjustment(DebitAddjustment, DebitAddjustmentAddCurr, CreditAddjustment, CreditAddjustmentAddCurr,
              TotalAmountLCY, TotalAmountAddCurr, VendPostingGr."Payables Account");
            InsertGLEntry(TRUE);
        END;

        IF NOT GLEntryTmp.FINDFIRST THEN BEGIN
            InitGLEntry(VendPostingGr."Payables Account", PositiveLCYAppAmt, PositiveACYAppAmt, FALSE, TRUE);
            InsertGLEntry(FALSE);
            InitGLEntry(VendPostingGr."Payables Account", NegativeLCYAppAmt, NegativeACYAppAmt, FALSE, TRUE);
            InsertGLEntry(FALSE);
        END;

        FinishCodeunit;
    end;

    procedure TransferVendLedgEntry(var CVLedgEntryBuf: Record "382"; var VendLedgEntry: Record "25"; VendToCV: Boolean)
    begin
        IF VendToCV THEN BEGIN
            CVLedgEntryBuf."Entry No." := VendLedgEntry."Entry No.";
            CVLedgEntryBuf."CV No." := VendLedgEntry."Vendor No.";
            CVLedgEntryBuf."Posting Date" := VendLedgEntry."Posting Date";
            CVLedgEntryBuf."Document Type" := VendLedgEntry."Document Type";
            CVLedgEntryBuf."Document No." := VendLedgEntry."Document No.";
            CVLedgEntryBuf.Description := VendLedgEntry.Description;
            CVLedgEntryBuf."Currency Code" := VendLedgEntry."Currency Code";
            CVLedgEntryBuf.Amount := VendLedgEntry.Amount;
            CVLedgEntryBuf."Remaining Amount" := VendLedgEntry."Remaining Amount";
            CVLedgEntryBuf."Original Amount" := VendLedgEntry."Original Amount";
            CVLedgEntryBuf."Original Amt. (LCY)" := VendLedgEntry."Original Amt. (LCY)";
            CVLedgEntryBuf."Remaining Amt. (LCY)" := VendLedgEntry."Remaining Amt. (LCY)";
            CVLedgEntryBuf."Amount (LCY)" := VendLedgEntry."Amount (LCY)";
            CVLedgEntryBuf."Sales/Purchase (LCY)" := VendLedgEntry."Purchase (LCY)";
            CVLedgEntryBuf."Inv. Discount (LCY)" := VendLedgEntry."Inv. Discount (LCY)";
            CVLedgEntryBuf."Bill-to/Pay-to CV No." := VendLedgEntry."Buy-from Vendor No.";
            CVLedgEntryBuf."CV Posting Group" := VendLedgEntry."Vendor Posting Group";
            CVLedgEntryBuf."Global Dimension 1 Code" := VendLedgEntry."Global Dimension 1 Code";
            CVLedgEntryBuf."Global Dimension 2 Code" := VendLedgEntry."Global Dimension 2 Code";
            CVLedgEntryBuf."Salesperson Code" := VendLedgEntry."Purchaser Code";
            CVLedgEntryBuf."User ID" := VendLedgEntry."User ID";
            CVLedgEntryBuf."Source Code" := VendLedgEntry."Source Code";
            CVLedgEntryBuf."On Hold" := VendLedgEntry."On Hold";
            CVLedgEntryBuf."Applies-to Doc. Type" := VendLedgEntry."Applies-to Doc. Type";
            CVLedgEntryBuf."Applies-to Doc. No." := VendLedgEntry."Applies-to Doc. No.";
            CVLedgEntryBuf.Open := VendLedgEntry.Open;
            CVLedgEntryBuf."Due Date" := VendLedgEntry."Due Date";
            CVLedgEntryBuf."Pmt. Discount Date" := VendLedgEntry."Pmt. Discount Date";
            CVLedgEntryBuf."Original Pmt. Disc. Possible" := VendLedgEntry."Original Pmt. Disc. Possible";
            CVLedgEntryBuf."Remaining Pmt. Disc. Possible" := VendLedgEntry."Remaining Pmt. Disc. Possible";
            CVLedgEntryBuf."Pmt. Disc. Given (LCY)" := VendLedgEntry."Pmt. Disc. Rcd.(LCY)";
            CVLedgEntryBuf.Positive := VendLedgEntry.Positive;
            CVLedgEntryBuf."Closed by Entry No." := VendLedgEntry."Closed by Entry No.";
            CVLedgEntryBuf."Closed at Date" := VendLedgEntry."Closed at Date";
            CVLedgEntryBuf."Closed by Amount" := VendLedgEntry."Closed by Amount";
            CVLedgEntryBuf."Applies-to ID" := VendLedgEntry."Applies-to ID";
            CVLedgEntryBuf."Journal Batch Name" := VendLedgEntry."Journal Batch Name";
            CVLedgEntryBuf."Reason Code" := VendLedgEntry."Reason Code";
            CVLedgEntryBuf."Bal. Account Type" := VendLedgEntry."Bal. Account Type";
            CVLedgEntryBuf."Bal. Account No." := VendLedgEntry."Bal. Account No.";
            CVLedgEntryBuf."Transaction No." := VendLedgEntry."Transaction No.";
            CVLedgEntryBuf."Closed by Amount (LCY)" := VendLedgEntry."Closed by Amount (LCY)";
            CVLedgEntryBuf."Debit Amount" := VendLedgEntry."Debit Amount";
            CVLedgEntryBuf."Credit Amount" := VendLedgEntry."Credit Amount";
            CVLedgEntryBuf."Debit Amount (LCY)" := VendLedgEntry."Debit Amount (LCY)";
            CVLedgEntryBuf."Credit Amount (LCY)" := VendLedgEntry."Credit Amount (LCY)";
            CVLedgEntryBuf."Document Date" := VendLedgEntry."Document Date";
            CVLedgEntryBuf."External Document No." := VendLedgEntry."External Document No.";
            CVLedgEntryBuf."No. Series" := VendLedgEntry."No. Series";
            CVLedgEntryBuf."Closed by Currency Code" := VendLedgEntry."Closed by Currency Code";
            CVLedgEntryBuf."Closed by Currency Amount" := VendLedgEntry."Closed by Currency Amount";
            CVLedgEntryBuf."Adjusted Currency Factor" := VendLedgEntry."Adjusted Currency Factor";
            CVLedgEntryBuf."Original Currency Factor" := VendLedgEntry."Original Currency Factor";
            CVLedgEntryBuf."Pmt. Disc. Tolerance Date" := VendLedgEntry."Pmt. Disc. Tolerance Date";
            CVLedgEntryBuf."Max. Payment Tolerance" := VendLedgEntry."Max. Payment Tolerance";
            CVLedgEntryBuf."Accepted Payment Tolerance" := VendLedgEntry."Accepted Payment Tolerance";
            CVLedgEntryBuf."Accepted Pmt. Disc. Tolerance" := VendLedgEntry."Accepted Pmt. Disc. Tolerance";
            CVLedgEntryBuf."Amount to Apply" := VendLedgEntry."Amount to Apply";
            CVLedgEntryBuf.Prepayment := VendLedgEntry.Prepayment;
        END ELSE BEGIN
            VendLedgEntry."Entry No." := CVLedgEntryBuf."Entry No.";
            VendLedgEntry."Vendor No." := CVLedgEntryBuf."CV No.";
            VendLedgEntry."Posting Date" := CVLedgEntryBuf."Posting Date";
            VendLedgEntry."Document Type" := CVLedgEntryBuf."Document Type";
            VendLedgEntry."Document No." := CVLedgEntryBuf."Document No.";
            VendLedgEntry.Description := CVLedgEntryBuf.Description;
            VendLedgEntry."Currency Code" := CVLedgEntryBuf."Currency Code";
            VendLedgEntry.Amount := CVLedgEntryBuf.Amount;
            VendLedgEntry."Remaining Amount" := CVLedgEntryBuf."Remaining Amount";
            VendLedgEntry."Original Amount" := CVLedgEntryBuf."Original Amount";
            VendLedgEntry."Original Amt. (LCY)" := CVLedgEntryBuf."Original Amt. (LCY)";
            VendLedgEntry."Remaining Amt. (LCY)" := CVLedgEntryBuf."Remaining Amt. (LCY)";
            VendLedgEntry."Amount (LCY)" := CVLedgEntryBuf."Amount (LCY)";
            VendLedgEntry."Purchase (LCY)" := CVLedgEntryBuf."Sales/Purchase (LCY)";
            VendLedgEntry."Inv. Discount (LCY)" := CVLedgEntryBuf."Inv. Discount (LCY)";
            VendLedgEntry."Buy-from Vendor No." := CVLedgEntryBuf."Bill-to/Pay-to CV No.";
            VendLedgEntry."Vendor Posting Group" := CVLedgEntryBuf."CV Posting Group";
            VendLedgEntry."Global Dimension 1 Code" := CVLedgEntryBuf."Global Dimension 1 Code";
            VendLedgEntry."Global Dimension 2 Code" := CVLedgEntryBuf."Global Dimension 2 Code";
            VendLedgEntry."Purchaser Code" := CVLedgEntryBuf."Salesperson Code";
            VendLedgEntry."User ID" := CVLedgEntryBuf."User ID";
            VendLedgEntry."Source Code" := CVLedgEntryBuf."Source Code";
            VendLedgEntry."On Hold" := CVLedgEntryBuf."On Hold";
            VendLedgEntry."Applies-to Doc. Type" := CVLedgEntryBuf."Applies-to Doc. Type";
            VendLedgEntry."Applies-to Doc. No." := CVLedgEntryBuf."Applies-to Doc. No.";
            VendLedgEntry.Open := CVLedgEntryBuf.Open;
            VendLedgEntry."Due Date" := CVLedgEntryBuf."Due Date";
            VendLedgEntry."Pmt. Discount Date" := CVLedgEntryBuf."Pmt. Discount Date";
            VendLedgEntry."Original Pmt. Disc. Possible" := CVLedgEntryBuf."Original Pmt. Disc. Possible";
            VendLedgEntry."Remaining Pmt. Disc. Possible" := CVLedgEntryBuf."Remaining Pmt. Disc. Possible";
            VendLedgEntry."Pmt. Disc. Rcd.(LCY)" := CVLedgEntryBuf."Pmt. Disc. Given (LCY)";
            VendLedgEntry.Positive := CVLedgEntryBuf.Positive;
            VendLedgEntry."Closed by Entry No." := CVLedgEntryBuf."Closed by Entry No.";
            VendLedgEntry."Closed at Date" := CVLedgEntryBuf."Closed at Date";
            VendLedgEntry."Closed by Amount" := CVLedgEntryBuf."Closed by Amount";
            VendLedgEntry."Applies-to ID" := CVLedgEntryBuf."Applies-to ID";
            VendLedgEntry."Journal Batch Name" := CVLedgEntryBuf."Journal Batch Name";
            VendLedgEntry."Reason Code" := CVLedgEntryBuf."Reason Code";
            VendLedgEntry."Bal. Account Type" := CVLedgEntryBuf."Bal. Account Type";
            VendLedgEntry."Bal. Account No." := CVLedgEntryBuf."Bal. Account No.";
            VendLedgEntry."Transaction No." := CVLedgEntryBuf."Transaction No.";
            VendLedgEntry."Closed by Amount (LCY)" := CVLedgEntryBuf."Closed by Amount (LCY)";
            VendLedgEntry."Debit Amount" := CVLedgEntryBuf."Debit Amount";
            VendLedgEntry."Credit Amount" := CVLedgEntryBuf."Credit Amount";
            VendLedgEntry."Debit Amount (LCY)" := CVLedgEntryBuf."Debit Amount (LCY)";
            VendLedgEntry."Credit Amount (LCY)" := CVLedgEntryBuf."Credit Amount (LCY)";
            VendLedgEntry."Document Date" := CVLedgEntryBuf."Document Date";
            VendLedgEntry."External Document No." := CVLedgEntryBuf."External Document No.";
            VendLedgEntry."No. Series" := CVLedgEntryBuf."No. Series";
            VendLedgEntry."Closed by Currency Code" := CVLedgEntryBuf."Closed by Currency Code";
            VendLedgEntry."Closed by Currency Amount" := CVLedgEntryBuf."Closed by Currency Amount";
            VendLedgEntry."Adjusted Currency Factor" := CVLedgEntryBuf."Adjusted Currency Factor";
            VendLedgEntry."Original Currency Factor" := CVLedgEntryBuf."Original Currency Factor";
            VendLedgEntry."Pmt. Disc. Tolerance Date" := CVLedgEntryBuf."Pmt. Disc. Tolerance Date";
            VendLedgEntry."Max. Payment Tolerance" := CVLedgEntryBuf."Max. Payment Tolerance";
            VendLedgEntry."Accepted Payment Tolerance" := CVLedgEntryBuf."Accepted Payment Tolerance";
            VendLedgEntry."Accepted Pmt. Disc. Tolerance" := CVLedgEntryBuf."Accepted Pmt. Disc. Tolerance";
            VendLedgEntry."Pmt. Tolerance (LCY)" := CVLedgEntryBuf."Pmt. Tolerance (LCY)";
            VendLedgEntry."Amount to Apply" := CVLedgEntryBuf."Amount to Apply";
            VendLedgEntry.Prepayment := CVLedgEntryBuf.Prepayment;
        END;
    end;

    procedure PostDtldVendLedgEntries(GenJnlLine2: Record "Gen. Journal Line"; var DtldCVLedgEntryBuf: Record "383"; VendPostingGr: Record "93"; NextTransactionNo: Integer; VendLedgEntryInserted: Boolean)
    var
        DtldVendLedgEntry: Record "380";
        Currency: Record "4";
        GenPostingSetup: Record "252";
        TotalAmountLCY: Decimal;
        TotalAmountAddCurr: Decimal;
        PaymentDiscAcc: Code[20];
        DtldVendLedgEntryNoOffset: Integer;
        PaymentTolAcc: Code[20];
        SaveEntryNo: Integer;
        DebitAddjustment: Decimal;
        DebitAddjustmentAddCurr: Decimal;
        CreditAddjustment: Decimal;
        CreditAddjustmentAddCurr: Decimal;
        PositiveLCYAppAmt: Decimal;
        NegativeLCYAppAmt: Decimal;
        PositiveACYAppAmt: Decimal;
        NegativeACYAppAmt: Decimal;
        OriginalPostingDate: Date;
        OriginalDateSet: Boolean;
        TotalAmountLCYApplDate: Decimal;
        TotalAmountAddCurrApplDate: Decimal;
        ApplicationDate: Date;
        DebitAddjustmentApplDate: Decimal;
        DebitAddjustmentAddCurrApplDat: Decimal;
        CreditAddjustmentApplDate: Decimal;
        CreditAddjustmentAddCurrApplDa: Decimal;
        SavedEntryUsed: Boolean;
    begin
        TotalAmountLCY := 0;
        TotalAmountAddCurr := 0;
        PositiveLCYAppAmt := 0;
        PositiveACYAppAmt := 0;
        NegativeLCYAppAmt := 0;
        NegativeACYAppAmt := 0;

        IF GenJnlLine2."Account Type" = GenJnlLine2."Account Type"::Vendor THEN BEGIN
            IF DtldVendLedgEntry.FINDLAST THEN
                DtldVendLedgEntryNoOffset := DtldVendLedgEntry."Entry No."
            ELSE
                //LS -
                DtldVendLedgEntryNoOffset := InitEntryNoInStore.GetCurrLocInitEntryNo(DATABASE::"Detailed Vendor Ledg. Entry") - 1;
            //DtldVendLedgEntryNoOffset := 0;
            //LS +
            DtldCVLedgEntryBuf.RESET;
            IF DtldCVLedgEntryBuf.FINDSET THEN BEGIN
                IF VendLedgEntryInserted THEN BEGIN
                    SaveEntryNo := NextEntryNo;
                    NextEntryNo := NextEntryNo + 1;
                END;
                REPEAT
                    IF DtldCVLedgEntryBuf."Posting Date" <> GenJnlLine."Posting Date" THEN BEGIN
                        OriginalPostingDate := GenJnlLine."Posting Date";
                        GenJnlLine."Posting Date" := DtldCVLedgEntryBuf."Posting Date";
                        OriginalDateSet := TRUE;
                        ApplicationDate := DtldCVLedgEntryBuf."Posting Date";
                    END;
                    CLEAR(DtldVendLedgEntry);
                    DtldVendLedgEntry.TRANSFERFIELDS(DtldCVLedgEntryBuf);
                    DtldVendLedgEntry."Entry No." :=
                      DtldVendLedgEntryNoOffset + DtldCVLedgEntryBuf."Entry No.";
                    DtldVendLedgEntry."Journal Batch Name" := GenJnlLine2."Journal Batch Name";
                    DtldVendLedgEntry."Reason Code" := GenJnlLine2."Reason Code";
                    DtldVendLedgEntry."Source Code" := GenJnlLine2."Source Code";
                    DtldVendLedgEntry."Transaction No." := NextTransactionNo;
                    VendUpdateDebitCredit(GenJnlLine2.Correction, DtldVendLedgEntry);
                    DtldVendLedgEntry.INSERT;

                    IF OriginalDateSet THEN BEGIN
                        TotalAmountLCYApplDate := TotalAmountLCYApplDate + DtldCVLedgEntryBuf."Amount (LCY)";
                        TotalAmountAddCurrApplDate := TotalAmountAddCurrApplDate + DtldCVLedgEntryBuf."Additional-Currency Amount";
                    END ELSE BEGIN
                        TotalAmountLCY := TotalAmountLCY + DtldCVLedgEntryBuf."Amount (LCY)";
                        TotalAmountAddCurr := TotalAmountAddCurr + DtldCVLedgEntryBuf."Additional-Currency Amount";
                    END;

                    // Post automatic entries.
                    IF (DtldCVLedgEntryBuf."Amount (LCY)" <> 0) OR
                       ((GLSetup."Additional Reporting Currency" <> '') AND
                        (DtldCVLedgEntryBuf."Additional-Currency Amount" <> 0))
                    THEN
                        CASE DtldCVLedgEntryBuf."Entry Type" OF
                            DtldCVLedgEntryBuf."Entry Type"::"Initial Entry":
                                ;
                            DtldCVLedgEntryBuf."Entry Type"::Application:
                                BEGIN
                                    IF DtldCVLedgEntryBuf."Amount (LCY)" >= 0 THEN BEGIN
                                        PositiveLCYAppAmt := PositiveLCYAppAmt + DtldCVLedgEntryBuf."Amount (LCY)";
                                        PositiveACYAppAmt :=
                                          PositiveACYAppAmt + DtldCVLedgEntryBuf."Additional-Currency Amount";
                                    END ELSE BEGIN
                                        NegativeLCYAppAmt := NegativeLCYAppAmt + DtldCVLedgEntryBuf."Amount (LCY)";
                                        NegativeACYAppAmt :=
                                          NegativeACYAppAmt + DtldCVLedgEntryBuf."Additional-Currency Amount";
                                    END;
                                END;
                            DtldCVLedgEntryBuf."Entry Type"::"Unrealized Loss":
                                BEGIN
                                    IF Currency.Code <> DtldCVLedgEntryBuf."Currency Code" THEN BEGIN
                                        IF DtldCVLedgEntryBuf."Currency Code" = '' THEN
                                            CLEAR(Currency)
                                        ELSE
                                            Currency.GET(DtldCVLedgEntryBuf."Currency Code");
                                    END;
                                    CheckNonAddCurrCodeOccurred(Currency.Code);
                                    Currency.TESTFIELD("Unrealized Losses Acc.");
                                    InitGLEntry(
                                      Currency."Unrealized Losses Acc.", -DtldCVLedgEntryBuf."Amount (LCY)",
                                      0, DtldCVLedgEntryBuf."Currency Code" = GLSetup."Additional Reporting Currency",
                                      TRUE);

                                    IF OriginalDateSet THEN
                                        CollectAddjustment(DebitAddjustmentApplDate, DebitAddjustmentAddCurrApplDat,
                                          CreditAddjustmentApplDate, CreditAddjustmentAddCurrApplDa,
                                          GLEntry.Amount, GLEntry."Additional-Currency Amount")
                                    ELSE
                                        CollectAddjustment(DebitAddjustment, DebitAddjustmentAddCurr,
                                          CreditAddjustment, CreditAddjustmentAddCurr,
                                          GLEntry.Amount, GLEntry."Additional-Currency Amount");
                                    InsertGLEntry(TRUE);
                                END;
                            DtldCVLedgEntryBuf."Entry Type"::"Unrealized Gain":
                                BEGIN
                                    IF Currency.Code <> DtldCVLedgEntryBuf."Currency Code" THEN BEGIN
                                        IF DtldCVLedgEntryBuf."Currency Code" = '' THEN
                                            CLEAR(Currency)
                                        ELSE
                                            Currency.GET(DtldCVLedgEntryBuf."Currency Code");
                                    END;
                                    CheckNonAddCurrCodeOccurred(Currency.Code);
                                    Currency.TESTFIELD("Unrealized Gains Acc.");
                                    InitGLEntry(
                                      Currency."Unrealized Gains Acc.", -DtldCVLedgEntryBuf."Amount (LCY)",
                                      0, DtldCVLedgEntryBuf."Currency Code" = GLSetup."Additional Reporting Currency",
                                      TRUE);

                                    IF OriginalDateSet THEN
                                        CollectAddjustment(DebitAddjustmentApplDate, DebitAddjustmentAddCurrApplDat,
                                          CreditAddjustmentApplDate, CreditAddjustmentAddCurrApplDa,
                                          GLEntry.Amount, GLEntry."Additional-Currency Amount")
                                    ELSE
                                        CollectAddjustment(DebitAddjustment, DebitAddjustmentAddCurr,
                                          CreditAddjustment, CreditAddjustmentAddCurr,
                                          GLEntry.Amount, GLEntry."Additional-Currency Amount");
                                    InsertGLEntry(TRUE);
                                END;
                            DtldCVLedgEntryBuf."Entry Type"::"Realized Loss":
                                BEGIN
                                    IF Currency.Code <> DtldCVLedgEntryBuf."Currency Code" THEN BEGIN
                                        IF DtldCVLedgEntryBuf."Currency Code" = '' THEN
                                            CLEAR(Currency)
                                        ELSE
                                            Currency.GET(DtldCVLedgEntryBuf."Currency Code");
                                    END;
                                    CheckNonAddCurrCodeOccurred(Currency.Code);
                                    Currency.TESTFIELD("Realized Losses Acc.");
                                    InitGLEntry(
                                      Currency."Realized Losses Acc.", -DtldCVLedgEntryBuf."Amount (LCY)",
                                      0, DtldCVLedgEntryBuf."Currency Code" = GLSetup."Additional Reporting Currency",
                                      TRUE);

                                    IF OriginalDateSet THEN
                                        CollectAddjustment(DebitAddjustmentApplDate, DebitAddjustmentAddCurrApplDat,
                                          CreditAddjustmentApplDate, CreditAddjustmentAddCurrApplDa,
                                          GLEntry.Amount, GLEntry."Additional-Currency Amount")
                                    ELSE
                                        CollectAddjustment(DebitAddjustment, DebitAddjustmentAddCurr,
                                          CreditAddjustment, CreditAddjustmentAddCurr,
                                          GLEntry.Amount, GLEntry."Additional-Currency Amount");
                                    InsertGLEntry(TRUE);
                                END;
                            DtldCVLedgEntryBuf."Entry Type"::"Realized Gain":
                                BEGIN
                                    IF Currency.Code <> DtldCVLedgEntryBuf."Currency Code" THEN BEGIN
                                        IF DtldCVLedgEntryBuf."Currency Code" = '' THEN
                                            CLEAR(Currency)
                                        ELSE
                                            Currency.GET(DtldCVLedgEntryBuf."Currency Code");
                                    END;
                                    CheckNonAddCurrCodeOccurred(Currency.Code);
                                    Currency.TESTFIELD("Realized Gains Acc.");
                                    InitGLEntry(
                                      Currency."Realized Gains Acc.", -DtldCVLedgEntryBuf."Amount (LCY)",
                                      0, DtldCVLedgEntryBuf."Currency Code" = GLSetup."Additional Reporting Currency",
                                      TRUE);

                                    IF OriginalDateSet THEN
                                        CollectAddjustment(DebitAddjustmentApplDate, DebitAddjustmentAddCurrApplDat,
                                          CreditAddjustmentApplDate, CreditAddjustmentAddCurrApplDa,
                                          GLEntry.Amount, GLEntry."Additional-Currency Amount")
                                    ELSE
                                        CollectAddjustment(DebitAddjustment, DebitAddjustmentAddCurr,
                                          CreditAddjustment, CreditAddjustmentAddCurr,
                                          GLEntry.Amount, GLEntry."Additional-Currency Amount");
                                    InsertGLEntry(TRUE);
                                END;
                            DtldCVLedgEntryBuf."Entry Type"::"Payment Discount":
                                BEGIN
                                    IF (DtldCVLedgEntryBuf."Amount (LCY)" <= 0) THEN BEGIN
                                        VendPostingGr.TESTFIELD("Payment Disc. Debit Acc.");
                                        PaymentDiscAcc := VendPostingGr."Payment Disc. Debit Acc.";
                                    END ELSE BEGIN
                                        VendPostingGr.TESTFIELD("Payment Disc. Credit Acc.");
                                        PaymentDiscAcc := VendPostingGr."Payment Disc. Credit Acc.";
                                    END;
                                    InitGLEntry(
                                      PaymentDiscAcc, -DtldCVLedgEntryBuf."Amount (LCY)",
                                      0, FALSE, TRUE);
                                    GLEntry."Additional-Currency Amount" :=
                                      -DtldCVLedgEntryBuf."Additional-Currency Amount";
                                    InsertGLEntry(TRUE);
                                END;
                            DtldCVLedgEntryBuf."Entry Type"::"Payment Discount (VAT Excl.)":
                                BEGIN
                                    GenPostingSetup.GET(
                                      DtldCVLedgEntryBuf."Gen. Bus. Posting Group",
                                      DtldCVLedgEntryBuf."Gen. Prod. Posting Group");
                                    IF (DtldCVLedgEntryBuf."Amount (LCY)" <= 0) THEN BEGIN
                                        GenPostingSetup.TESTFIELD("Purch. Pmt. Disc. Debit Acc.");
                                        PaymentDiscAcc := GenPostingSetup."Purch. Pmt. Disc. Debit Acc.";
                                    END ELSE BEGIN
                                        GenPostingSetup.TESTFIELD("Purch. Pmt. Disc. Credit Acc.");
                                        PaymentDiscAcc := GenPostingSetup."Purch. Pmt. Disc. Credit Acc.";
                                    END;
                                    InitGLEntry(PaymentDiscAcc, -DtldCVLedgEntryBuf."Amount (LCY)", 0, FALSE, TRUE);
                                    GLEntry."Additional-Currency Amount" := -DtldCVLedgEntryBuf."Additional-Currency Amount";
                                    GLEntry."VAT Amount" := -DtldCVLedgEntryBuf."VAT Amount (LCY)";
                                    GLEntry."Gen. Posting Type" := DtldCVLedgEntryBuf."Gen. Posting Type";
                                    GLEntry."Gen. Bus. Posting Group" := DtldCVLedgEntryBuf."Gen. Bus. Posting Group";
                                    GLEntry."Gen. Prod. Posting Group" := DtldCVLedgEntryBuf."Gen. Prod. Posting Group";
                                    GLEntry."VAT Bus. Posting Group" := DtldCVLedgEntryBuf."VAT Bus. Posting Group";
                                    GLEntry."VAT Prod. Posting Group" := DtldCVLedgEntryBuf."VAT Prod. Posting Group";
                                    GLEntry."Tax Area Code" := DtldCVLedgEntryBuf."Tax Area Code";
                                    GLEntry."Tax Liable" := DtldCVLedgEntryBuf."Tax Liable";
                                    GLEntry."Tax Group Code" := DtldCVLedgEntryBuf."Tax Group Code";
                                    GLEntry."Use Tax" := DtldCVLedgEntryBuf."Use Tax";

                                    IF OriginalDateSet THEN
                                        CollectAddjustment(DebitAddjustmentApplDate, DebitAddjustmentAddCurrApplDat,
                                          CreditAddjustmentApplDate, CreditAddjustmentAddCurrApplDa,
                                          GLEntry.Amount, GLEntry."Additional-Currency Amount")
                                    ELSE
                                        CollectAddjustment(DebitAddjustment, DebitAddjustmentAddCurr,
                                          CreditAddjustment, CreditAddjustmentAddCurr,
                                          GLEntry.Amount, GLEntry."Additional-Currency Amount");
                                    InsertGLEntry(TRUE);

                                    InsertVatEntriesFromTemp(DtldCVLedgEntryBuf);
                                END;
                            DtldCVLedgEntryBuf."Entry Type"::"Payment Discount (VAT Adjustment)":
                                BEGIN
                                    // The g/l entries for this entry type are posted by the VAT functions.
                                END;
                            DtldCVLedgEntryBuf."Entry Type"::"Appln. Rounding":
                                BEGIN
                                    IF -DtldCVLedgEntryBuf."Amount (LCY)" > 0 THEN BEGIN
                                        VendPostingGr.TESTFIELD("Debit Curr. Appln. Rndg. Acc.");
                                        InitGLEntry(
                                          VendPostingGr."Debit Curr. Appln. Rndg. Acc.",
                                          -DtldCVLedgEntryBuf."Amount (LCY)",
                                          -DtldCVLedgEntryBuf."Additional-Currency Amount",
                                          TRUE, TRUE);
                                        InsertGLEntry(TRUE);
                                    END;
                                    IF -DtldCVLedgEntryBuf."Amount (LCY)" < 0 THEN BEGIN
                                        VendPostingGr.TESTFIELD("Credit Curr. Appln. Rndg. Acc.");
                                        InitGLEntry(
                                          VendPostingGr."Credit Curr. Appln. Rndg. Acc.",
                                          -DtldCVLedgEntryBuf."Amount (LCY)",
                                          -DtldCVLedgEntryBuf."Additional-Currency Amount",
                                          TRUE, TRUE);
                                        InsertGLEntry(TRUE);
                                    END;
                                END;
                            DtldCVLedgEntryBuf."Entry Type"::"Correction of Remaining Amount":
                                BEGIN
                                    IF -DtldCVLedgEntryBuf."Amount (LCY)" > 0 THEN BEGIN
                                        VendPostingGr.TESTFIELD("Debit Rounding Account");
                                        InitGLEntry(
                                          VendPostingGr."Debit Rounding Account", -DtldCVLedgEntryBuf."Amount (LCY)",
                                          0, FALSE, TRUE);
                                        GLEntry."Additional-Currency Amount" := 0;

                                        IF OriginalDateSet THEN
                                            CollectAddjustment(DebitAddjustmentApplDate, DebitAddjustmentAddCurrApplDat,
                                              CreditAddjustmentApplDate, CreditAddjustmentAddCurrApplDa,
                                              GLEntry.Amount, GLEntry."Additional-Currency Amount")
                                        ELSE
                                            CollectAddjustment(DebitAddjustment, DebitAddjustmentAddCurr,
                                              CreditAddjustment, CreditAddjustmentAddCurr,
                                              GLEntry.Amount, GLEntry."Additional-Currency Amount");
                                        InsertGLEntry(TRUE);
                                    END;
                                    IF -DtldCVLedgEntryBuf."Amount (LCY)" < 0 THEN BEGIN
                                        VendPostingGr.TESTFIELD("Credit Rounding Account");
                                        InitGLEntry(
                                          VendPostingGr."Credit Rounding Account", -DtldCVLedgEntryBuf."Amount (LCY)",
                                          0, FALSE, TRUE);
                                        GLEntry."Additional-Currency Amount" := 0;

                                        IF OriginalDateSet THEN
                                            CollectAddjustment(DebitAddjustmentApplDate, DebitAddjustmentAddCurrApplDat,
                                              CreditAddjustmentApplDate, CreditAddjustmentAddCurrApplDa,
                                              GLEntry.Amount, GLEntry."Additional-Currency Amount")
                                        ELSE
                                            CollectAddjustment(DebitAddjustment, DebitAddjustmentAddCurr,
                                              CreditAddjustment, CreditAddjustmentAddCurr,
                                              GLEntry.Amount, GLEntry."Additional-Currency Amount");
                                        InsertGLEntry(TRUE);
                                    END;
                                END;
                            DtldCVLedgEntryBuf."Entry Type"::"Payment Discount Tolerance":
                                BEGIN
                                    IF GLSetup."Pmt. Disc. Tolerance Posting" =
                                      GLSetup."Pmt. Disc. Tolerance Posting"::"Payment Tolerance Accounts"
                                    THEN BEGIN
                                        IF (DtldCVLedgEntryBuf."Amount (LCY)" >= 0) THEN BEGIN
                                            VendPostingGr.TESTFIELD("Payment Tolerance Debit Acc.");
                                            PaymentTolAcc := VendPostingGr."Payment Tolerance Debit Acc.";
                                        END ELSE BEGIN
                                            VendPostingGr.TESTFIELD("Payment Tolerance Credit Acc.");
                                            PaymentTolAcc := VendPostingGr."Payment Tolerance Credit Acc.";
                                        END;
                                    END ELSE
                                        IF GLSetup."Pmt. Disc. Tolerance Posting" =
                                 GLSetup."Pmt. Disc. Tolerance Posting"::"Payment Discount Accounts"
                               THEN BEGIN
                                            IF (DtldCVLedgEntryBuf."Amount (LCY)" >= 0) THEN BEGIN
                                                VendPostingGr.TESTFIELD("Payment Disc. Debit Acc.");
                                                PaymentTolAcc := VendPostingGr."Payment Disc. Debit Acc.";
                                            END ELSE BEGIN
                                                VendPostingGr.TESTFIELD("Payment Disc. Credit Acc.");
                                                PaymentTolAcc := VendPostingGr."Payment Disc. Credit Acc.";
                                            END;
                                        END;
                                    InitGLEntry(
                                      PaymentTolAcc, -DtldCVLedgEntryBuf."Amount (LCY)",
                                      0, FALSE, TRUE);
                                    GLEntry."Additional-Currency Amount" :=
                                      -DtldCVLedgEntryBuf."Additional-Currency Amount";

                                    IF OriginalDateSet THEN
                                        CollectAddjustment(DebitAddjustmentApplDate, DebitAddjustmentAddCurrApplDat,
                                          CreditAddjustmentApplDate, CreditAddjustmentAddCurrApplDa,
                                          GLEntry.Amount, GLEntry."Additional-Currency Amount")
                                    ELSE
                                        CollectAddjustment(DebitAddjustment, DebitAddjustmentAddCurr,
                                          CreditAddjustment, CreditAddjustmentAddCurr,
                                          GLEntry.Amount, GLEntry."Additional-Currency Amount");
                                    InsertGLEntry(TRUE);
                                END;
                            DtldCVLedgEntryBuf."Entry Type"::"Payment Tolerance":
                                BEGIN
                                    IF GLSetup."Payment Tolerance Posting" =
                                      GLSetup."Payment Tolerance Posting"::"Payment Tolerance Accounts"
                                    THEN BEGIN
                                        IF (DtldCVLedgEntryBuf."Amount (LCY)" >= 0) THEN BEGIN
                                            VendPostingGr.TESTFIELD("Payment Tolerance Debit Acc.");
                                            PaymentTolAcc := VendPostingGr."Payment Tolerance Debit Acc.";
                                        END ELSE BEGIN
                                            VendPostingGr.TESTFIELD("Payment Tolerance Credit Acc.");
                                            PaymentTolAcc := VendPostingGr."Payment Tolerance Credit Acc.";
                                        END;
                                    END ELSE
                                        IF GLSetup."Payment Tolerance Posting" =
                                 GLSetup."Payment Tolerance Posting"::"Payment Discount Accounts"
                               THEN BEGIN
                                            IF (DtldCVLedgEntryBuf."Amount (LCY)" >= 0) THEN BEGIN
                                                VendPostingGr.TESTFIELD("Payment Disc. Debit Acc.");
                                                PaymentTolAcc := VendPostingGr."Payment Disc. Debit Acc.";
                                            END ELSE BEGIN
                                                VendPostingGr.TESTFIELD("Payment Disc. Credit Acc.");
                                                PaymentTolAcc := VendPostingGr."Payment Disc. Credit Acc.";
                                            END;
                                        END;
                                    InitGLEntry(
                                      PaymentTolAcc, -DtldCVLedgEntryBuf."Amount (LCY)",
                                      0, FALSE, TRUE);
                                    GLEntry."Additional-Currency Amount" :=
                                      -DtldCVLedgEntryBuf."Additional-Currency Amount";

                                    IF OriginalDateSet THEN
                                        CollectAddjustment(DebitAddjustmentApplDate, DebitAddjustmentAddCurrApplDat,
                                          CreditAddjustmentApplDate, CreditAddjustmentAddCurrApplDa,
                                          GLEntry.Amount, GLEntry."Additional-Currency Amount")
                                    ELSE
                                        CollectAddjustment(DebitAddjustment, DebitAddjustmentAddCurr,
                                          CreditAddjustment, CreditAddjustmentAddCurr,
                                          GLEntry.Amount, GLEntry."Additional-Currency Amount");
                                    InsertGLEntry(TRUE);
                                END;
                            DtldCVLedgEntryBuf."Entry Type"::"Payment Tolerance (VAT Excl.)":
                                BEGIN
                                    GenPostingSetup.GET(
                                      DtldCVLedgEntryBuf."Gen. Bus. Posting Group",
                                      DtldCVLedgEntryBuf."Gen. Prod. Posting Group");
                                    IF GLSetup."Payment Tolerance Posting" =
                                      GLSetup."Payment Tolerance Posting"::"Payment Tolerance Accounts"
                                    THEN BEGIN
                                        IF (DtldCVLedgEntryBuf."Amount (LCY)" <= 0) THEN BEGIN
                                            GenPostingSetup.TESTFIELD("Purch. Pmt. Tol. Debit Acc.");
                                            PaymentTolAcc := GenPostingSetup."Purch. Pmt. Tol. Debit Acc.";
                                        END ELSE BEGIN
                                            GenPostingSetup.TESTFIELD("Purch. Pmt. Tol. Credit Acc.");
                                            PaymentTolAcc := GenPostingSetup."Purch. Pmt. Tol. Credit Acc.";
                                        END;
                                    END ELSE
                                        IF GLSetup."Payment Tolerance Posting" =
                                 GLSetup."Payment Tolerance Posting"::"Payment Discount Accounts"
                               THEN BEGIN
                                            IF (DtldCVLedgEntryBuf."Amount (LCY)" <= 0) THEN BEGIN
                                                GenPostingSetup.TESTFIELD("Purch. Pmt. Disc. Debit Acc.");
                                                PaymentTolAcc := GenPostingSetup."Purch. Pmt. Disc. Debit Acc.";
                                            END ELSE BEGIN
                                                GenPostingSetup.TESTFIELD("Purch. Pmt. Disc. Credit Acc.");
                                                PaymentTolAcc := GenPostingSetup."Purch. Pmt. Disc. Credit Acc.";
                                            END;
                                        END;
                                    InitGLEntry(PaymentTolAcc, -DtldCVLedgEntryBuf."Amount (LCY)", 0, FALSE, TRUE);
                                    GLEntry."Additional-Currency Amount" := -DtldCVLedgEntryBuf."Additional-Currency Amount";
                                    GLEntry."VAT Amount" := -DtldCVLedgEntryBuf."VAT Amount (LCY)";
                                    GLEntry."Gen. Posting Type" := DtldCVLedgEntryBuf."Gen. Posting Type";
                                    GLEntry."Gen. Bus. Posting Group" := DtldCVLedgEntryBuf."Gen. Bus. Posting Group";
                                    GLEntry."Gen. Prod. Posting Group" := DtldCVLedgEntryBuf."Gen. Prod. Posting Group";
                                    GLEntry."VAT Bus. Posting Group" := DtldCVLedgEntryBuf."VAT Bus. Posting Group";
                                    GLEntry."VAT Prod. Posting Group" := DtldCVLedgEntryBuf."VAT Prod. Posting Group";
                                    GLEntry."Tax Area Code" := DtldCVLedgEntryBuf."Tax Area Code";
                                    GLEntry."Tax Liable" := DtldCVLedgEntryBuf."Tax Liable";
                                    GLEntry."Tax Group Code" := DtldCVLedgEntryBuf."Tax Group Code";
                                    GLEntry."Use Tax" := DtldCVLedgEntryBuf."Use Tax";

                                    IF OriginalDateSet THEN
                                        CollectAddjustment(DebitAddjustmentApplDate, DebitAddjustmentAddCurrApplDat,
                                          CreditAddjustmentApplDate, CreditAddjustmentAddCurrApplDa,
                                          GLEntry.Amount, GLEntry."Additional-Currency Amount")
                                    ELSE
                                        CollectAddjustment(DebitAddjustment, DebitAddjustmentAddCurr,
                                          CreditAddjustment, CreditAddjustmentAddCurr,
                                          GLEntry.Amount, GLEntry."Additional-Currency Amount");
                                    InsertGLEntry(TRUE);

                                    InsertVatEntriesFromTemp(DtldCVLedgEntryBuf);
                                END;
                            DtldCVLedgEntryBuf."Entry Type"::"Payment Discount Tolerance (VAT Excl.)":
                                BEGIN
                                    GenPostingSetup.GET(
                                      DtldCVLedgEntryBuf."Gen. Bus. Posting Group",
                                      DtldCVLedgEntryBuf."Gen. Prod. Posting Group");
                                    IF GLSetup."Pmt. Disc. Tolerance Posting" =
                                      GLSetup."Pmt. Disc. Tolerance Posting"::"Payment Tolerance Accounts"
                                    THEN BEGIN
                                        IF (DtldCVLedgEntryBuf."Amount (LCY)" <= 0) THEN BEGIN
                                            GenPostingSetup.TESTFIELD("Purch. Pmt. Tol. Debit Acc.");
                                            PaymentTolAcc := GenPostingSetup."Purch. Pmt. Tol. Debit Acc.";
                                        END ELSE BEGIN
                                            GenPostingSetup.TESTFIELD("Purch. Pmt. Tol. Credit Acc.");
                                            PaymentTolAcc := GenPostingSetup."Purch. Pmt. Tol. Credit Acc.";
                                        END;
                                    END ELSE
                                        IF GLSetup."Pmt. Disc. Tolerance Posting" =
                                 GLSetup."Pmt. Disc. Tolerance Posting"::"Payment Discount Accounts"
                               THEN BEGIN
                                            IF (DtldCVLedgEntryBuf."Amount (LCY)" <= 0) THEN BEGIN
                                                GenPostingSetup.TESTFIELD("Purch. Pmt. Disc. Debit Acc.");
                                                PaymentTolAcc := GenPostingSetup."Purch. Pmt. Disc. Debit Acc.";
                                            END ELSE BEGIN
                                                GenPostingSetup.TESTFIELD("Purch. Pmt. Disc. Credit Acc.");
                                                PaymentTolAcc := GenPostingSetup."Purch. Pmt. Disc. Credit Acc.";
                                            END;
                                        END;
                                    InitGLEntry(PaymentTolAcc, -DtldCVLedgEntryBuf."Amount (LCY)", 0, FALSE, TRUE);
                                    GLEntry."Additional-Currency Amount" := -DtldCVLedgEntryBuf."Additional-Currency Amount";
                                    GLEntry."VAT Amount" := -DtldCVLedgEntryBuf."VAT Amount (LCY)";
                                    GLEntry."Gen. Posting Type" := DtldCVLedgEntryBuf."Gen. Posting Type";
                                    GLEntry."Gen. Bus. Posting Group" := DtldCVLedgEntryBuf."Gen. Bus. Posting Group";
                                    GLEntry."Gen. Prod. Posting Group" := DtldCVLedgEntryBuf."Gen. Prod. Posting Group";
                                    GLEntry."VAT Bus. Posting Group" := DtldCVLedgEntryBuf."VAT Bus. Posting Group";
                                    GLEntry."VAT Prod. Posting Group" := DtldCVLedgEntryBuf."VAT Prod. Posting Group";
                                    GLEntry."Tax Area Code" := DtldCVLedgEntryBuf."Tax Area Code";
                                    GLEntry."Tax Liable" := DtldCVLedgEntryBuf."Tax Liable";
                                    GLEntry."Tax Group Code" := DtldCVLedgEntryBuf."Tax Group Code";
                                    GLEntry."Use Tax" := DtldCVLedgEntryBuf."Use Tax";

                                    IF OriginalDateSet THEN
                                        CollectAddjustment(DebitAddjustmentApplDate, DebitAddjustmentAddCurrApplDat,
                                          CreditAddjustmentApplDate, CreditAddjustmentAddCurrApplDa,
                                          GLEntry.Amount, GLEntry."Additional-Currency Amount")
                                    ELSE
                                        CollectAddjustment(DebitAddjustment, DebitAddjustmentAddCurr,
                                          CreditAddjustment, CreditAddjustmentAddCurr,
                                          GLEntry.Amount, GLEntry."Additional-Currency Amount");
                                    InsertGLEntry(TRUE);

                                    InsertVatEntriesFromTemp(DtldCVLedgEntryBuf);
                                END;
                            DtldCVLedgEntryBuf."Entry Type"::"Payment Tolerance (VAT Adjustment)",
                            DtldCVLedgEntryBuf."Entry Type"::"Payment Discount Tolerance (VAT Adjustment)":
                                BEGIN
                                    // The g/l entries for this entry type are posted by the VAT functions.
                                END;
                            ELSE
                                DtldCVLedgEntryBuf.FIELDERROR("Entry Type");
                        END;
                    //APNT-IBU1.0
                    IF DtldCVLedgEntryBuf."IBU Entry" = TRUE THEN BEGIN
                        DtldVendLedgEntryNoOffset += 1;
                        DtldVendLedgEntry.INIT;
                        DtldVendLedgEntry.TRANSFERFIELDS(DtldCVLedgEntryBuf);
                        DtldVendLedgEntry."Entry No." := DtldVendLedgEntryNoOffset + DtldCVLedgEntryBuf."Entry No.";
                        DtldVendLedgEntry."Entry Type" := DtldVendLedgEntry."Entry Type"::Application;
                        DtldVendLedgEntry."Journal Batch Name" := GenJnlLine."Journal Batch Name";
                        DtldVendLedgEntry."Reason Code" := GenJnlLine."Reason Code";
                        DtldVendLedgEntry."Source Code" := GenJnlLine."Source Code";
                        DtldVendLedgEntry."Transaction No." := NextTransactionNo;
                        DtldVendLedgEntry.Amount := -DtldCVLedgEntryBuf.Amount;
                        DtldVendLedgEntry."Amount (LCY)" := -DtldCVLedgEntryBuf."Amount (LCY)";
                        DtldVendLedgEntry."Debit Amount" := DtldCVLedgEntryBuf."Credit Amount";
                        DtldVendLedgEntry."Credit Amount" := DtldCVLedgEntryBuf."Debit Amount";
                        DtldVendLedgEntry."Debit Amount (LCY)" := DtldCVLedgEntryBuf."Credit Amount (LCY)";
                        DtldVendLedgEntry."Credit Amount (LCY)" := DtldCVLedgEntryBuf."Debit Amount (LCY)";
                        VendUpdateDebitCredit(GenJnlLine.Correction, DtldVendLedgEntry);
                        IF DtldVendLedgEntry.Amount <> 0 THEN //APNT-RBT1.0
                            DtldVendLedgEntry.INSERT;
                        VendLedgEntryRec2.GET(DtldCVLedgEntryBuf."Cust. Ledger Entry No.");
                        VendLedgEntryRec2.Open := FALSE;
                        VendLedgEntryRec2.MODIFY;
                    END;
                    //APNT-IBU1.0
                    IF OriginalDateSet THEN BEGIN
                        GenJnlLine."Posting Date" := OriginalPostingDate;
                        OriginalDateSet := FALSE;
                    END;
                UNTIL DtldCVLedgEntryBuf.NEXT = 0;
            END;

            IF VendLedgEntryInserted OR (TotalAmountLCY <> 0) OR
               (TotalAmountAddCurr <> 0) AND (GLSetup."Additional Reporting Currency" <> '')
            THEN BEGIN
                HandlDtlAddjustment(DebitAddjustment, DebitAddjustmentAddCurr, CreditAddjustment, CreditAddjustmentAddCurr,
                  TotalAmountLCY, TotalAmountAddCurr, VendPostingGr."Payables Account");
                GLEntry."Bal. Account Type" := GenJnlLine2."Bal. Account Type";
                GLEntry."Bal. Account No." := GenJnlLine2."Bal. Account No.";
                IF VendLedgEntryInserted THEN BEGIN
                    GLEntry."Entry No." := SaveEntryNo;
                    NextEntryNo := NextEntryNo - 1;
                    SavedEntryUsed := TRUE;
                END;
                InsertGLEntry(TRUE);
            END;

            IF (TotalAmountLCYApplDate <> 0) OR
               (TotalAmountAddCurrApplDate <> 0) AND (GLSetup."Additional Reporting Currency" <> '')
            THEN BEGIN
                GenJnlLine."Posting Date" := ApplicationDate;
                HandlDtlAddjustment(DebitAddjustmentApplDate,
                  DebitAddjustmentAddCurrApplDat,
                  CreditAddjustmentApplDate,
                  CreditAddjustmentAddCurrApplDa,
                  TotalAmountLCYApplDate, TotalAmountAddCurrApplDate, VendPostingGr."Payables Account");
                IF VendLedgEntryInserted AND NOT SavedEntryUsed THEN BEGIN
                    GLEntry."Entry No." := SaveEntryNo;
                    NextEntryNo := NextEntryNo - 1;
                END;
                InsertGLEntry(TRUE);
                GenJnlLine."Posting Date" := OriginalPostingDate;
            END;
            IF NOT GLEntryTmp.FINDFIRST AND DtldCVLedgEntryBuf.FINDFIRST THEN BEGIN
                InitGLEntry(VendPostingGr."Payables Account", PositiveLCYAppAmt, PositiveACYAppAmt, FALSE, TRUE);
                InsertGLEntry(FALSE);
                InitGLEntry(VendPostingGr."Payables Account", NegativeLCYAppAmt, NegativeACYAppAmt, FALSE, TRUE);
                InsertGLEntry(FALSE);
            END;
            DtldCVLedgEntryBuf.DELETEALL;
        END;
    end;

    local procedure AutoEntrForDtldVendLedgEntries(DtldCVLedgEntryBuf: Record "383"; OriginalTransactionNo: Integer)
    var
        GenPostingSetup: Record "252";
        VATPostingSetup: Record "VAT Posting Setup";
        TaxJurisdiction: Record "320";
        AccNo: Code[20];
    begin
        IF (DtldCVLedgEntryBuf."Amount (LCY)" = 0) AND
           ((GLSetup."Additional Reporting Currency" = '') OR
            (DtldCVLedgEntryBuf."Additional-Currency Amount" = 0))
        THEN
            EXIT;

        CASE DtldCVLedgEntryBuf."Entry Type" OF
            DtldCVLedgEntryBuf."Entry Type"::"Initial Entry":
                ;
            DtldCVLedgEntryBuf."Entry Type"::Application:
                ;
            DtldCVLedgEntryBuf."Entry Type"::"Unrealized Loss":
                BEGIN
                    IF Currency.Code <> DtldCVLedgEntryBuf."Currency Code" THEN BEGIN
                        IF DtldCVLedgEntryBuf."Currency Code" = '' THEN
                            CLEAR(Currency)
                        ELSE
                            Currency.GET(DtldCVLedgEntryBuf."Currency Code");
                    END;
                    CheckNonAddCurrCodeOccurred(Currency.Code);
                    Currency.TESTFIELD("Unrealized Losses Acc.");
                    InitGLEntry(
                      Currency."Unrealized Losses Acc.", -DtldCVLedgEntryBuf."Amount (LCY)",
                      0, DtldCVLedgEntryBuf."Currency Code" = GLSetup."Additional Reporting Currency",
                      TRUE);
                    InsertGLEntry(TRUE);
                END;
            DtldCVLedgEntryBuf."Entry Type"::"Unrealized Gain":
                BEGIN
                    IF Currency.Code <> DtldCVLedgEntryBuf."Currency Code" THEN BEGIN
                        IF DtldCVLedgEntryBuf."Currency Code" = '' THEN
                            CLEAR(Currency)
                        ELSE
                            Currency.GET(DtldCVLedgEntryBuf."Currency Code");
                    END;
                    CheckNonAddCurrCodeOccurred(Currency.Code);
                    Currency.TESTFIELD("Unrealized Gains Acc.");
                    InitGLEntry(
                      Currency."Unrealized Gains Acc.", -DtldCVLedgEntryBuf."Amount (LCY)",
                      0, DtldCVLedgEntryBuf."Currency Code" = GLSetup."Additional Reporting Currency",
                      TRUE);
                    InsertGLEntry(TRUE);
                END;
            DtldCVLedgEntryBuf."Entry Type"::"Realized Loss":
                BEGIN
                    IF Currency.Code <> DtldCVLedgEntryBuf."Currency Code" THEN BEGIN
                        IF DtldCVLedgEntryBuf."Currency Code" = '' THEN
                            CLEAR(Currency)
                        ELSE
                            Currency.GET(DtldCVLedgEntryBuf."Currency Code");
                    END;
                    CheckNonAddCurrCodeOccurred(Currency.Code);
                    Currency.TESTFIELD("Realized Losses Acc.");
                    InitGLEntry(
                      Currency."Realized Losses Acc.", -DtldCVLedgEntryBuf."Amount (LCY)",
                      0, DtldCVLedgEntryBuf."Currency Code" = GLSetup."Additional Reporting Currency",
                      TRUE);
                    InsertGLEntry(TRUE);
                END;
            DtldCVLedgEntryBuf."Entry Type"::"Realized Gain":
                BEGIN
                    IF Currency.Code <> DtldCVLedgEntryBuf."Currency Code" THEN BEGIN
                        IF DtldCVLedgEntryBuf."Currency Code" = '' THEN
                            CLEAR(Currency)
                        ELSE
                            Currency.GET(DtldCVLedgEntryBuf."Currency Code");
                    END;
                    CheckNonAddCurrCodeOccurred(Currency.Code);
                    Currency.TESTFIELD("Realized Gains Acc.");
                    InitGLEntry(
                      Currency."Realized Gains Acc.", -DtldCVLedgEntryBuf."Amount (LCY)",
                      0, DtldCVLedgEntryBuf."Currency Code" = GLSetup."Additional Reporting Currency",
                      TRUE);
                    InsertGLEntry(TRUE);
                END;
            DtldCVLedgEntryBuf."Entry Type"::"Payment Discount":
                BEGIN
                    IF DtldCVLedgEntryBuf."Amount (LCY)" > 0 THEN BEGIN
                        VendPostingGr.TESTFIELD("Payment Disc. Debit Acc.");
                        AccNo := VendPostingGr."Payment Disc. Debit Acc.";
                    END ELSE BEGIN
                        VendPostingGr.TESTFIELD("Payment Disc. Credit Acc.");
                        AccNo := VendPostingGr."Payment Disc. Credit Acc.";
                    END;
                    InitGLEntry(
                      AccNo, -DtldCVLedgEntryBuf."Amount (LCY)", 0, FALSE, TRUE);
                    GLEntry."Additional-Currency Amount" := -DtldCVLedgEntryBuf."Additional-Currency Amount";
                    InsertGLEntry(TRUE);
                END;
            DtldCVLedgEntryBuf."Entry Type"::"Payment Discount (VAT Excl.)":
                BEGIN
                    GenPostingSetup.GET(
                      DtldCVLedgEntryBuf."Gen. Bus. Posting Group",
                      DtldCVLedgEntryBuf."Gen. Prod. Posting Group");
                    IF DtldCVLedgEntryBuf."Amount (LCY)" > 0 THEN BEGIN
                        GenPostingSetup.TESTFIELD("Purch. Pmt. Disc. Debit Acc.");
                        AccNo := GenPostingSetup."Purch. Pmt. Disc. Debit Acc.";
                    END ELSE BEGIN
                        GenPostingSetup.TESTFIELD("Purch. Pmt. Disc. Credit Acc.");
                        AccNo := GenPostingSetup."Purch. Pmt. Disc. Credit Acc.";
                    END;
                    InitGLEntry(AccNo, -DtldCVLedgEntryBuf."Amount (LCY)", 0, FALSE, TRUE);
                    GLEntry."Additional-Currency Amount" := -DtldCVLedgEntryBuf."Additional-Currency Amount";
                    GLEntry."VAT Amount" := -DtldCVLedgEntryBuf."VAT Amount (LCY)";
                    GLEntry."Gen. Posting Type" := GLEntry."Gen. Posting Type"::Purchase;
                    GLEntry."Gen. Bus. Posting Group" := DtldCVLedgEntryBuf."Gen. Bus. Posting Group";
                    GLEntry."Gen. Prod. Posting Group" := DtldCVLedgEntryBuf."Gen. Prod. Posting Group";
                    GLEntry."VAT Bus. Posting Group" := DtldCVLedgEntryBuf."VAT Bus. Posting Group";
                    GLEntry."VAT Prod. Posting Group" := DtldCVLedgEntryBuf."VAT Prod. Posting Group";
                    GLEntry."Tax Area Code" := DtldCVLedgEntryBuf."Tax Area Code";
                    GLEntry."Tax Liable" := DtldCVLedgEntryBuf."Tax Liable";
                    GLEntry."Tax Group Code" := DtldCVLedgEntryBuf."Tax Group Code";
                    GLEntry."Use Tax" := DtldCVLedgEntryBuf."Use Tax";
                    InsertGLEntry(TRUE);

                    InsertVatEntriesFromTemp(DtldCVLedgEntryBuf);
                END;
            DtldCVLedgEntryBuf."Entry Type"::"Payment Discount (VAT Adjustment)",
            DtldCVLedgEntryBuf."Entry Type"::"Payment Tolerance (VAT Adjustment)",
            DtldCVLedgEntryBuf."Entry Type"::"Payment Discount Tolerance (VAT Adjustment)":
                BEGIN
                    VATEntry.SETRANGE("Transaction No.", OriginalTransactionNo);
                    VATEntry.SETRANGE("VAT Bus. Posting Group", DtldCVLedgEntryBuf."VAT Bus. Posting Group");
                    VATEntry.SETRANGE("VAT Prod. Posting Group", DtldCVLedgEntryBuf."VAT Prod. Posting Group");
                    VATEntry.FINDFIRST;

                    VATPostingSetup.GET(
                      DtldCVLedgEntryBuf."VAT Bus. Posting Group",
                      DtldCVLedgEntryBuf."VAT Prod. Posting Group");
                    VATPostingSetup.TESTFIELD("VAT Calculation Type", VATEntry."VAT Calculation Type");
                    CLEAR(VATEntry);

                    CASE VATPostingSetup."VAT Calculation Type" OF
                        VATPostingSetup."VAT Calculation Type"::"Normal VAT",
                        VATPostingSetup."VAT Calculation Type"::"Full VAT":
                            BEGIN
                                VATPostingSetup.TESTFIELD("Purchase VAT Account");
                                InitGLEntry(
                                  VATPostingSetup."Purchase VAT Account", -DtldCVLedgEntryBuf."Amount (LCY)",
                                  0, FALSE, TRUE);
                                GLEntry."Additional-Currency Amount" := -DtldCVLedgEntryBuf."Additional-Currency Amount";
                                InsertGLEntry(TRUE);
                            END;
                        VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT":
                            BEGIN
                                VATPostingSetup.TESTFIELD("Purchase VAT Account");
                                InitGLEntry(
                                  VATPostingSetup."Purchase VAT Account", -DtldCVLedgEntryBuf."Amount (LCY)", 0, FALSE, TRUE);
                                GLEntry."Additional-Currency Amount" := -DtldCVLedgEntryBuf."Additional-Currency Amount";
                                InsertGLEntry(TRUE);
                                InitGLEntry(
                                  VATPostingSetup."Reverse Chrg. VAT Acc.", DtldCVLedgEntryBuf."Amount (LCY)", 0, FALSE, TRUE);
                                GLEntry."Additional-Currency Amount" := DtldCVLedgEntryBuf."Additional-Currency Amount";
                                InsertGLEntry(TRUE);
                            END;
                        VATPostingSetup."VAT Calculation Type"::"Sales Tax":
                            IF DtldCVLedgEntryBuf."Use Tax" THEN BEGIN
                                TaxJurisdiction.TESTFIELD("Tax Account (Purchases)");
                                InitGLEntry(
                                  TaxJurisdiction."Tax Account (Purchases)", -DtldCVLedgEntryBuf."Amount (LCY)", 0, FALSE, TRUE);
                                GLEntry."Additional-Currency Amount" := -DtldCVLedgEntryBuf."Additional-Currency Amount";
                                InsertGLEntry(TRUE);
                                TaxJurisdiction.TESTFIELD("Reverse Charge (Purchases)");
                                InitGLEntry(
                                  TaxJurisdiction."Reverse Charge (Purchases)", DtldCVLedgEntryBuf."Amount (LCY)", 0, FALSE, TRUE);
                                GLEntry."Additional-Currency Amount" := DtldCVLedgEntryBuf."Additional-Currency Amount";
                                InsertGLEntry(TRUE);
                            END ELSE BEGIN
                                TaxJurisdiction.TESTFIELD("Tax Account (Purchases)");
                                InitGLEntry(
                                  TaxJurisdiction."Tax Account (Purchases)", -DtldCVLedgEntryBuf."Amount (LCY)", 0, FALSE, TRUE);
                                GLEntry."Additional-Currency Amount" := -DtldCVLedgEntryBuf."Additional-Currency Amount";
                                InsertGLEntry(TRUE);
                            END;
                    END;
                END;
            DtldCVLedgEntryBuf."Entry Type"::"Appln. Rounding":
                BEGIN
                    IF -DtldCVLedgEntryBuf."Amount (LCY)" <> 0 THEN BEGIN
                        CASE TRUE OF
                            -DtldCVLedgEntryBuf."Amount (LCY)" < 0:
                                BEGIN
                                    VendPostingGr.TESTFIELD("Debit Curr. Appln. Rndg. Acc.");
                                    AccNo := VendPostingGr."Debit Curr. Appln. Rndg. Acc.";
                                END;
                            -DtldCVLedgEntryBuf."Amount (LCY)" > 0:
                                BEGIN
                                    VendPostingGr.TESTFIELD("Credit Curr. Appln. Rndg. Acc.");
                                    AccNo := VendPostingGr."Credit Curr. Appln. Rndg. Acc.";
                                END;
                        END;
                        InitGLEntry(
                          AccNo,
                          -DtldCVLedgEntryBuf."Amount (LCY)",
                          -DtldCVLedgEntryBuf."Additional-Currency Amount",
                          TRUE, TRUE);
                        InsertGLEntry(TRUE);
                    END;
                END;
            DtldCVLedgEntryBuf."Entry Type"::"Correction of Remaining Amount":
                BEGIN
                    IF -DtldCVLedgEntryBuf."Amount (LCY)" <> 0 THEN BEGIN
                        CASE TRUE OF
                            -DtldCVLedgEntryBuf."Amount (LCY)" < 0:
                                BEGIN
                                    VendPostingGr.TESTFIELD("Debit Rounding Account");
                                    AccNo := VendPostingGr."Debit Rounding Account";
                                END;
                            -DtldCVLedgEntryBuf."Amount (LCY)" > 0:
                                BEGIN
                                    VendPostingGr.TESTFIELD("Credit Rounding Account");
                                    AccNo := VendPostingGr."Credit Rounding Account";
                                END;
                        END;
                        InitGLEntry(
                          AccNo, -DtldCVLedgEntryBuf."Amount (LCY)",
                          0, FALSE, TRUE);
                        GLEntry."Additional-Currency Amount" := 0;
                        InsertGLEntry(TRUE);
                    END;
                END;
            DtldCVLedgEntryBuf."Entry Type"::"Payment Discount Tolerance":
                BEGIN
                    CASE GLSetup."Pmt. Disc. Tolerance Posting" OF
                        GLSetup."Pmt. Disc. Tolerance Posting"::"Payment Tolerance Accounts":
                            BEGIN
                                IF DtldCVLedgEntryBuf."Amount (LCY)" < 0 THEN BEGIN
                                    VendPostingGr.TESTFIELD("Payment Tolerance Debit Acc.");
                                    AccNo := VendPostingGr."Payment Tolerance Debit Acc.";
                                END ELSE BEGIN
                                    VendPostingGr.TESTFIELD("Payment Tolerance Credit Acc.");
                                    AccNo := VendPostingGr."Payment Tolerance Credit Acc.";
                                END;
                            END;
                        GLSetup."Pmt. Disc. Tolerance Posting"::"Payment Discount Accounts":
                            BEGIN
                                IF DtldCVLedgEntryBuf."Amount (LCY)" < 0 THEN BEGIN
                                    VendPostingGr.TESTFIELD("Payment Disc. Debit Acc.");
                                    AccNo := VendPostingGr."Payment Disc. Debit Acc.";
                                END ELSE BEGIN
                                    VendPostingGr.TESTFIELD("Payment Disc. Credit Acc.");
                                    AccNo := VendPostingGr."Payment Disc. Credit Acc.";
                                END;
                            END;
                    END;
                    InitGLEntry(
                      AccNo, -DtldCVLedgEntryBuf."Amount (LCY)", 0, FALSE, TRUE);
                    GLEntry."Additional-Currency Amount" := -DtldCVLedgEntryBuf."Additional-Currency Amount";
                    InsertGLEntry(TRUE);
                END;
            DtldCVLedgEntryBuf."Entry Type"::"Payment Tolerance":
                BEGIN
                    CASE GLSetup."Payment Tolerance Posting" OF
                        GLSetup."Payment Tolerance Posting"::"Payment Tolerance Accounts":
                            BEGIN
                                IF DtldCVLedgEntryBuf."Amount (LCY)" < 0 THEN BEGIN
                                    VendPostingGr.TESTFIELD("Payment Tolerance Debit Acc.");
                                    AccNo := VendPostingGr."Payment Tolerance Debit Acc.";
                                END ELSE BEGIN
                                    VendPostingGr.TESTFIELD("Payment Tolerance Credit Acc.");
                                    AccNo := VendPostingGr."Payment Tolerance Credit Acc.";
                                END;
                            END;
                        GLSetup."Payment Tolerance Posting"::"Payment Discount Accounts":
                            BEGIN
                                IF DtldCVLedgEntryBuf."Amount (LCY)" < 0 THEN BEGIN
                                    VendPostingGr.TESTFIELD("Payment Disc. Debit Acc.");
                                    AccNo := VendPostingGr."Payment Disc. Debit Acc.";
                                END ELSE BEGIN
                                    VendPostingGr.TESTFIELD("Payment Disc. Credit Acc.");
                                    AccNo := VendPostingGr."Payment Disc. Credit Acc.";
                                END;
                            END;
                    END;
                    InitGLEntry(
                      AccNo, -DtldCVLedgEntryBuf."Amount (LCY)", 0, FALSE, TRUE);
                    GLEntry."Additional-Currency Amount" := -DtldCVLedgEntryBuf."Additional-Currency Amount";
                    InsertGLEntry(TRUE);
                END;
            DtldCVLedgEntryBuf."Entry Type"::"Payment Tolerance (VAT Excl.)":
                BEGIN
                    GenPostingSetup.GET(
                      DtldCVLedgEntryBuf."Gen. Bus. Posting Group",
                      DtldCVLedgEntryBuf."Gen. Prod. Posting Group");
                    CASE GLSetup."Payment Tolerance Posting" OF
                        GLSetup."Payment Tolerance Posting"::"Payment Tolerance Accounts":
                            BEGIN
                                IF DtldCVLedgEntryBuf."Amount (LCY)" > 0 THEN BEGIN
                                    GenPostingSetup.TESTFIELD("Purch. Pmt. Tol. Debit Acc.");
                                    AccNo := GenPostingSetup."Purch. Pmt. Tol. Debit Acc.";
                                END ELSE BEGIN
                                    GenPostingSetup.TESTFIELD("Purch. Pmt. Tol. Credit Acc.");
                                    AccNo := GenPostingSetup."Purch. Pmt. Tol. Credit Acc.";
                                END;
                            END;
                        GLSetup."Payment Tolerance Posting"::"Payment Discount Accounts":
                            BEGIN
                                IF DtldCVLedgEntryBuf."Amount (LCY)" > 0 THEN BEGIN
                                    GenPostingSetup.TESTFIELD("Purch. Pmt. Disc. Debit Acc.");
                                    AccNo := GenPostingSetup."Purch. Pmt. Disc. Debit Acc.";
                                END ELSE BEGIN
                                    GenPostingSetup.TESTFIELD("Purch. Pmt. Disc. Credit Acc.");
                                    AccNo := GenPostingSetup."Purch. Pmt. Disc. Credit Acc.";
                                END;
                            END;
                    END;
                    InitGLEntry(AccNo, -DtldCVLedgEntryBuf."Amount (LCY)", 0, FALSE, TRUE);
                    GLEntry."Additional-Currency Amount" := -DtldCVLedgEntryBuf."Additional-Currency Amount";
                    GLEntry."Gen. Posting Type" := GLEntry."Gen. Posting Type"::Purchase;
                    GLEntry."Gen. Bus. Posting Group" := DtldCVLedgEntryBuf."Gen. Bus. Posting Group";
                    GLEntry."Gen. Prod. Posting Group" := DtldCVLedgEntryBuf."Gen. Prod. Posting Group";
                    GLEntry."VAT Bus. Posting Group" := DtldCVLedgEntryBuf."VAT Bus. Posting Group";
                    GLEntry."VAT Prod. Posting Group" := DtldCVLedgEntryBuf."VAT Prod. Posting Group";
                    GLEntry."Tax Area Code" := DtldCVLedgEntryBuf."Tax Area Code";
                    GLEntry."Tax Liable" := DtldCVLedgEntryBuf."Tax Liable";
                    GLEntry."Tax Group Code" := DtldCVLedgEntryBuf."Tax Group Code";
                    GLEntry."Use Tax" := DtldCVLedgEntryBuf."Use Tax";
                    InsertGLEntry(TRUE);

                    InsertVatEntriesFromTemp(DtldCVLedgEntryBuf);
                END;
            DtldCVLedgEntryBuf."Entry Type"::"Payment Discount Tolerance (VAT Excl.)":
                BEGIN
                    GenPostingSetup.GET(
                      DtldCVLedgEntryBuf."Gen. Bus. Posting Group",
                      DtldCVLedgEntryBuf."Gen. Prod. Posting Group");
                    CASE GLSetup."Pmt. Disc. Tolerance Posting" OF
                        GLSetup."Pmt. Disc. Tolerance Posting"::"Payment Tolerance Accounts":
                            BEGIN
                                IF DtldCVLedgEntryBuf."Amount (LCY)" > 0 THEN BEGIN
                                    GenPostingSetup.TESTFIELD("Purch. Pmt. Tol. Debit Acc.");
                                    AccNo := GenPostingSetup."Purch. Pmt. Tol. Debit Acc.";
                                END ELSE BEGIN
                                    GenPostingSetup.TESTFIELD("Purch. Pmt. Tol. Credit Acc.");
                                    AccNo := GenPostingSetup."Purch. Pmt. Tol. Credit Acc.";
                                END;
                            END;
                        GLSetup."Pmt. Disc. Tolerance Posting"::"Payment Discount Accounts":
                            BEGIN
                                IF DtldCVLedgEntryBuf."Amount (LCY)" > 0 THEN BEGIN
                                    GenPostingSetup.TESTFIELD("Purch. Pmt. Disc. Debit Acc.");
                                    AccNo := GenPostingSetup."Purch. Pmt. Disc. Debit Acc.";
                                END ELSE BEGIN
                                    GenPostingSetup.TESTFIELD("Purch. Pmt. Disc. Credit Acc.");
                                    AccNo := GenPostingSetup."Purch. Pmt. Disc. Credit Acc.";
                                END;
                            END;
                    END;
                    InitGLEntry(AccNo, -DtldCVLedgEntryBuf."Amount (LCY)", 0, FALSE, TRUE);
                    GLEntry."Additional-Currency Amount" := -DtldCVLedgEntryBuf."Additional-Currency Amount";
                    GLEntry."Gen. Posting Type" := GLEntry."Gen. Posting Type"::Purchase;
                    GLEntry."Gen. Bus. Posting Group" := DtldCVLedgEntryBuf."Gen. Bus. Posting Group";
                    GLEntry."Gen. Prod. Posting Group" := DtldCVLedgEntryBuf."Gen. Prod. Posting Group";
                    GLEntry."VAT Bus. Posting Group" := DtldCVLedgEntryBuf."VAT Bus. Posting Group";
                    GLEntry."VAT Prod. Posting Group" := DtldCVLedgEntryBuf."VAT Prod. Posting Group";
                    GLEntry."Tax Area Code" := DtldCVLedgEntryBuf."Tax Area Code";
                    GLEntry."Tax Liable" := DtldCVLedgEntryBuf."Tax Liable";
                    GLEntry."Tax Group Code" := DtldCVLedgEntryBuf."Tax Group Code";
                    GLEntry."Use Tax" := DtldCVLedgEntryBuf."Use Tax";
                    InsertGLEntry(TRUE);

                    InsertVatEntriesFromTemp(DtldCVLedgEntryBuf);
                END;
            ELSE
                DtldCVLedgEntryBuf.FIELDERROR("Entry Type");
        END;
    end;

    local procedure VendUpdateDebitCredit(Correction: Boolean; var DtldVendLedgEntry: Record "380")
    begin
        WITH DtldVendLedgEntry DO BEGIN
            IF ((Amount > 0) OR ("Amount (LCY)" > 0)) AND NOT Correction OR
               ((Amount < 0) OR ("Amount (LCY)" < 0)) AND Correction
            THEN BEGIN
                "Debit Amount" := Amount;
                "Credit Amount" := 0;
                "Debit Amount (LCY)" := "Amount (LCY)";
                "Credit Amount (LCY)" := 0;
            END ELSE BEGIN
                "Debit Amount" := 0;
                "Credit Amount" := -Amount;
                "Debit Amount (LCY)" := 0;
                "Credit Amount (LCY)" := -"Amount (LCY)";
            END;
        END;
    end;

    local procedure VendUnrealizedVAT(var VendLedgEntry2: Record "25"; SettledAmount: Decimal)
    var
        VATEntry2: Record "254";
        VATPart: Decimal;
        VATAmount: Decimal;
        VATBase: Decimal;
        VATAmountAddCurr: Decimal;
        VATBaseAddCurr: Decimal;
        PaidAmount: Decimal;
        TotalUnrealVATAmountFirst: Decimal;
        TotalUnrealVATAmountLast: Decimal;
        PurchVATAccount: Code[20];
        PurchVATUnrealAccount: Code[20];
        PurchReverseAccount: Code[20];
        PurchReverseUnrealAccount: Code[20];
        LastConnectionNo: Integer;
    begin
        VATEntry2.RESET;
        VATEntry2.SETCURRENTKEY("Transaction No.");
        VATEntry2.SETRANGE("Transaction No.", VendLedgEntry2."Transaction No.");
        PaidAmount := -VendLedgEntry2."Amount (LCY)" + VendLedgEntry2."Remaining Amt. (LCY)";
        IF VATEntry2.FINDSET THEN
            REPEAT
                IF (VATPostingSetup."VAT Bus. Posting Group" <> VATEntry2."VAT Bus. Posting Group") OR
                   (VATPostingSetup."VAT Prod. Posting Group" <> VATEntry2."VAT Prod. Posting Group")
                THEN
                    VATPostingSetup.GET(VATEntry2."VAT Bus. Posting Group", VATEntry2."VAT Prod. Posting Group");
                IF VATPostingSetup."Unrealized VAT Type" IN
                  [VATPostingSetup."Unrealized VAT Type"::Last, VATPostingSetup."Unrealized VAT Type"::"Last (Fully Paid)"] THEN
                    TotalUnrealVATAmountLast := TotalUnrealVATAmountLast - VATEntry2."Remaining Unrealized Amount";
                IF VATPostingSetup."Unrealized VAT Type" IN
                  [VATPostingSetup."Unrealized VAT Type"::First, VATPostingSetup."Unrealized VAT Type"::"First (Fully Paid)"] THEN
                    TotalUnrealVATAmountFirst := TotalUnrealVATAmountFirst - VATEntry2."Remaining Unrealized Amount";
            UNTIL VATEntry2.NEXT = 0;
        IF VATEntry2.FINDSET THEN BEGIN
            LastConnectionNo := 0;
            REPEAT
                IF (VATPostingSetup."VAT Bus. Posting Group" <> VATEntry2."VAT Bus. Posting Group") OR
                   (VATPostingSetup."VAT Prod. Posting Group" <> VATEntry2."VAT Prod. Posting Group")
                THEN
                    VATPostingSetup.GET(VATEntry2."VAT Bus. Posting Group", VATEntry2."VAT Prod. Posting Group");
                IF LastConnectionNo <> VATEntry2."Sales Tax Connection No." THEN BEGIN
                    InsertSummarizedVAT;
                    LastConnectionNo := VATEntry2."Sales Tax Connection No.";
                END;

                VATPart :=
                  VATEntry2.GetUnRealizedVATPart(
                    ROUND(SettledAmount / VendLedgEntry2.GetOriginalCurrencyFactor),
                    PaidAmount,
                    VendLedgEntry2."Original Amt. (LCY)",
                    TotalUnrealVATAmountFirst,
                    TotalUnrealVATAmountLast);

                IF VATPart >= 0 THEN BEGIN
                    IF VATPart <> 0 THEN BEGIN
                        CASE VATEntry2."VAT Calculation Type" OF
                            VATEntry2."VAT Calculation Type"::"Normal VAT",
                            VATEntry2."VAT Calculation Type"::"Full VAT":
                                BEGIN
                                    VATPostingSetup.TESTFIELD("Purchase VAT Account");
                                    VATPostingSetup.TESTFIELD("Purch. VAT Unreal. Account");
                                    PurchVATAccount := VATPostingSetup."Purchase VAT Account";
                                    PurchVATUnrealAccount := VATPostingSetup."Purch. VAT Unreal. Account";
                                END;
                            VATEntry2."VAT Calculation Type"::"Reverse Charge VAT":
                                BEGIN
                                    VATPostingSetup.TESTFIELD("Purchase VAT Account");
                                    VATPostingSetup.TESTFIELD("Purch. VAT Unreal. Account");
                                    VATPostingSetup.TESTFIELD("Reverse Chrg. VAT Acc.");
                                    VATPostingSetup.TESTFIELD("Reverse Chrg. VAT Unreal. Acc.");
                                    PurchVATAccount := VATPostingSetup."Purchase VAT Account";
                                    PurchVATUnrealAccount := VATPostingSetup."Purch. VAT Unreal. Account";
                                    PurchReverseAccount := VATPostingSetup."Reverse Chrg. VAT Acc.";
                                    PurchReverseUnrealAccount := VATPostingSetup."Reverse Chrg. VAT Unreal. Acc.";
                                END;
                            VATEntry2."VAT Calculation Type"::"Sales Tax":
                                IF (VATEntry2.Type = VATEntry2.Type::Purchase) AND VATEntry2."Use Tax" THEN BEGIN
                                    TaxJurisdiction.GET(VATEntry2."Tax Jurisdiction Code");
                                    TaxJurisdiction.TESTFIELD("Tax Account (Purchases)");
                                    TaxJurisdiction.TESTFIELD("Reverse Charge (Purchases)");
                                    TaxJurisdiction.TESTFIELD("Unreal. Tax Acc. (Purchases)");
                                    TaxJurisdiction.TESTFIELD("Unreal. Rev. Charge (Purch.)");
                                    PurchVATAccount := TaxJurisdiction."Tax Account (Purchases)";
                                    PurchVATUnrealAccount := TaxJurisdiction."Unreal. Tax Acc. (Purchases)";
                                    PurchReverseAccount := TaxJurisdiction."Reverse Charge (Purchases)";
                                    PurchReverseUnrealAccount := TaxJurisdiction."Unreal. Rev. Charge (Purch.)";
                                END ELSE BEGIN
                                    TaxJurisdiction.GET(VATEntry2."Tax Jurisdiction Code");
                                    TaxJurisdiction.TESTFIELD("Tax Account (Purchases)");
                                    TaxJurisdiction.TESTFIELD("Unreal. Tax Acc. (Purchases)");
                                    PurchVATAccount := TaxJurisdiction."Tax Account (Purchases)";
                                    PurchVATUnrealAccount := TaxJurisdiction."Unreal. Tax Acc. (Purchases)";
                                END;
                        END;

                        IF VATPart = 1 THEN BEGIN
                            VATAmount := VATEntry2."Remaining Unrealized Amount";
                            VATBase := VATEntry2."Remaining Unrealized Base";
                            VATAmountAddCurr := VATEntry2."Add.-Curr. Rem. Unreal. Amount";
                            VATBaseAddCurr := VATEntry2."Add.-Curr. Rem. Unreal. Base";
                        END ELSE BEGIN
                            VATAmount := ROUND(VATEntry2."Remaining Unrealized Amount" * VATPart);
                            VATBase := ROUND(VATEntry2."Remaining Unrealized Base" * VATPart);
                            VATAmountAddCurr :=
                              ROUND(
                                VATEntry2."Add.-Curr. Rem. Unreal. Amount" * VATPart,
                                AddCurrency."Amount Rounding Precision");
                            VATBaseAddCurr :=
                              ROUND(
                                VATEntry2."Add.-Curr. Rem. Unreal. Base" * VATPart,
                                AddCurrency."Amount Rounding Precision");
                        END;

                        InitGLEntry(PurchVATUnrealAccount, -VATAmount, 0, FALSE, TRUE);
                        GLEntry."Additional-Currency Amount" := -VATAmountAddCurr;
                        GLEntry."Bal. Account No." := PurchVATAccount;
                        SummarizeVAT(
                          GLSetup."Summarize G/L Entries", GLEntry, TempGLEntryVAT, InsertedTempGLEntryVAT);

                        InitGLEntry(PurchVATAccount, VATAmount, 0, FALSE, TRUE);
                        GLEntry."Additional-Currency Amount" := VATAmountAddCurr;
                        GLEntry."Gen. Posting Type" := VATEntry2.Type;
                        GLEntry."Gen. Bus. Posting Group" := VATEntry2."Gen. Bus. Posting Group";
                        GLEntry."Gen. Prod. Posting Group" := VATEntry2."Gen. Prod. Posting Group";
                        GLEntry."VAT Bus. Posting Group" := VATEntry2."VAT Bus. Posting Group";
                        GLEntry."VAT Prod. Posting Group" := VATEntry2."VAT Prod. Posting Group";
                        GLEntry."Tax Area Code" := VATEntry2."Tax Area Code";
                        GLEntry."Tax Liable" := VATEntry2."Tax Liable";
                        GLEntry."Tax Group Code" := VATEntry2."Tax Group Code";
                        GLEntry."Use Tax" := VATEntry2."Use Tax";
                        GLEntry."Bal. Account No." := PurchVATUnrealAccount;
                        SummarizeVAT(
                          GLSetup."Summarize G/L Entries", GLEntry, TempGLEntryVAT, InsertedTempGLEntryVAT);

                        IF (VATEntry2."VAT Calculation Type" =
                            VATEntry2."VAT Calculation Type"::"Reverse Charge VAT") OR
                           ((VATEntry2."VAT Calculation Type" =
                             VATEntry2."VAT Calculation Type"::"Sales Tax") AND
                            (VATEntry2.Type = VATEntry2.Type::Purchase) AND VATEntry2."Use Tax")
                        THEN BEGIN
                            InitGLEntry(PurchReverseUnrealAccount, VATAmount, 0, FALSE, TRUE);
                            GLEntry."Additional-Currency Amount" := VATAmountAddCurr;
                            GLEntry."Bal. Account No." := PurchReverseAccount;
                            SummarizeVAT(
                              GLSetup."Summarize G/L Entries", GLEntry, TempGLEntryVAT, InsertedTempGLEntryVAT);

                            InitGLEntry(PurchReverseAccount, -VATAmount, 0, FALSE, TRUE);
                            GLEntry."Additional-Currency Amount" := -VATAmountAddCurr;
                            GLEntry."Gen. Posting Type" := VATEntry2.Type;
                            GLEntry."Gen. Bus. Posting Group" := VATEntry2."Gen. Bus. Posting Group";
                            GLEntry."Gen. Prod. Posting Group" := VATEntry2."Gen. Prod. Posting Group";
                            GLEntry."VAT Bus. Posting Group" := VATEntry2."VAT Bus. Posting Group";
                            GLEntry."VAT Prod. Posting Group" := VATEntry2."VAT Prod. Posting Group";
                            GLEntry."Tax Area Code" := VATEntry2."Tax Area Code";
                            GLEntry."Tax Liable" := VATEntry2."Tax Liable";
                            GLEntry."Tax Group Code" := VATEntry2."Tax Group Code";
                            GLEntry."Use Tax" := VATEntry2."Use Tax";
                            GLEntry."Bal. Account No." := PurchReverseUnrealAccount;
                            SummarizeVAT(
                              GLSetup."Summarize G/L Entries", GLEntry, TempGLEntryVAT, InsertedTempGLEntryVAT);
                        END;

                        VATEntry.LOCKTABLE;
                        VATEntry := VATEntry2;
                        VATEntry."Entry No." := NextVATEntryNo;
                        VATEntry."Posting Date" := GenJnlLine."Posting Date";
                        VATEntry."Document No." := GenJnlLine."Document No.";
                        VATEntry."External Document No." := GenJnlLine."External Document No.";
                        VATEntry."Document Type" := GenJnlLine."Document Type";
                        VATEntry.Amount := VATAmount;
                        VATEntry.Base := VATBase;
                        VATEntry."Unrealized Amount" := 0;
                        VATEntry."Unrealized Base" := 0;
                        VATEntry."Remaining Unrealized Amount" := 0;
                        VATEntry."Remaining Unrealized Base" := 0;
                        VATEntry."Additional-Currency Amount" := VATAmountAddCurr;
                        VATEntry."Additional-Currency Base" := VATBaseAddCurr;
                        VATEntry."Add.-Currency Unrealized Amt." := 0;
                        VATEntry."Add.-Currency Unrealized Base" := 0;
                        VATEntry."Add.-Curr. Rem. Unreal. Amount" := 0;
                        VATEntry."Add.-Curr. Rem. Unreal. Base" := 0;
                        VATEntry."User ID" := USERID;
                        VATEntry."Source Code" := GenJnlLine."Source Code";
                        VATEntry."Reason Code" := GenJnlLine."Reason Code";
                        VATEntry."Closed by Entry No." := 0;
                        VATEntry.Closed := FALSE;
                        VATEntry."Transaction No." := GLEntry."Transaction No.";
                        VATEntry."Sales Tax Connection No." := NextConnectionNo;
                        VATEntry."Unrealized VAT Entry No." := VATEntry2."Entry No.";
                        VATEntry.INSERT;
                        NextVATEntryNo := NextVATEntryNo + 1;

                        VATEntry2."Remaining Unrealized Amount" :=
                          VATEntry2."Remaining Unrealized Amount" - VATEntry.Amount;
                        VATEntry2."Remaining Unrealized Base" :=
                          VATEntry2."Remaining Unrealized Base" - VATEntry.Base;
                        VATEntry2."Add.-Curr. Rem. Unreal. Amount" :=
                          VATEntry2."Add.-Curr. Rem. Unreal. Amount" - VATEntry."Additional-Currency Amount";
                        VATEntry2."Add.-Curr. Rem. Unreal. Base" :=
                          VATEntry2."Add.-Curr. Rem. Unreal. Base" - VATEntry."Additional-Currency Base";
                        VATEntry2.MODIFY;
                    END;
                END;
            UNTIL VATEntry2.NEXT = 0;

            InsertSummarizedVAT;
        END;
    end;

    local procedure PostUnrealVATByUnapply(UnrealVATAccNo: Code[20]; VATAccNo: Code[20]; VATEntry: Record "254"; NewVATEntry: Record "254")
    var
        VATEntry2: Record "254";
    begin
        InitGLEntry(UnrealVATAccNo, VATEntry.Amount, 0, FALSE, TRUE);
        GLEntry."Additional-Currency Amount" :=
          CalcAddCurrForUnapplication(VATEntry."Posting Date", VATEntry.Amount);
        InsertGLEntry(TRUE);

        InitGLEntry(VATAccNo, -VATEntry.Amount, 0, FALSE, TRUE);
        GLEntry."Additional-Currency Amount" :=
          CalcAddCurrForUnapplication(VATEntry."Posting Date", -VATEntry.Amount);
        GLEntry."Gen. Posting Type" := VATEntry.Type;
        GLEntry."Gen. Bus. Posting Group" := VATEntry."Gen. Bus. Posting Group";
        GLEntry."Gen. Prod. Posting Group" := VATEntry."Gen. Prod. Posting Group";
        GLEntry."VAT Bus. Posting Group" := VATEntry."VAT Bus. Posting Group";
        GLEntry."VAT Prod. Posting Group" := VATEntry."VAT Prod. Posting Group";
        GLEntry."Tax Area Code" := VATEntry."Tax Area Code";
        GLEntry."Tax Liable" := VATEntry."Tax Liable";
        GLEntry."Tax Group Code" := VATEntry."Tax Group Code";
        GLEntry."Use Tax" := VATEntry."Use Tax";
        InsertGLEntry(TRUE);

        WITH VATEntry2 DO BEGIN
            GET(VATEntry."Unrealized VAT Entry No.");
            "Remaining Unrealized Amount" := "Remaining Unrealized Amount" - NewVATEntry.Amount;
            "Remaining Unrealized Base" := "Remaining Unrealized Base" - NewVATEntry.Base;
            "Add.-Curr. Rem. Unreal. Amount" :=
              "Add.-Curr. Rem. Unreal. Amount" - NewVATEntry."Additional-Currency Amount";
            "Add.-Curr. Rem. Unreal. Base" :=
              "Add.-Curr. Rem. Unreal. Base" - NewVATEntry."Additional-Currency Base";
            MODIFY;
        END;
    end;

    local procedure UpdateCalcInterest(var CVLedgEntryBuf: Record "382")
    var
        CustLedgEntry: Record "21";
        CVLedgEntryBuf2: Record "382";
    begin
        WITH CVLedgEntryBuf DO BEGIN
            IF CustLedgEntry.GET("Closed by Entry No.") THEN BEGIN
                CVLedgEntryBuf2.TRANSFERFIELDS(CustLedgEntry);
                UpdateCalcInterest2(CVLedgEntryBuf, CVLedgEntryBuf2);
            END;
            CustLedgEntry.SETCURRENTKEY("Closed by Entry No.");
            CustLedgEntry.SETRANGE("Closed by Entry No.", "Entry No.");
            IF CustLedgEntry.FINDSET THEN
                REPEAT
                    CVLedgEntryBuf2.TRANSFERFIELDS(CustLedgEntry);
                    UpdateCalcInterest2(CVLedgEntryBuf, CVLedgEntryBuf2);
                UNTIL CustLedgEntry.NEXT = 0;
        END;
    end;

    local procedure UpdateCalcInterest2(var CVLedgEntryBuf: Record "382"; var CVLedgEntryBuf2: Record "382")
    begin
        WITH CVLedgEntryBuf DO
            IF "Due Date" < CVLedgEntryBuf2."Document Date" THEN
                "Calculate Interest" := TRUE;
    end;

    procedure GLCalcAddCurrency(AddCurrAmount: Decimal; UseAddCurrAmount: Boolean)
    begin
        IF (GLSetup."Additional Reporting Currency" <> '') AND
           (GenJnlLine."Additional-Currency Posting" = GenJnlLine."Additional-Currency Posting"::None)
        THEN BEGIN
            IF (GenJnlLine."Source Currency Code" = GLSetup."Additional Reporting Currency") AND
               UseAddCurrAmount
            THEN
                GLEntry."Additional-Currency Amount" := AddCurrAmount
            ELSE
                GLEntry."Additional-Currency Amount" := ExchangeAmtLCYToFCY2(GLEntry.Amount);
        END;
    end;

    procedure HandleAddCurrResidualGLEntry()
    var
        TableID: array[10] of Integer;
        AccNo: array[10] of Code[20];
    begin
        IF GLSetup."Additional Reporting Currency" = '' THEN
            EXIT;

        TotalAddCurrAmount := TotalAddCurrAmount + GLEntry."Additional-Currency Amount";
        TotalAmount := TotalAmount + GLEntry.Amount;

        IF (GenJnlLine."Additional-Currency Posting" = GenJnlLine."Additional-Currency Posting"::None) AND
            (TotalAmount = 0) AND (TotalAddCurrAmount <> 0) AND
            CheckNonAddCurrCodeOccurred(GenJnlLine."Source Currency Code")
        THEN BEGIN
            OrigGLEntry := GLEntry;
            GLEntry.INIT;
            GLEntry."Posting Date" := GenJnlLine."Posting Date";
            GLEntry."Document Date" := GenJnlLine."Document Date";
            GLEntry."Document Type" := GenJnlLine."Document Type";
            GLEntry."Document No." := GenJnlLine."Document No.";
            GLEntry."External Document No." := '';
            GLEntry.Description :=
              COPYSTR(
                STRSUBSTNO(
                  Text010,
                  GLEntry.FIELDCAPTION("Additional-Currency Amount")),
                1, MAXSTRLEN(GLEntry.Description));
            GLEntry."Business Unit Code" := GenJnlLine."Business Unit Code";
            GLEntry."Global Dimension 1 Code" := GenJnlLine."Shortcut Dimension 1 Code";
            GLEntry."Global Dimension 2 Code" := GenJnlLine."Shortcut Dimension 2 Code";
            GLEntry."Source Code" := GenJnlLine."Source Code";
            GLEntry."Source Type" := 0;
            GLEntry."Source No." := '';
            GLEntry."Job No." := '';
            GLEntry.Quantity := 0;
            GLEntry."Journal Batch Name" := GenJnlLine."Journal Batch Name";
            GLEntry."Reason Code" := GenJnlLine."Reason Code";
            GLEntry."Entry No." := NextEntryNo;
            GLEntry."Transaction No." := NextTransactionNo;
            IF TotalAddCurrAmount < 0 THEN
                GLEntry."G/L Account No." := AddCurrency."Residual Losses Account"
            ELSE
                GLEntry."G/L Account No." := AddCurrency."Residual Gains Account";
            GLEntry.Amount := 0;
            GLEntry."User ID" := USERID;
            GLEntry."No. Series" := GenJnlLine."Posting No. Series";
            GLEntry."System-Created Entry" := TRUE;
            GLEntry."Prior-Year Entry" := GLEntry."Posting Date" < FiscalYearStartDate;
            GLEntry."Additional-Currency Amount" := -TotalAddCurrAmount;
            GLAcc.GET(GLEntry."G/L Account No.");
            GLAcc.TESTFIELD(Blocked, FALSE);
            GLAcc.TESTFIELD("Account Type", GLAcc."Account Type"::Posting);
            InsertGLEntry(FALSE);

            GLAcc.GET(GLEntry."G/L Account No.");
            GLAcc.TESTFIELD(Blocked, FALSE);
            GLAcc.TESTFIELD("Account Type", GLAcc."Account Type"::Posting);
            TableID[1] := DimMgt.TypeToTableID1(GenJnlLine."Account Type"::"G/L Account");
            AccNo[1] := GLEntry."G/L Account No.";
            IF NOT DimMgt.CheckJnlLineDimValuePosting(TempJnlLineDim, TableID, AccNo) THEN
                IF GenJnlLine."Line No." <> 0 THEN
                    ERROR(
                      Text013,
                      GenJnlLine.TABLECAPTION, GenJnlLine."Journal Template Name",
                      GenJnlLine."Journal Batch Name", GenJnlLine."Line No.",
                      DimMgt.GetDimValuePostingErr)
                ELSE
                    ERROR(DimMgt.GetDimValuePostingErr);

            GLEntry := OrigGLEntry;
            TotalAddCurrAmount := 0;
        END;
    end;

    local procedure CalcLCYToAddCurr(AmountLCY: Decimal): Decimal
    begin
        IF GLSetup."Additional Reporting Currency" = '' THEN
            EXIT;
        EXIT(ExchangeAmtLCYToFCY2(AmountLCY));
    end;

    procedure CalcAddCurrFactor(Numerator: Decimal; Denominator: Decimal): Decimal
    begin
        IF Denominator = 0 THEN
            EXIT(0);

        IF Numerator <> 0 THEN
            EXIT(Numerator / Denominator)
        ELSE
            IF GLSetup."Additional Reporting Currency" <> '' THEN
                CalcLCYToAddCurr(1)
            ELSE
                EXIT(0);
    end;

    procedure GetCurrencyExchRate()
    var
        NewCurrencyDate: Date;
    begin
        IF GLSetup."Additional Reporting Currency" <> '' THEN BEGIN
            IF GLSetup."Additional Reporting Currency" <> AddCurrency.Code THEN BEGIN
                AddCurrency.GET(GLSetup."Additional Reporting Currency");
                AddCurrency.TESTFIELD("Amount Rounding Precision");
                AddCurrency.TESTFIELD("Residual Gains Account");
                AddCurrency.TESTFIELD("Residual Losses Account");
            END;
            NewCurrencyDate := GenJnlLine."Posting Date";
            IF GenJnlLine."Reversing Entry" THEN
                NewCurrencyDate := NewCurrencyDate - 1;
            IF (NewCurrencyDate <> CurrencyDate) OR
               UseCurrFactorOnly
            THEN BEGIN
                UseCurrFactorOnly := FALSE;
                CurrencyDate := NewCurrencyDate;
                CurrencyFactor :=
                  CurrExchRate.ExchangeRate(
                    CurrencyDate, GLSetup."Additional Reporting Currency");
            END;
            IF (GenJnlLine."FA Add.-Currency Factor" <> 0) AND
               (GenJnlLine."FA Add.-Currency Factor" <> CurrencyFactor)
            THEN BEGIN
                UseCurrFactorOnly := TRUE;
                CurrencyDate := 0D;
                CurrencyFactor := GenJnlLine."FA Add.-Currency Factor";
            END;
        END;
    end;

    procedure ExchAmount(Amount: Decimal; FromCurrencyCode: Code[10]; ToCurrencyCode: Code[10]; UsePostingDate: Date): Decimal
    var
        ToCurrency: Record "4";
    begin
        IF (FromCurrencyCode = ToCurrencyCode) OR (Amount = 0) THEN
            EXIT(Amount);

        Amount :=
          CurrExchRate.ExchangeAmtFCYToFCY(
            UsePostingDate, FromCurrencyCode, ToCurrencyCode, Amount);

        IF ToCurrencyCode <> '' THEN BEGIN
            ToCurrency.GET(ToCurrencyCode);
            Amount := ROUND(Amount, ToCurrency."Amount Rounding Precision");
        END ELSE
            Amount := ROUND(Amount);

        EXIT(Amount);
    end;

    local procedure ExchangeAmtLCYToFCY2(Amount: Decimal): Decimal
    begin
        IF UseCurrFactorOnly THEN
            EXIT(
              ROUND(
                CurrExchRate.ExchangeAmtLCYToFCYOnlyFactor(Amount, CurrencyFactor),
                AddCurrency."Amount Rounding Precision"));
        EXIT(
          ROUND(
            CurrExchRate.ExchangeAmtLCYToFCY(
              CurrencyDate, GLSetup."Additional Reporting Currency", Amount, CurrencyFactor),
            AddCurrency."Amount Rounding Precision"));
    end;

    local procedure CalcAddCurrForUnapplication(Date: Date; Amt: Decimal): Decimal
    var
        AddCurrency: Record "4";
    begin
        IF GLSetup."Additional Reporting Currency" <> '' THEN BEGIN
            IF GLSetup."Additional Reporting Currency" <> AddCurrency.Code THEN BEGIN
                AddCurrency.GET(GLSetup."Additional Reporting Currency");
                AddCurrency.TESTFIELD("Amount Rounding Precision");
            END;
            EXIT(
              ROUND(
                CurrExchRate.ExchangeAmtLCYToFCY(
                  Date,
                  GLSetup."Additional Reporting Currency",
                  Amt,
                  CurrExchRate.ExchangeRate(Date, GLSetup."Additional Reporting Currency")),
                AddCurrency."Amount Rounding Precision"));
        END;
    end;

    local procedure InsertFAAllocDim(EntryNo: Integer): Boolean
    var
        FAAllocDim: Record "5648";
    begin
        IF FAGLPostBuf.GET(EntryNo) THEN BEGIN
            TempFAJnlLineDim.DELETEALL;
            FAAllocDim.SETRANGE(Code, FAGLPostBuf."FA Posting Group");
            FAAllocDim.SETRANGE("Allocation Type", FAGLPostBuf."FA Allocation Type");
            FAAllocDim.SETRANGE("Line No.", FAGLPostBuf."FA Allocation Line No.");
            IF FAAllocDim.FINDSET THEN
                REPEAT
                    TempFAJnlLineDim."Dimension Code" := FAAllocDim."Dimension Code";
                    TempFAJnlLineDim."Dimension Value Code" := FAAllocDim."Dimension Value Code";
                    TempFAJnlLineDim.INSERT;
                UNTIL FAAllocDim.NEXT = 0;
            DimMgt.MoveJnlLineDimToLedgEntryDim(
              TempFAJnlLineDim, DATABASE::"G/L Entry", EntryNo);
            FAGLPostBuf.DELETE;
            EXIT(TRUE);
        END ELSE
            EXIT(FALSE);
    end;

    local procedure CheckNonAddCurrCodeOccurred(CurrencyCode: Code[10]): Boolean
    begin
        NonAddCurrCodeOccured :=
          NonAddCurrCodeOccured OR (GLSetup."Additional Reporting Currency" <> CurrencyCode);
        EXIT(NonAddCurrCodeOccured);
    end;

    procedure CheckCalcPmtDisc(var NewCVLedgEntryBuf: Record "382"; var OldCVLedgEntryBuf2: Record "382"; ApplnRoundingPrecision: Decimal; CheckFilter: Boolean; CheckAmount: Boolean): Boolean
    begin
        IF (((NewCVLedgEntryBuf."Document Type" = NewCVLedgEntryBuf."Document Type"::Refund) OR
             (NewCVLedgEntryBuf."Document Type" = NewCVLedgEntryBuf."Document Type"::Payment)) AND
            (((OldCVLedgEntryBuf2."Document Type" = OldCVLedgEntryBuf2."Document Type"::"Credit Memo") AND
              (OldCVLedgEntryBuf2."Remaining Pmt. Disc. Possible" <> 0) AND
              (NewCVLedgEntryBuf."Posting Date" <= OldCVLedgEntryBuf2."Pmt. Discount Date")) OR
              ((OldCVLedgEntryBuf2."Document Type" = OldCVLedgEntryBuf2."Document Type"::Invoice) AND
               (NewCVLedgEntryBuf."Posting Date" <= OldCVLedgEntryBuf2."Pmt. Discount Date"))))
        THEN BEGIN
            IF CheckFilter THEN BEGIN
                IF CheckAmount THEN BEGIN
                    IF (OldCVLedgEntryBuf2.GETFILTER(Positive) <> '') OR
                      (ABS(NewCVLedgEntryBuf."Remaining Amount") + ApplnRoundingPrecision >=
                      ABS(OldCVLedgEntryBuf2."Remaining Amount" - OldCVLedgEntryBuf2."Remaining Pmt. Disc. Possible"))
                    THEN
                        EXIT(TRUE)
                    ELSE
                        EXIT(FALSE);
                END ELSE BEGIN
                    IF (OldCVLedgEntryBuf2.GETFILTER(Positive) <> '')
                    THEN
                        EXIT(TRUE)
                    ELSE
                        EXIT(FALSE);
                END;
            END ELSE BEGIN
                IF CheckAmount THEN BEGIN
                    IF (ABS(NewCVLedgEntryBuf."Remaining Amount") + ApplnRoundingPrecision >=
                      ABS(OldCVLedgEntryBuf2."Remaining Amount" - OldCVLedgEntryBuf2."Remaining Pmt. Disc. Possible"))
                    THEN
                        EXIT(TRUE)
                    ELSE
                        EXIT(FALSE);
                END ELSE
                    EXIT(TRUE);
            END;
            EXIT(TRUE);
        END ELSE
            EXIT(FALSE);
    end;

    procedure CheckCalcPmtDiscCVCust(var NewCVLedgEntryBuf: Record "382"; var OldCustLedgEntry2: Record "21"; ApplnRoundingPrecision: Decimal; CheckFilter: Boolean; CheckAmount: Boolean): Boolean
    var
        OldCVLedgEntryBuf2: Record "382";
    begin
        OldCustLedgEntry2.COPYFILTER(Positive, OldCVLedgEntryBuf2.Positive);
        TransferCustLedgEntry(OldCVLedgEntryBuf2, OldCustLedgEntry2, TRUE);
        EXIT(
          CheckCalcPmtDisc(
            NewCVLedgEntryBuf, OldCVLedgEntryBuf2, ApplnRoundingPrecision, CheckFilter, CheckAmount));
    end;

    procedure CheckCalcPmtDiscCust(var NewCustLedgEntry: Record "21"; var OldCustLedgEntry2: Record "21"; ApplnRoundingPrecision: Decimal; CheckFilter: Boolean; CheckAmount: Boolean): Boolean
    var
        NewCVLedgEntryBuf: Record "382";
        OldCVLedgEntryBuf2: Record "382";
    begin
        TransferCustLedgEntry(NewCVLedgEntryBuf, NewCustLedgEntry, TRUE);
        OldCustLedgEntry2.COPYFILTER(Positive, OldCVLedgEntryBuf2.Positive);
        TransferCustLedgEntry(OldCVLedgEntryBuf2, OldCustLedgEntry2, TRUE);
        EXIT(
          CheckCalcPmtDisc(
            NewCVLedgEntryBuf, OldCVLedgEntryBuf2, ApplnRoundingPrecision, CheckFilter, CheckAmount));
    end;

    procedure CheckCalcPmtDiscGenJnlCust(GenJnlLine: Record "Gen. Journal Line"; OldCustLedgEntry2: Record "21"; ApplnRoundingPrecision: Decimal; CheckAmount: Boolean): Boolean
    var
        NewCVLedgEntryBuf: Record "382";
        OldCVLedgEntryBuf2: Record "382";
    begin
        NewCVLedgEntryBuf."Document Type" := GenJnlLine."Document Type";
        NewCVLedgEntryBuf."Posting Date" := GenJnlLine."Posting Date";
        NewCVLedgEntryBuf."Remaining Amount" := GenJnlLine.Amount;
        TransferCustLedgEntry(OldCVLedgEntryBuf2, OldCustLedgEntry2, TRUE);
        EXIT(
          CheckCalcPmtDisc(
            NewCVLedgEntryBuf, OldCVLedgEntryBuf2, ApplnRoundingPrecision, FALSE, CheckAmount));
    end;

    procedure CheckCalcPmtDiscCVVend(var NewCVLedgEntrybuf: Record "382"; var OldVendLedgEntry2: Record "25"; ApplnRoundingPrecision: Decimal; CheckFilter: Boolean; CheckAmount: Boolean): Boolean
    var
        OldCVLedgEntryBuf2: Record "382";
    begin
        OldVendLedgEntry2.COPYFILTER(Positive, OldCVLedgEntryBuf2.Positive);
        TransferVendLedgEntry(OldCVLedgEntryBuf2, OldVendLedgEntry2, TRUE);
        EXIT(
          CheckCalcPmtDisc(
            NewCVLedgEntrybuf, OldCVLedgEntryBuf2, ApplnRoundingPrecision, CheckFilter, CheckAmount));
    end;

    procedure CheckCalcPmtDiscVend(var NewVendLedgEntry: Record "25"; var OldVendLedgEntry2: Record "25"; ApplnRoundingPrecision: Decimal; CheckFilter: Boolean; CheckAmount: Boolean): Boolean
    var
        NewCVLedgEntryBuf: Record "382";
        OldCVLedgEntryBuf2: Record "382";
    begin
        TransferVendLedgEntry(NewCVLedgEntryBuf, NewVendLedgEntry, TRUE);
        OldVendLedgEntry2.COPYFILTER(Positive, OldCVLedgEntryBuf2.Positive);
        TransferVendLedgEntry(OldCVLedgEntryBuf2, OldVendLedgEntry2, TRUE);
        EXIT(
          CheckCalcPmtDisc(
            NewCVLedgEntryBuf, OldCVLedgEntryBuf2, ApplnRoundingPrecision, CheckFilter, CheckAmount));
    end;

    procedure CheckCalcPmtDiscGenJnlVend(GenJnlLine: Record "Gen. Journal Line"; OldVendLedgEntry2: Record "25"; ApplnRoundingPrecision: Decimal; CheckAmount: Boolean): Boolean
    var
        NewCVLedgEntryBuf: Record "382";
        OldCVLedgEntryBuf2: Record "382";
    begin
        NewCVLedgEntryBuf."Document Type" := GenJnlLine."Document Type";
        NewCVLedgEntryBuf."Posting Date" := GenJnlLine."Posting Date";
        NewCVLedgEntryBuf."Remaining Amount" := GenJnlLine.Amount;
        TransferVendLedgEntry(OldCVLedgEntryBuf2, OldVendLedgEntry2, TRUE);
        EXIT(
          CheckCalcPmtDisc(
            NewCVLedgEntryBuf, OldCVLedgEntryBuf2, ApplnRoundingPrecision, FALSE, CheckAmount));
    end;

    procedure Reverse(var ReversalEntry: Record "179"; var ReversalEntry2: Record "179")
    var
        SourceCodeSetup: Record "242";
        GLEntry2: Record "G/L Entry";
        ReversedGLEntry: Record "G/L Entry";
        GLReg2: Record "G/L Register";
        CustLedgEntry: Record "21";
        TempCustLedgEntry: Record "21" temporary;
        VendLedgEntry: Record "25";
        TempVendLedgEntry: Record "25" temporary;
        BankAccLedgEntry: Record "271";
        TempBankAccLedgEntry: Record "271" temporary;
        VATEntry: Record "254";
        FALedgEntry: Record "5601";
        MaintenanceLedgEntry: Record "5625";
        LedgEntryDim: Record "355";
        TempRevertTransactionNo: Record "2000000026" temporary;
        FAInsertLedgEntry: Codeunit "5600";
        UpdateAnalysisView: Codeunit "410";
        NextDtldCustLedgEntryEntryNo: Integer;
        NextDtldVendLedgEntryEntryNo: Integer;
        TableID: array[10] of Integer;
        AccNo: array[10] of Code[20];
    begin
        SourceCodeSetup.GET;
        IF ReversalEntry2."Reversal Type" = ReversalEntry2."Reversal Type"::Register THEN
            GLReg2."No." := ReversalEntry2."G/L Register No.";

        ReversalEntry.CopyFilters(
          GLEntry2, CustLedgEntry, VendLedgEntry, BankAccLedgEntry, VATEntry, FALedgEntry, MaintenanceLedgEntry);

        IF ReversalEntry2."Reversal Type" = ReversalEntry2."Reversal Type"::Transaction THEN BEGIN
            IF ReversalEntry2.FINDSET(FALSE, FALSE) THEN
                REPEAT
                    TempRevertTransactionNo.Number := ReversalEntry2."Transaction No.";
                    IF TempRevertTransactionNo.INSERT THEN;
                UNTIL ReversalEntry2.NEXT = 0;
        END;

        GetAgrmtReverseReason(ReversalEntry); //LG00.02

        CLEAR(GenJnlLine);
        GenJnlLine."Source Code" := SourceCodeSetup.Reversal;
        GenJnlLine."Reason Code" := ReverseReason; //LG00.02

        InitCodeUnit;
        GLReg.Reversed := TRUE;

        IF CustLedgEntry.FINDSET THEN
            REPEAT
                IF CustLedgEntry."Reversed by Entry No." <> 0 THEN
                    ERROR(Text015);
                TempCustLedgEntry := CustLedgEntry;
                TempCustLedgEntry.INSERT;
            UNTIL CustLedgEntry.NEXT = 0;
        IF VendLedgEntry.FINDSET THEN
            REPEAT
                IF VendLedgEntry."Reversed by Entry No." <> 0 THEN
                    ERROR(Text015);
                TempVendLedgEntry := VendLedgEntry;
                TempVendLedgEntry.INSERT;
            UNTIL VendLedgEntry.NEXT = 0;
        IF BankAccLedgEntry.FINDSET THEN
            REPEAT
                IF BankAccLedgEntry."Reversed by Entry No." <> 0 THEN
                    ERROR(Text015);
                TempBankAccLedgEntry := BankAccLedgEntry;
                TempBankAccLedgEntry.INSERT;
            UNTIL BankAccLedgEntry.NEXT = 0;

        IF TempRevertTransactionNo.FINDSET THEN;
        REPEAT
            IF ReversalEntry2."Reversal Type" = ReversalEntry2."Reversal Type"::Transaction THEN
                GLEntry2.SETRANGE("Transaction No.", TempRevertTransactionNo.Number);
            WITH GLEntry2 DO
                IF FIND('+') THEN
                    REPEAT
                        IF "Reversed by Entry No." <> 0 THEN
                            ERROR(Text015);
                        LedgEntryDim.SETRANGE("Table ID", DATABASE::"G/L Entry");
                        LedgEntryDim.SETRANGE("Entry No.", "Entry No.");
                        TempJnlLineDim.RESET;
                        TempJnlLineDim.DELETEALL;
                        DimMgt.CopyLedgEntryDimToJnlLineDim(LedgEntryDim, TempJnlLineDim);
                        IF NOT DimMgt.CheckJnlLineDimComb(TempJnlLineDim) THEN
                            ERROR(Text011, TABLECAPTION, "Entry No.", DimMgt.GetDimCombErr);
                        CLEAR(TableID);
                        CLEAR(AccNo);
                        TableID[1] := DATABASE::"G/L Account";
                        AccNo[1] := "G/L Account No.";
                        IF NOT DimMgt.CheckJnlLineDimValuePosting(TempJnlLineDim, TableID, AccNo) THEN
                            ERROR(DimMgt.GetDimValuePostingErr);
                        GLEntry := GLEntry2;
                        IF "FA Entry No." <> 0 THEN
                            FAInsertLedgEntry.InsertReverseEntry(
                              NextEntryNo, "FA Entry Type", "FA Entry No.", GLEntry."FA Entry No.", NextTransactionNo, ReversalEntry2);
                        GLEntry.Amount := -Amount;
                        GLEntry.Quantity := -Quantity;
                        GLEntry."VAT Amount" := -"VAT Amount";
                        GLEntry."Debit Amount" := -"Debit Amount";
                        GLEntry."Credit Amount" := -"Credit Amount";
                        GLEntry."Additional-Currency Amount" := -"Additional-Currency Amount";
                        GLEntry."Add.-Currency Debit Amount" := -"Add.-Currency Debit Amount";
                        GLEntry."Add.-Currency Credit Amount" := -"Add.-Currency Credit Amount";
                        GLEntry."Entry No." := NextEntryNo;
                        GLEntry."Transaction No." := NextTransactionNo;
                        GLEntry."User ID" := USERID;
                        GenJnlLine.Correction :=
                          (GLEntry."Debit Amount" < 0) OR (GLEntry."Credit Amount" < 0) OR
                          (GLEntry."Add.-Currency Debit Amount" < 0) OR (GLEntry."Add.-Currency Credit Amount" < 0);
                        GLEntry."Prior-Year Entry" := GLEntry."Posting Date" < FiscalYearStartDate;
                        GLEntry."Journal Batch Name" := '';
                        GLEntry."Source Code" := GenJnlLine."Source Code";
                        SetReversalDescription(
                          ReversalEntry."Entry Type"::"G/L Account", "Entry No.", ReversalEntry2, GLEntry.Description);
                        GLEntry."Reversed Entry No." := "Entry No.";
                        GLEntry.Reversed := TRUE;
                        GLEntry."Reason Code" := ReverseReason; //LG00.02
                                                                // Reversal of Reversal
                        IF "Reversed Entry No." <> 0 THEN BEGIN
                            ReversedGLEntry.GET(GLEntry2."Reversed Entry No.");
                            ReversedGLEntry."Reversed by Entry No." := 0;
                            ReversedGLEntry.Reversed := FALSE;
                            ReversedGLEntry.MODIFY;
                            "Reversed Entry No." := GLEntry."Entry No.";
                            GLEntry."Reversed by Entry No." := "Entry No.";
                        END;
                        "Reversed by Entry No." := GLEntry."Entry No.";
                        Reversed := TRUE;
                        MODIFY;
                        InsertGLEntry(FALSE);
                        ReversedGLEntryTemp := GLEntry;
                        ReversedGLEntryTemp.INSERT;

                        DimMgt.CopyLedgEntryDimToLedgEntryDim(
                          DATABASE::"G/L Entry", "Entry No.", DATABASE::"G/L Entry", GLEntry."Entry No.");

                        CASE TRUE OF
                            TempCustLedgEntry.GET("Entry No."):
                                BEGIN
                                    IF NOT DimMgt.CheckJnlLineDimComb(TempJnlLineDim) THEN
                                        ERROR(Text011, TABLECAPTION, "Entry No.", DimMgt.GetDimCombErr);
                                    CLEAR(TableID);
                                    CLEAR(AccNo);
                                    TableID[1] := DATABASE::Customer;
                                    AccNo[1] := TempCustLedgEntry."Customer No.";
                                    TableID[2] := DATABASE::"Salesperson/Purchaser";
                                    AccNo[2] := TempCustLedgEntry."Salesperson Code";
                                    IF NOT DimMgt.CheckJnlLineDimValuePosting(TempJnlLineDim, TableID, AccNo) THEN
                                        ERROR(DimMgt.GetDimValuePostingErr);
                                    ReverseCustLedgEntry(
                                      TempCustLedgEntry, GLEntry."Entry No.", GenJnlLine.Correction, NextDtldCustLedgEntryEntryNo, ReversalEntry2);
                                    TempCustLedgEntry.DELETE;
                                END;
                            TempVendLedgEntry.GET("Entry No."):
                                BEGIN
                                    IF NOT DimMgt.CheckJnlLineDimComb(TempJnlLineDim) THEN
                                        ERROR(Text011, TABLECAPTION, "Entry No.", DimMgt.GetDimCombErr);
                                    CLEAR(TableID);
                                    CLEAR(AccNo);
                                    TableID[1] := DATABASE::Vendor;
                                    AccNo[1] := TempVendLedgEntry."Vendor No.";
                                    TableID[2] := DATABASE::"Salesperson/Purchaser";
                                    AccNo[2] := TempVendLedgEntry."Purchaser Code";
                                    IF NOT DimMgt.CheckJnlLineDimValuePosting(TempJnlLineDim, TableID, AccNo) THEN
                                        ERROR(DimMgt.GetDimValuePostingErr);
                                    ReverseVendLedgEntry(
                                      TempVendLedgEntry, GLEntry."Entry No.", GenJnlLine.Correction, NextDtldVendLedgEntryEntryNo, ReversalEntry2);
                                    TempVendLedgEntry.DELETE;
                                END;
                            TempBankAccLedgEntry.GET("Entry No."):
                                BEGIN
                                    IF NOT DimMgt.CheckJnlLineDimComb(TempJnlLineDim) THEN
                                        ERROR(Text011, TABLECAPTION, "Entry No.", DimMgt.GetDimCombErr);
                                    CLEAR(TableID);
                                    CLEAR(AccNo);
                                    TableID[1] := DATABASE::"Bank Account";
                                    AccNo[1] := TempBankAccLedgEntry."Bank Account No.";
                                    IF NOT DimMgt.CheckJnlLineDimValuePosting(TempJnlLineDim, TableID, AccNo) THEN
                                        ERROR(DimMgt.GetDimValuePostingErr);
                                    ReverseBankAccLedgEntry(TempBankAccLedgEntry, GLEntry."Entry No.", ReversalEntry2);
                                    TempBankAccLedgEntry.DELETE;
                                END;
                        END;
                    UNTIL NEXT(-1) = 0;
        UNTIL TempRevertTransactionNo.NEXT = 0;

        IF FALedgEntry.FINDSET THEN
            REPEAT
                FAInsertLedgEntry.CheckFAReverseEntry(FALedgEntry)
            UNTIL FALedgEntry.NEXT = 0;

        IF MaintenanceLedgEntry.FINDSET THEN
            REPEAT
                FAInsertLedgEntry.CheckMaintReverseEntry(MaintenanceLedgEntry)
            UNTIL FALedgEntry.NEXT = 0;

        FAInsertLedgEntry.FinishFAReverseEntry(GLReg);

        IF NOT TempCustLedgEntry.ISEMPTY THEN
            ERROR(Text014, CustLedgEntry.TABLECAPTION, GLEntry.TABLECAPTION);
        IF NOT TempVendLedgEntry.ISEMPTY THEN
            ERROR(Text014, VendLedgEntry.TABLECAPTION, GLEntry.TABLECAPTION);
        IF NOT TempBankAccLedgEntry.ISEMPTY THEN
            ERROR(Text014, BankAccLedgEntry.TABLECAPTION, GLEntry.TABLECAPTION);

        IF ReversalEntry2."Reversal Type" = ReversalEntry2."Reversal Type"::Transaction THEN BEGIN
            TempRevertTransactionNo.FINDSET;
            REPEAT
                VATEntry.SETRANGE("Transaction No.", TempRevertTransactionNo.Number);
                ReverseVAT(VATEntry);
            UNTIL TempRevertTransactionNo.NEXT = 0;
        END ELSE
            ReverseVAT(VATEntry);

        TempJnlLineDim.DELETEALL;
        FinishCodeunit;

        IF GLReg2."No." <> 0 THEN
            IF GLReg2.GET(GLReg2."No.") THEN BEGIN
                GLReg2.Reversed := TRUE;
                GLReg2.MODIFY;
            END;

        UpdateAnalysisView.UpdateAll(0, TRUE);
    end;

    local procedure ReverseCustLedgEntry(CustLedgEntry: Record "21"; NewEntryNo: Integer; Correction: Boolean; var NextDtldCustLedgEntryEntryNo: Integer; var ReversalEntry: Record "179")
    var
        NewCustLedgEntry: Record "21";
        ReversedCustLedgEntry: Record "21";
        DtldCustLedgEntry: Record "379";
        NewDtldCustLedgEntry: Record "379";
    begin
        WITH NewCustLedgEntry DO BEGIN
            NewCustLedgEntry := CustLedgEntry;
            "Sales (LCY)" := -"Sales (LCY)";
            "Profit (LCY)" := -"Profit (LCY)";
            "Inv. Discount (LCY)" := -"Inv. Discount (LCY)";
            "Original Pmt. Disc. Possible" := -"Original Pmt. Disc. Possible";
            "Pmt. Disc. Given (LCY)" := -"Pmt. Disc. Given (LCY)";
            Positive := NOT Positive;
            "Adjusted Currency Factor" := -"Adjusted Currency Factor";
            "Original Currency Factor" := -"Original Currency Factor";
            "Remaining Pmt. Disc. Possible" := -"Remaining Pmt. Disc. Possible";
            "Max. Payment Tolerance" := -"Max. Payment Tolerance";
            "Accepted Payment Tolerance" := -"Accepted Payment Tolerance";
            "Pmt. Tolerance (LCY)" := -"Pmt. Tolerance (LCY)";
            "User ID" := USERID;
            "Entry No." := NewEntryNo;
            "Transaction No." := NextTransactionNo;
            "Journal Batch Name" := '';
            "Source Code" := GenJnlLine."Source Code";
            SetReversalDescription(
              ReversalEntry."Entry Type"::Customer, CustLedgEntry."Entry No.", ReversalEntry, Description);
            "Reversed Entry No." := CustLedgEntry."Entry No.";
            Reversed := TRUE;
            "Applies-to ID" := '';
            "Reason Code" := ReverseReason; //LG00.02
                                            // Reversal of Reversal
            IF CustLedgEntry."Reversed Entry No." <> 0 THEN BEGIN
                ReversedCustLedgEntry.GET(CustLedgEntry."Reversed Entry No.");
                ReversedCustLedgEntry."Reversed by Entry No." := 0;
                ReversedCustLedgEntry.Reversed := FALSE;
                ReversedCustLedgEntry.MODIFY;
                CustLedgEntry."Reversed Entry No." := "Entry No.";
                "Reversed by Entry No." := CustLedgEntry."Entry No.";
            END;
            CustLedgEntry."Applies-to ID" := '';
            CustLedgEntry."Reversed by Entry No." := "Entry No.";
            CustLedgEntry.Reversed := TRUE;
            CustLedgEntry.MODIFY;
            INSERT;

            //LG00.02 -
            IF CustLedgEntry."Ref. Document No." <> '' THEN
                ReverseAppliedAgrmtLines(CustLedgEntry."Document No.");
            //LG00.02 +


            IF NextDtldCustLedgEntryEntryNo = 0 THEN BEGIN
                DtldCustLedgEntry.FINDLAST;
                NextDtldCustLedgEntryEntryNo := DtldCustLedgEntry."Entry No." + 1;
            END;
            DtldCustLedgEntry.SETCURRENTKEY("Cust. Ledger Entry No.");
            DtldCustLedgEntry.SETRANGE("Cust. Ledger Entry No.", CustLedgEntry."Entry No.");
            DtldCustLedgEntry.SETRANGE(Unapplied, FALSE);
            DtldCustLedgEntry.FINDSET;
            REPEAT
                DtldCustLedgEntry.TESTFIELD("Entry Type", DtldCustLedgEntry."Entry Type"::"Initial Entry");
                NewDtldCustLedgEntry := DtldCustLedgEntry;
                NewDtldCustLedgEntry.Amount := -NewDtldCustLedgEntry.Amount;
                NewDtldCustLedgEntry."Amount (LCY)" := -NewDtldCustLedgEntry."Amount (LCY)";
                CustUpdateDebitCredit(Correction, NewDtldCustLedgEntry);
                NewDtldCustLedgEntry."Cust. Ledger Entry No." := NewEntryNo;
                NewDtldCustLedgEntry."User ID" := USERID;
                NewDtldCustLedgEntry."Transaction No." := NextTransactionNo;
                NewDtldCustLedgEntry."Entry No." := NextDtldCustLedgEntryEntryNo;
                NextDtldCustLedgEntryEntryNo := NextDtldCustLedgEntryEntryNo + 1;
                NewDtldCustLedgEntry.INSERT;
            UNTIL DtldCustLedgEntry.NEXT = 0;

            ApplyCustLedgEntryByReversal(
              CustLedgEntry, NewCustLedgEntry, NewDtldCustLedgEntry, "Entry No.", NextDtldCustLedgEntryEntryNo);
            ApplyCustLedgEntryByReversal(
              NewCustLedgEntry, CustLedgEntry, DtldCustLedgEntry, "Entry No.", NextDtldCustLedgEntryEntryNo);

            DimMgt.CopyLedgEntryDimToLedgEntryDim(
              DATABASE::"Cust. Ledger Entry", CustLedgEntry."Entry No.", DATABASE::"Cust. Ledger Entry", NewEntryNo);
        END;
    end;

    local procedure ReverseVendLedgEntry(VendLedgEntry: Record "25"; NewEntryNo: Integer; Correction: Boolean; var NextDtldVendLedgEntryEntryNo: Integer; var ReversalEntry: Record "179")
    var
        NewVendLedgEntry: Record "25";
        ReversedVendLedgEntry: Record "25";
        DtldVendLedgEntry: Record "380";
        NewDtldVendLedgEntry: Record "380";
    begin
        WITH NewVendLedgEntry DO BEGIN
            NewVendLedgEntry := VendLedgEntry;
            "Purchase (LCY)" := -"Purchase (LCY)";
            "Inv. Discount (LCY)" := -"Inv. Discount (LCY)";
            "Original Pmt. Disc. Possible" := -"Original Pmt. Disc. Possible";
            "Pmt. Disc. Rcd.(LCY)" := -"Pmt. Disc. Rcd.(LCY)";
            Positive := NOT Positive;
            "Adjusted Currency Factor" := -"Adjusted Currency Factor";
            "Original Currency Factor" := -"Original Currency Factor";
            "Remaining Pmt. Disc. Possible" := -"Remaining Pmt. Disc. Possible";
            "Max. Payment Tolerance" := -"Max. Payment Tolerance";
            "Accepted Payment Tolerance" := -"Accepted Payment Tolerance";
            "Pmt. Tolerance (LCY)" := -"Pmt. Tolerance (LCY)";
            "User ID" := USERID;
            "Entry No." := NewEntryNo;
            "Transaction No." := NextTransactionNo;
            "Journal Batch Name" := '';
            "Source Code" := GenJnlLine."Source Code";
            SetReversalDescription(
              ReversalEntry."Entry Type"::Vendor, VendLedgEntry."Entry No.", ReversalEntry, Description);
            "Reversed Entry No." := VendLedgEntry."Entry No.";
            Reversed := TRUE;
            "Applies-to ID" := '';
            // Reversal of Reversal
            IF VendLedgEntry."Reversed Entry No." <> 0 THEN BEGIN
                ReversedVendLedgEntry.GET(VendLedgEntry."Reversed Entry No.");
                ReversedVendLedgEntry."Reversed by Entry No." := 0;
                ReversedVendLedgEntry.Reversed := FALSE;
                ReversedVendLedgEntry.MODIFY;
                VendLedgEntry."Reversed Entry No." := "Entry No.";
                "Reversed by Entry No." := VendLedgEntry."Entry No.";
            END;
            VendLedgEntry."Applies-to ID" := '';
            VendLedgEntry."Reversed by Entry No." := "Entry No.";
            VendLedgEntry.Reversed := TRUE;
            VendLedgEntry.MODIFY;
            INSERT;

            IF NextDtldVendLedgEntryEntryNo = 0 THEN BEGIN
                DtldVendLedgEntry.FINDLAST;
                NextDtldVendLedgEntryEntryNo := DtldVendLedgEntry."Entry No." + 1;
            END;
            DtldVendLedgEntry.SETCURRENTKEY("Vendor Ledger Entry No.");
            DtldVendLedgEntry.SETRANGE("Vendor Ledger Entry No.", VendLedgEntry."Entry No.");
            DtldVendLedgEntry.SETRANGE(Unapplied, FALSE);
            DtldVendLedgEntry.FINDSET;
            REPEAT
                DtldVendLedgEntry.TESTFIELD("Entry Type", DtldVendLedgEntry."Entry Type"::"Initial Entry");
                NewDtldVendLedgEntry := DtldVendLedgEntry;
                NewDtldVendLedgEntry.Amount := -NewDtldVendLedgEntry.Amount;
                NewDtldVendLedgEntry."Amount (LCY)" := -NewDtldVendLedgEntry."Amount (LCY)";
                VendUpdateDebitCredit(Correction, NewDtldVendLedgEntry);
                NewDtldVendLedgEntry."Vendor Ledger Entry No." := NewEntryNo;
                NewDtldVendLedgEntry."User ID" := USERID;
                NewDtldVendLedgEntry."Transaction No." := NextTransactionNo;
                NewDtldVendLedgEntry."Entry No." := NextDtldVendLedgEntryEntryNo;
                NextDtldVendLedgEntryEntryNo := NextDtldVendLedgEntryEntryNo + 1;
                NewDtldVendLedgEntry.INSERT;
            UNTIL DtldVendLedgEntry.NEXT = 0;

            ApplyVendLedgEntryByReversal(
              VendLedgEntry, NewVendLedgEntry, NewDtldVendLedgEntry, "Entry No.", NextDtldVendLedgEntryEntryNo);
            ApplyVendLedgEntryByReversal(
              NewVendLedgEntry, VendLedgEntry, DtldVendLedgEntry, "Entry No.", NextDtldVendLedgEntryEntryNo);

            DimMgt.CopyLedgEntryDimToLedgEntryDim(
              DATABASE::"Vendor Ledger Entry", VendLedgEntry."Entry No.",
              DATABASE::"Vendor Ledger Entry", NewEntryNo);
        END;
    end;

    local procedure ReverseBankAccLedgEntry(BankAccLedgEntry: Record "271"; NewEntryNo: Integer; var ReversalEntry: Record "179")
    var
        NewBankAccLedgEntry: Record "271";
        ReversedBankAccLedgEntry: Record "271";
    begin
        WITH NewBankAccLedgEntry DO BEGIN
            NewBankAccLedgEntry := BankAccLedgEntry;
            Amount := -Amount;
            "Remaining Amount" := -"Remaining Amount";
            "Amount (LCY)" := -"Amount (LCY)";
            "Debit Amount" := -"Debit Amount";
            "Credit Amount" := -"Credit Amount";
            "Debit Amount (LCY)" := -"Debit Amount (LCY)";
            "Credit Amount (LCY)" := -"Credit Amount (LCY)";
            Positive := NOT Positive;
            "User ID" := USERID;
            "Entry No." := NewEntryNo;
            "Transaction No." := NextTransactionNo;
            "Journal Batch Name" := '';
            "Source Code" := GenJnlLine."Source Code";
            SetReversalDescription(
              ReversalEntry."Entry Type"::"Bank Account", BankAccLedgEntry."Entry No.", ReversalEntry, Description);
            "Reversed Entry No." := BankAccLedgEntry."Entry No.";
            Reversed := TRUE;
            "Reason Code" := ReverseReason; //LG00.02
                                            // Reversal of Reversal
            IF BankAccLedgEntry."Reversed Entry No." <> 0 THEN BEGIN
                ReversedBankAccLedgEntry.GET(BankAccLedgEntry."Reversed Entry No.");
                ReversedBankAccLedgEntry."Reversed by Entry No." := 0;
                ReversedBankAccLedgEntry.Reversed := FALSE;
                ReversedBankAccLedgEntry.MODIFY;
                BankAccLedgEntry."Reversed Entry No." := "Entry No.";
                "Reversed by Entry No." := BankAccLedgEntry."Entry No.";
            END;
            BankAccLedgEntry."Reversed by Entry No." := "Entry No.";
            BankAccLedgEntry.Reversed := TRUE;
            BankAccLedgEntry.MODIFY;
            INSERT;

            DimMgt.CopyLedgEntryDimToLedgEntryDim(
              DATABASE::"Bank Account Ledger Entry", BankAccLedgEntry."Entry No.",
              DATABASE::"Bank Account Ledger Entry", NewEntryNo);
        END;
    end;

    local procedure ReverseVAT(var VATEntry: Record "254")
    var
        NewVATEntry: Record "254";
        ReversedVATEntry: Record "254";
    begin
        IF VATEntry.FINDSET THEN
            REPEAT
                IF VATEntry."Reversed by Entry No." <> 0 THEN
                    ERROR(Text015);
                WITH NewVATEntry DO BEGIN
                    NewVATEntry := VATEntry;
                    Base := -Base;
                    Amount := -Amount;
                    "Unrealized Amount" := -"Unrealized Amount";
                    "Unrealized Base" := -"Unrealized Base";
                    "Remaining Unrealized Amount" := -"Remaining Unrealized Amount";
                    "Remaining Unrealized Base" := -"Remaining Unrealized Base";
                    "Additional-Currency Amount" := -"Additional-Currency Amount";
                    "Additional-Currency Base" := -"Additional-Currency Base";
                    "Add.-Currency Unrealized Amt." := -"Add.-Currency Unrealized Amt.";
                    "Add.-Curr. Rem. Unreal. Amount" := -"Add.-Curr. Rem. Unreal. Amount";
                    "Add.-Curr. Rem. Unreal. Base" := -"Add.-Curr. Rem. Unreal. Base";
                    "VAT Difference" := -"VAT Difference";
                    "Add.-Curr. VAT Difference" := -"Add.-Curr. VAT Difference";
                    "Transaction No." := NextTransactionNo;
                    "Source Code" := GenJnlLine."Source Code";
                    "User ID" := USERID;
                    "Entry No." := NextVATEntryNo;
                    "Reversed Entry No." := VATEntry."Entry No.";
                    Reversed := TRUE;
                    "Reason Code" := ReverseReason; //LG00.02
                                                    // Reversal of Reversal
                    IF VATEntry."Reversed Entry No." <> 0 THEN BEGIN
                        ReversedVATEntry.GET(VATEntry."Reversed Entry No.");
                        ReversedVATEntry."Reversed by Entry No." := 0;
                        ReversedVATEntry.Reversed := FALSE;
                        ReversedVATEntry.MODIFY;
                        VATEntry."Reversed Entry No." := "Entry No.";
                        "Reversed by Entry No." := VATEntry."Entry No.";
                    END;
                    VATEntry."Reversed by Entry No." := "Entry No.";
                    VATEntry.Reversed := TRUE;
                    VATEntry.MODIFY;
                    INSERT;
                    GLEntryVatEntrylink.SETRANGE("VAT Entry No.", VATEntry."Entry No.");
                    IF GLEntryVatEntrylink.FINDSET THEN
                        REPEAT
                            ReversedGLEntryTemp.SETRANGE("Reversed Entry No.", GLEntryVatEntrylink."G/L Entry No.");
                            IF ReversedGLEntryTemp.FINDFIRST THEN
                                GLEntryVatEntrylink.InsertLink(ReversedGLEntryTemp, NewVATEntry);
                        UNTIL GLEntryVatEntrylink.NEXT = 0;
                    NextVATEntryNo := NextVATEntryNo + 1;
                END;
            UNTIL VATEntry.NEXT = 0;
    end;

    local procedure SetReversalDescription(EntryType: Option " ","G/L Account",Customer,Vendor,"Bank Account","Fixed Asset",Maintenance,VAT; EntryNo: Integer; var ReversalEntry: Record "179"; var Description: Text[50])
    begin
        ReversalEntry.RESET;
        ReversalEntry.SETRANGE("Entry Type", EntryType);
        ReversalEntry.SETRANGE("Entry No.", EntryNo);
        IF ReversalEntry.FINDFIRST THEN
            Description := ReversalEntry.Description;
    end;

    local procedure ApplyCustLedgEntryByReversal(CustLedgEntry: Record "21"; CustLedgEntry2: Record "21"; DtldCustLedgEntry2: Record "379"; AppliedEntryNo: Integer; var NextDtldCustLedgEntryEntryNo: Integer)
    var
        NewDtldCustLedgEntry: Record "379";
    begin
        CustLedgEntry2.CALCFIELDS("Remaining Amount", "Remaining Amt. (LCY)");
        CustLedgEntry."Closed by Entry No." := CustLedgEntry2."Entry No.";
        CustLedgEntry."Closed at Date" := CustLedgEntry2."Posting Date";
        CustLedgEntry."Closed by Amount" := -CustLedgEntry2."Remaining Amount";
        CustLedgEntry."Closed by Amount (LCY)" := -CustLedgEntry2."Remaining Amt. (LCY)";
        CustLedgEntry."Closed by Currency Code" := CustLedgEntry2."Currency Code";
        CustLedgEntry."Closed by Currency Amount" := -CustLedgEntry2."Remaining Amount";
        CustLedgEntry.Open := FALSE;
        CustLedgEntry.MODIFY;

        NewDtldCustLedgEntry := DtldCustLedgEntry2;
        NewDtldCustLedgEntry."Cust. Ledger Entry No." := CustLedgEntry."Entry No.";
        NewDtldCustLedgEntry."Entry Type" := NewDtldCustLedgEntry."Entry Type"::Application;
        NewDtldCustLedgEntry."Applied Cust. Ledger Entry No." := AppliedEntryNo;
        NewDtldCustLedgEntry."User ID" := USERID;
        NewDtldCustLedgEntry."Transaction No." := NextTransactionNo;
        NewDtldCustLedgEntry."Entry No." := NextDtldCustLedgEntryEntryNo;
        NextDtldCustLedgEntryEntryNo := NextDtldCustLedgEntryEntryNo + 1;
        NewDtldCustLedgEntry.INSERT;
    end;

    local procedure ApplyVendLedgEntryByReversal(VendLedgEntry: Record "25"; VendLedgEntry2: Record "25"; DtldVendLedgEntry2: Record "380"; AppliedEntryNo: Integer; var NextDtldVendLedgEntryEntryNo: Integer)
    var
        NewDtldVendLedgEntry: Record "380";
    begin
        VendLedgEntry2.CALCFIELDS("Remaining Amount", "Remaining Amt. (LCY)");
        VendLedgEntry."Closed by Entry No." := VendLedgEntry2."Entry No.";
        VendLedgEntry."Closed at Date" := VendLedgEntry2."Posting Date";
        VendLedgEntry."Closed by Amount" := -VendLedgEntry2."Remaining Amount";
        VendLedgEntry."Closed by Amount (LCY)" := -VendLedgEntry2."Remaining Amt. (LCY)";
        VendLedgEntry."Closed by Currency Code" := VendLedgEntry2."Currency Code";
        VendLedgEntry."Closed by Currency Amount" := -VendLedgEntry2."Remaining Amount";
        VendLedgEntry.Open := FALSE;
        VendLedgEntry.MODIFY;

        NewDtldVendLedgEntry := DtldVendLedgEntry2;
        NewDtldVendLedgEntry."Vendor Ledger Entry No." := VendLedgEntry."Entry No.";
        NewDtldVendLedgEntry."Entry Type" := NewDtldVendLedgEntry."Entry Type"::Application;
        NewDtldVendLedgEntry."Applied Vend. Ledger Entry No." := AppliedEntryNo;
        NewDtldVendLedgEntry."User ID" := USERID;
        NewDtldVendLedgEntry."Transaction No." := NextTransactionNo;
        NewDtldVendLedgEntry."Entry No." := NextDtldVendLedgEntryEntryNo;
        NextDtldVendLedgEntryEntryNo := NextDtldVendLedgEntryEntryNo + 1;
        NewDtldVendLedgEntry.INSERT;
    end;

    procedure PostPmtDiscountVATByUnapply(ReverseChargeVATAccNo: Code[20]; VATAccNo: Code[20]; VATEntry: Record "254")
    begin
        InitGLEntry(ReverseChargeVATAccNo, VATEntry.Amount, 0, FALSE, TRUE);
        GLEntry."Additional-Currency Amount" :=
          CalcAddCurrForUnapplication(VATEntry."Posting Date", VATEntry.Amount);
        InsertGLEntry(TRUE);

        InitGLEntry(VATAccNo, -VATEntry.Amount, 0, FALSE, TRUE);
        GLEntry."Additional-Currency Amount" :=
          CalcAddCurrForUnapplication(VATEntry."Posting Date", -VATEntry.Amount);
        InsertGLEntry(TRUE);
    end;

    local procedure HandlDtlAddjustment(DebitAddjustment: Decimal; DebitAddjustmentAddCurr: Decimal; CreditAddjustment: Decimal; CreditAddjustmentAddCurr: Decimal; TotalAmountLCY: Decimal; TotalAmountAddCurr: Decimal; GLAcc: Code[20])
    var
        GLInitDone: Boolean;
    begin
        GLInitDone := FALSE;
        IF (TotalAmountLCY > 0) OR ((TotalAmountLCY = 0) AND (TotalAmountAddCurr > 0)) THEN BEGIN
            IF ((DebitAddjustment <> 0) OR (DebitAddjustmentAddCurr <> 0)) AND
               ((TotalAmountLCY + DebitAddjustment <> 0) OR (TotalAmountAddCurr + DebitAddjustmentAddCurr <> 0)) THEN BEGIN
                InitGLEntry(
                   GLAcc, -DebitAddjustment, -DebitAddjustmentAddCurr, TRUE, TRUE);
                GLEntry."Bal. Account Type" := GenJnlLine."Bal. Account Type";
                GLEntry."Bal. Account No." := GenJnlLine."Bal. Account No.";
                InsertGLEntry(TRUE);
                InitGLEntry(
                  GLAcc, TotalAmountLCY + DebitAddjustment,
                  TotalAmountAddCurr + DebitAddjustmentAddCurr, TRUE, TRUE);
                GLInitDone := TRUE;
            END;
        END ELSE
            IF TotalAmountLCY < 0 THEN BEGIN
                IF ((CreditAddjustment <> 0) OR (CreditAddjustmentAddCurr <> 0)) AND
                   ((TotalAmountLCY + CreditAddjustment <> 0) OR (TotalAmountAddCurr + CreditAddjustmentAddCurr <> 0)) THEN BEGIN
                    InitGLEntry(
                       GLAcc, -CreditAddjustment, -CreditAddjustmentAddCurr, TRUE, TRUE);
                    GLEntry."Bal. Account Type" := GenJnlLine."Bal. Account Type";
                    GLEntry."Bal. Account No." := GenJnlLine."Bal. Account No.";
                    InsertGLEntry(TRUE);
                    InitGLEntry(
                      GLAcc, TotalAmountLCY + CreditAddjustment,
                      TotalAmountAddCurr + CreditAddjustmentAddCurr, TRUE, TRUE);
                    GLInitDone := TRUE;
                END;
            END;

        IF NOT GLInitDone THEN
            InitGLEntry(GLAcc, TotalAmountLCY, TotalAmountAddCurr, TRUE, TRUE);
    end;

    local procedure CollectAddjustment(var DebitAddjustment: Decimal; var DebitAddjustmentAddCurr: Decimal; var CreditAddjustment: Decimal; var CreditAddjustmentAddCurr: Decimal; Amount: Decimal; AmountAddCurr: Decimal)
    begin
        IF (Amount > 0) OR ((Amount = 0) AND (AmountAddCurr > 0)) THEN BEGIN
            DebitAddjustment := DebitAddjustment + Amount;
            DebitAddjustmentAddCurr := DebitAddjustmentAddCurr + AmountAddCurr;
        END ELSE BEGIN
            CreditAddjustment := CreditAddjustment + Amount;
            CreditAddjustmentAddCurr := CreditAddjustmentAddCurr + AmountAddCurr;
        END;
    end;

    procedure SetOverDimErr()
    begin
        OverrideDimErr := TRUE;
    end;

    local procedure PostJob()
    begin
        IF JobLine THEN BEGIN
            JobLine := FALSE;
            JobPostLine.PostGenJnlLine(GenJnlLine, GLEntry, TempJnlLineDim);
        END;
    end;

    procedure InsertVatEntriesFromTemp(var DtldCVLedgEntryBuf: Record "383")
    var
        Complete: Boolean;
        LinkedAmount: Decimal;
    begin
        TempVatEntry.SETRANGE("Gen. Bus. Posting Group", GLEntry."Gen. Bus. Posting Group");
        TempVatEntry.SETRANGE("Gen. Prod. Posting Group", GLEntry."Gen. Prod. Posting Group");
        TempVatEntry.SETRANGE("VAT Bus. Posting Group", GLEntry."VAT Bus. Posting Group");
        TempVatEntry.SETRANGE("VAT Prod. Posting Group", GLEntry."VAT Prod. Posting Group");
        CASE DtldCVLedgEntryBuf."Entry Type" OF
            DtldCVLedgEntryBuf."Entry Type"::"Payment Discount (VAT Excl.)":
                TempVatEntry.SETRANGE("Entry No.", 0, 999999);
            DtldCVLedgEntryBuf."Entry Type"::"Payment Discount Tolerance (VAT Excl.)":
                TempVatEntry.SETRANGE("Entry No.", 1000000, 1999999);
            DtldCVLedgEntryBuf."Entry Type"::"Payment Tolerance (VAT Excl.)":
                TempVatEntry.SETRANGE("Entry No.", 2000000, 2999999)
        END;
        TempVatEntry.FINDSET;
        REPEAT
            VATEntry := TempVatEntry;
            VATEntry."Entry No." := NextVATEntryNo;
            VATEntry.INSERT;
            NextVATEntryNo := NextVATEntryNo + 1;
            IF VATEntry."Unrealized VAT Entry No." = 0 THEN
                GLEntryVatEntrylink.InsertLink(GLEntry, VATEntry);
            TempVatEntry.DELETE;
            LinkedAmount := LinkedAmount + VATEntry.Base;
            Complete := LinkedAmount = -DtldCVLedgEntryBuf."Amount (LCY)";
        UNTIL Complete OR (TempVatEntry.NEXT = 0);
    end;

    procedure ABSMin(Decimal1: Decimal; Decimal2: Decimal): Decimal
    begin
        IF ABS(Decimal1) < ABS(Decimal2) THEN
            EXIT(Decimal1);
        EXIT(Decimal2);
    end;

    procedure UpdateShortcutDimCodes(var GenJnl: Record "Gen. Journal Line"; var TempJnlLineDim2: Record "Gen. Journal Line Dimension")
    var
        TableID: Integer;
        DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order"," ";
        PurchInv: Record "122";
        DocNo: Code[20];
        Transfers: Record "60060";
        DefaultDim: Record "352";
    begin
        //APNT-HR1.0
        WITH GenJnl DO BEGIN
            GLSetup.GET;
            IF GLSetup."Shortcut Dimension 1 Code" <> '' THEN BEGIN
                IF DefaultDim.GET(DATABASE::Employee, '', GLSetup."Shortcut Dimension 1 Code") THEN
                    IF DefaultDim."Value Posting" = DefaultDim."Value Posting"::"Code Mandatory" THEN
                        TESTFIELD("Shortcut Dimension 1 Code");
                IF ("Shortcut Dimension 1 Code" <> '') AND
                   (NOT (TempJnlLineDim2.GET(81, "Journal Template Name", "Journal Batch Name", "Line No.", 0,
                    GLSetup."Shortcut Dimension 1 Code"))) THEN BEGIN
                    TempJnlLineDim2."Table ID" := DATABASE::"Gen. Journal Line";
                    TempJnlLineDim2."Journal Template Name" := "Journal Template Name";
                    TempJnlLineDim2."Journal Batch Name" := "Journal Batch Name";
                    TempJnlLineDim2."Journal Line No." := "Line No.";
                    TempJnlLineDim2."Dimension Code" := GLSetup."Shortcut Dimension 1 Code";
                    TempJnlLineDim2."Dimension Value Code" := "Shortcut Dimension 1 Code";
                    TempJnlLineDim2.INSERT;
                END;
            END;
            IF GLSetup."Shortcut Dimension 2 Code" <> '' THEN BEGIN
                IF DefaultDim.GET(DATABASE::Employee, '', GLSetup."Shortcut Dimension 2 Code") THEN
                    IF DefaultDim."Value Posting" = DefaultDim."Value Posting"::"Code Mandatory" THEN
                        TESTFIELD("Shortcut Dimension 2 Code");
                IF ("Shortcut Dimension 2 Code" <> '') AND
                   (NOT (TempJnlLineDim2.GET(81, "Journal Template Name", "Journal Batch Name", "Line No.", 0,
                    GLSetup."Shortcut Dimension 2 Code"))) THEN BEGIN
                    TempJnlLineDim2."Table ID" := DATABASE::"Gen. Journal Line";
                    TempJnlLineDim2."Journal Template Name" := "Journal Template Name";
                    TempJnlLineDim2."Journal Batch Name" := "Journal Batch Name";
                    TempJnlLineDim2."Journal Line No." := "Line No.";
                    TempJnlLineDim2."Dimension Code" := GLSetup."Shortcut Dimension 2 Code";
                    TempJnlLineDim2."Dimension Value Code" := "Shortcut Dimension 2 Code";
                    TempJnlLineDim2.INSERT;
                END;
            END;
        END;
        //APNT-HR1.0
    end;

    procedure PostSettlements()
    var
        Employee: Record "5200";
        DeductionLines: Record "60062";
        JnlLineDim: Record "Gen. Journal Line Dimension";
        LedgEntryDim: Record "355";
        EntryNo: Integer;
    begin
        WITH GenJnlLine DO BEGIN
            CASE "Payroll Type" OF
                "Payroll Type"::Deduction:
                    BEGIN
                        InsertPayrollGLEntries(GenJnlLine);
                        IF Amount < 0 THEN
                            EXIT;

                        Employee.GET("Employee No.");
                        Employee.TESTFIELD(Status, Employee.Status::Active);
                        DeductionLines.RESET;
                        IF DeductionLines.FINDLAST THEN
                            EntryNo := DeductionLines."Entry No." + 1
                        ELSE
                            EntryNo := 1;

                        DeductionLines.INIT;
                        DeductionLines."Entry No." := EntryNo;
                        DeductionLines."Document No." := "Document No.";
                        DeductionLines."Employee No." := "Employee No.";
                        DeductionLines.Name := Employee."First Name";
                        DeductionLines.Grade := Employee."Salary Grade";
                        DeductionLines.Description := Description;
                        DeductionLines."Shortcut Dimension 1 Code" := "Shortcut Dimension 1 Code";
                        DeductionLines."Shortcut Dimension 2 Code" := "Shortcut Dimension 2 Code";
                        IF "Payroll Type" = "Payroll Type"::Deduction THEN
                            DeductionLines.Amount := ABS(Amount)
                        ELSE
                            DeductionLines.Amount := -ABS(Amount);
                        DeductionLines."Document Type" := DeductionLines."Document Type"::" ";
                        DeductionLines."Account No." := "Account No.";
                        DeductionLines."Posting Date" := "Posting Date";
                        DeductionLines."Document No." := "Document No.";
                        DeductionLines."Posting Date" := "Document Date";
                        DeductionLines.Posted := TRUE;
                        DeductionLines."Payroll Parameter" := "Payroll Parameter";
                        DeductionLines."Document Type" := "Payroll Type";
                        DeductionLines.INSERT;

                        JnlLineDim.RESET;
                        JnlLineDim.SETRANGE("Table ID", DATABASE::"Gen. Journal Line");
                        JnlLineDim.SETRANGE("Journal Template Name", "Journal Template Name");
                        JnlLineDim.SETRANGE("Journal Batch Name", "Journal Batch Name");
                        JnlLineDim.SETRANGE("Journal Line No.", "Line No.");
                        IF JnlLineDim.FINDFIRST THEN
                            REPEAT
                                LedgEntryDim.INIT;
                                LedgEntryDim."Table ID" := DATABASE::"Deduction Entry Lines";
                                LedgEntryDim."Entry No." := DeductionLines."Entry No.";
                                LedgEntryDim."Dimension Code" := JnlLineDim."Dimension Code";
                                LedgEntryDim."Dimension Value Code" := JnlLineDim."Dimension Value Code";
                                LedgEntryDim.INSERT;
                            UNTIL JnlLineDim.NEXT = 0;
                    END;

                "Payroll Type"::"Re-imbursement", "Payroll Type"::Bonus, "Payroll Type"::Commission:
                    BEGIN
                        InsertPayrollGLEntries(GenJnlLine);
                        IF Amount > 0 THEN
                            EXIT;

                        Employee.GET("Employee No.");
                        Employee.TESTFIELD(Status, Employee.Status::Active);
                        DeductionLines.RESET;
                        IF DeductionLines.FINDLAST THEN
                            EntryNo := DeductionLines."Entry No." + 1
                        ELSE
                            EntryNo := 1;

                        DeductionLines.INIT;
                        DeductionLines."Entry No." := EntryNo;
                        DeductionLines."Document No." := "Document No.";
                        DeductionLines."Employee No." := "Employee No.";
                        DeductionLines.Name := Employee."First Name";
                        DeductionLines.Grade := Employee."Salary Grade";
                        DeductionLines.Description := Description;
                        DeductionLines."Shortcut Dimension 1 Code" := "Shortcut Dimension 1 Code";
                        DeductionLines."Shortcut Dimension 2 Code" := "Shortcut Dimension 2 Code";
                        IF "Payroll Type" = "Payroll Type"::Deduction THEN
                            DeductionLines.Amount := ABS(Amount)
                        ELSE
                            DeductionLines.Amount := -ABS(Amount);
                        IF "Payroll Type" = "Payroll Type"::"Re-imbursement" THEN
                            DeductionLines."Document Type" := DeductionLines."Document Type"::"Basic Salary"
                        ELSE
                            IF "Payroll Type" = "Payroll Type"::Deduction THEN
                                DeductionLines."Document Type" := DeductionLines."Document Type"::" ";
                        DeductionLines."Account No." := "Account No.";
                        DeductionLines."Posting Date" := "Posting Date";
                        DeductionLines."Document No." := "Document No.";
                        DeductionLines."Posting Date" := "Document Date";
                        DeductionLines.Posted := TRUE;
                        DeductionLines."Payroll Parameter" := "Payroll Parameter";
                        DeductionLines."Document Type" := "Payroll Type";

                        DeductionLines.INSERT;

                        JnlLineDim.RESET;
                        JnlLineDim.SETRANGE("Table ID", DATABASE::"Gen. Journal Line");
                        JnlLineDim.SETRANGE("Journal Template Name", "Journal Template Name");
                        JnlLineDim.SETRANGE("Journal Batch Name", "Journal Batch Name");
                        JnlLineDim.SETRANGE("Journal Line No.", "Line No.");
                        IF JnlLineDim.FINDFIRST THEN
                            REPEAT
                                LedgEntryDim.INIT;
                                LedgEntryDim."Table ID" := DATABASE::"Deduction Entry Lines";
                                LedgEntryDim."Entry No." := DeductionLines."Entry No.";
                                LedgEntryDim."Dimension Code" := JnlLineDim."Dimension Code";
                                LedgEntryDim."Dimension Value Code" := JnlLineDim."Dimension Value Code";
                                LedgEntryDim.INSERT;
                            UNTIL JnlLineDim.NEXT = 0;
                    END;
            END;
        END;
    end;

    procedure InsertPayrollGLEntries(PayrollJnlLine: Record "Gen. Journal Line")
    var
        Employee: Record "5200";
        PayrollGLEntries: Record "60040";
        EmpPostingGrp: Record "60016";
        HRSetup: Record "5218";
        JnlLineDim: Record "Gen. Journal Line Dimension";
        LedgEntryDim: Record "355";
    begin
        WITH PayrollJnlLine DO BEGIN
            HRSetup.GET;
            Employee.GET("Employee No.");
            IF NOT ("Payroll Type" IN ["Payroll Type"::Gratuity, "Payroll Type"::"Pension Payment"]) THEN
                Employee.TESTFIELD(Status, Employee.Status::Active);
            Employee.TESTFIELD("Employee Posting Group");
            IF "Posting Group" = '' THEN
                "Posting Group" := Employee."Employee Posting Group";

            PayrollGLEntries.LOCKTABLE;
            PayrollGLEntries.INIT;
            IF (("Payroll Type" = "Payroll Type"::Deduction) AND (Amount > 0)) OR
               (("Payroll Type" IN ["Payroll Type"::"Re-imbursement", "Payroll Type"::Bonus, "Payroll Type"::Commission]) AND (Amount < 0))
          THEN
                PayrollGLEntries."Employee No." := "Employee No.";
            PayrollGLEntries."Posting Date" := "Posting Date";
            PayrollGLEntries."Document Date" := "Document Date";
            PayrollGLEntries."Document Type" := "Payroll Type";
            PayrollGLEntries."Document No." := "Document No.";
            PayrollGLEntries."Account Type" := "Account Type";
            PayrollGLEntries."Account No." := "Account No.";
            PayrollGLEntries.Description := Description;
            PayrollGLEntries."Currency Code" := "Currency Code";
            PayrollGLEntries.Amount := Amount;
            PayrollGLEntries."Amount (LCY)" := "Amount (LCY)";
            IF PayrollGLEntries.Amount < 0 THEN BEGIN
                PayrollGLEntries."Credit Amount" := -PayrollGLEntries.Amount;
                PayrollGLEntries."Credit Amount (LCY)" := -PayrollGLEntries."Amount (LCY)";
            END ELSE BEGIN
                PayrollGLEntries."Debit Amount" := PayrollGLEntries.Amount;
                PayrollGLEntries."Debit Amount (LCY)" := PayrollGLEntries."Amount (LCY)";
            END;
            PayrollGLEntries."Employee Posting Group" := "Posting Group";
            PayrollGLEntries."Global Dimension 1 Code" := "Shortcut Dimension 1 Code";
            PayrollGLEntries."Global Dimension 2 Code" := "Shortcut Dimension 2 Code";
            PayrollGLEntries."User ID" := USERID;
            PayrollGLEntries."Source Code" := "Source Code";
            PayrollGLEntries."Reason Code" := "Reason Code";
            PayrollGLEntries."External Document No." := "External Document No.";
            PayrollGLEntries."Payroll Parameter" := "Payroll Parameter";
            PayrollGLEntries.INSERT(TRUE);
            PayrollGLEntries.Open := FALSE;
            PayrollGLEntries.MODIFY;

            JnlLineDim.RESET;
            JnlLineDim.SETRANGE("Table ID", DATABASE::"Gen. Journal Line");
            JnlLineDim.SETRANGE("Journal Template Name", "Journal Template Name");
            JnlLineDim.SETRANGE("Journal Batch Name", "Journal Batch Name");
            JnlLineDim.SETRANGE("Journal Line No.", "Line No.");
            IF JnlLineDim.FINDFIRST THEN
                REPEAT
                    LedgEntryDim.INIT;
                    LedgEntryDim."Table ID" := DATABASE::"Posted Payroll Statement Lines";
                    LedgEntryDim."Entry No." := PayrollGLEntries."Entry No.";
                    LedgEntryDim."Dimension Code" := JnlLineDim."Dimension Code";
                    LedgEntryDim."Dimension Value Code" := JnlLineDim."Dimension Value Code";
                    LedgEntryDim.INSERT;
                UNTIL JnlLineDim.NEXT = 0;
            PayrollGLEntries.INIT;
            IF (("Payroll Type" = "Payroll Type"::Deduction) AND (Amount > 0)) OR
               (("Payroll Type" IN ["Payroll Type"::"Re-imbursement", "Payroll Type"::Bonus, "Payroll Type"::Commission]) AND (Amount < 0))
          THEN
                //PayrollGLEntries."Employee No." := "Employee No.";
                PayrollGLEntries."Posting Date" := "Posting Date";
            PayrollGLEntries."Document Date" := "Document Date";
            PayrollGLEntries."Document Type" := "Payroll Type";
            PayrollGLEntries."Document No." := "Document No.";
            PayrollGLEntries."Account Type" := "Account Type";
            PayrollGLEntries."Account No." := "Account No.";
            PayrollGLEntries.Description := Description;
            PayrollGLEntries."Currency Code" := "Currency Code";
            PayrollGLEntries.Amount := Amount;
            PayrollGLEntries."Amount (LCY)" := "Amount (LCY)";
            IF PayrollGLEntries.Amount < 0 THEN BEGIN
                PayrollGLEntries."Credit Amount" := -PayrollGLEntries.Amount;
                PayrollGLEntries."Credit Amount (LCY)" := -PayrollGLEntries."Amount (LCY)";
            END ELSE BEGIN
                PayrollGLEntries."Debit Amount" := PayrollGLEntries.Amount;
                PayrollGLEntries."Debit Amount (LCY)" := PayrollGLEntries."Amount (LCY)";
            END;
            PayrollGLEntries."Employee Posting Group" := "Posting Group";
            PayrollGLEntries."Global Dimension 1 Code" := "Shortcut Dimension 1 Code";
            PayrollGLEntries."Global Dimension 2 Code" := "Shortcut Dimension 2 Code";
            PayrollGLEntries."User ID" := USERID;
            PayrollGLEntries."Source Code" := "Source Code";
            PayrollGLEntries."Reason Code" := "Reason Code";
            PayrollGLEntries."External Document No." := "External Document No.";
            PayrollGLEntries."Payroll Parameter" := "Payroll Parameter";
            PayrollGLEntries.INSERT(TRUE);
            PayrollGLEntries.Open := FALSE;
            PayrollGLEntries.MODIFY;

            JnlLineDim.RESET;
            JnlLineDim.SETRANGE("Table ID", DATABASE::"Gen. Journal Line");
            JnlLineDim.SETRANGE("Journal Template Name", "Journal Template Name");
            JnlLineDim.SETRANGE("Journal Batch Name", "Journal Batch Name");
            JnlLineDim.SETRANGE("Journal Line No.", "Line No.");
            IF JnlLineDim.FINDFIRST THEN
                REPEAT
                    LedgEntryDim.INIT;
                    LedgEntryDim."Table ID" := DATABASE::"Posted Payroll Statement Lines";
                    LedgEntryDim."Entry No." := PayrollGLEntries."Entry No.";
                    LedgEntryDim."Dimension Code" := JnlLineDim."Dimension Code";
                    LedgEntryDim."Dimension Value Code" := JnlLineDim."Dimension Value Code";
                    LedgEntryDim.INSERT;
                UNTIL JnlLineDim.NEXT = 0;

        END;
    end;

    procedure PostBonusAccruals()
    var
        DimensionValue: Record "349";
    begin
        WITH GenJnlLine DO BEGIN
            GLSetup.GET;
            DimensionValue.RESET;
            DimensionValue.SETRANGE("Dimension Code", GLSetup."Global Dimension 1 Code");
            DimensionValue.SETRANGE(Code, "Shortcut Dimension 1 Code");
            IF DimensionValue.FINDFIRST THEN BEGIN
                DimensionValue."Last Bonus Accrued Date" := "Last Bonus Accrued Date";
                DimensionValue.MODIFY;
            END;
        END;
    end;

    procedure ReverseAppliedAgrmtLines(RefDocumentNo: Code[20])
    var
        AgrmtAppliedEntries: Record "33016872";
        PaymentSchdule: Record "33016824";
    begin
        //LG00.02 -
        AgrmtAppliedEntries.SETRANGE("Document No.", RefDocumentNo);
        AgrmtAppliedEntries.SETRANGE("Entry Type", AgrmtAppliedEntries."Entry Type"::Posted);
        IF AgrmtAppliedEntries.FINDSET THEN BEGIN
            REPEAT
                AgrmtAppliedEntries."Entry Type" := AgrmtAppliedEntries."Entry Type"::Refund;
                AgrmtAppliedEntries.MODIFY(TRUE);

                PaymentSchdule.RESET;
                PaymentSchdule.SETRANGE("Agreement Type", AgrmtAppliedEntries."Ref. Document Type");
                PaymentSchdule.SETRANGE("Agreement No.", AgrmtAppliedEntries."Ref. Document No.");
                PaymentSchdule.SETRANGE("Agreement Line No.", AgrmtAppliedEntries."Ref. Document Line No.");
                PaymentSchdule.SETRANGE("Payment Schedule Line No.", AgrmtAppliedEntries."Payment Schedule Line No.");
                IF PaymentSchdule.FINDFIRST THEN BEGIN
                    PaymentSchdule."Amount Paid" := PaymentSchdule."Amount Paid" - AgrmtAppliedEntries."Applied Amount";
                    PaymentSchdule."Balance Amt." := PaymentSchdule."Balance Amt." + AgrmtAppliedEntries."Applied Amount";
                    PaymentSchdule.MODIFY;
                END;

            UNTIL AgrmtAppliedEntries.NEXT = 0;
        END;
        //LG00.02 +
    end;

    procedure GetAgrmtReverseReason(ReverseEntryRec: Record "179")
    var
        AgrmtReverseReason: Record "33016873";
    begin
        //LG00.02 -
        CLEAR(ReverseReason);
        AgrmtReverseReason.SETCURRENTKEY("Transaction No.", "Register No.");
        AgrmtReverseReason.SETRANGE("Transaction No.", ReverseEntryRec."Transaction No.");
        AgrmtReverseReason.SETRANGE("Register No.", ReverseEntryRec."G/L Register No.");
        IF AgrmtReverseReason.FINDFIRST THEN
            ReverseReason := AgrmtReverseReason."Reason Code";
        //LG00.02 +
    end;
}

