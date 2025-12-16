codeunit 33016802 "Payment Schedule Management"
{
    // DP6.01.02 HK 19SEP2013 : Code added to update due date for element with single line


    trigger OnRun()
    begin
    end;

    var
        Text001: Label 'Multiple Payment Term should be Yes for Agreement Type %1, Agreement No. %2';
        Text002: Label 'Payment Schedule Amount %1 must be equal to Agreement Original Amount %2';
        Text003: Label 'Agreement Status for Agreement Type %1 No. %2 must not be closed.';
        TotalPaymentLineRatio: Integer;
        Text004: Label 'No. of payment term lines defined must be equal to No. of Invoices  %1 for Agreement No. %2 and Agreement Line %3';
        Text005: Label 'Payment Schedule lines created for Agreement %1';
        PremiseMgtSetup: Record "33016826";

    procedure CreatePaymentScheduleLines(AgreementRec: Record "33016815")
    var
        PayScheduleLineRec: Record "33016824";
        PaymentScheduleLines: Record "33016824";
        AgreementLineRec: Record "33016816";
        PaymentCounter: Decimal;
        PaymentLinesRec: Record "33016817";
        ModifyAgreement: Boolean;
        Percentwise: Boolean;
        Amountwise: Boolean;
        Amt: Decimal;
        InstallAmt: Decimal;
        NoofPaymentTermLine: Integer;
        RatioWise: Boolean;
        TotalAmount: Decimal;
        Specificwise: Boolean;
        NoofDays: Integer;
        NoofPaymentTermLineRec: Integer;
        NoofDaysFormula: Text[10];
        MonthTotalNoofDays: Integer;
        NoofDaysFormula1: Text[30];
        CurrLineNo: Integer;
    begin
        PremiseMgtSetup.GET;
        IF AgreementRec."Agreement Status" = AgreementRec."Agreement Status"::Closed THEN
            ERROR(Text003, AgreementRec."Agreement Type", AgreementRec."No.");

        IF AgreementRec."Multiple Payment Terms" THEN
            WITH AgreementRec DO BEGIN

                PayScheduleLineRec.RESET;
                PayScheduleLineRec.SETRANGE("Agreement Type", "Agreement Type");
                PayScheduleLineRec.SETRANGE("Agreement No.", "No.");
                PayScheduleLineRec.SETFILTER("Posted Invoice No.", '');
                PayScheduleLineRec.DELETEALL;

                AgreementLineRec.RESET;
                AgreementLineRec.SETRANGE("Agreement Type", "Agreement Type");
                AgreementLineRec.SETRANGE("Agreement No.", "No.");
                IF AgreementLineRec.FINDSET THEN
                    REPEAT
                        AgreementLineRec.TESTFIELD("Payment Term Code");
                        AgreementLineRec.TESTFIELD("Start Date");
                        CLEAR(PaymentCounter);
                        CLEAR(ModifyAgreement);
                        CLEAR(Percentwise);
                        CLEAR(Amountwise);
                        CLEAR(RatioWise);
                        CLEAR(Specificwise);
                        CLEAR(NoofPaymentTermLine);
                        TotalAmount := 0;

                        PaymentLinesRec.RESET;
                        PaymentLinesRec.SETCURRENTKEY("Payment Term Code", "Element Type", "Line No.");
                        PaymentLinesRec.SETRANGE("Payment Term Code", AgreementLineRec."Payment Term Code");
                        PaymentLinesRec.SETRANGE("Element Type", AgreementLineRec."Element Type");
                        NoofPaymentTermLine := PaymentLinesRec.COUNT;
                        IF NoofPaymentTermLine <> AgreementLineRec."No. of Invoices" THEN
                            ERROR(Text004, AgreementLineRec."No. of Invoices", AgreementLineRec."Agreement No.", AgreementLineRec."Line No.");

                        IF PaymentLinesRec.FINDFIRST THEN BEGIN
                            CurrLineNo := 0;
                            IF PaymentLinesRec."Calculation Type" = PaymentLinesRec."Calculation Type"::Ratio THEN
                                RatioWise := TRUE
                            ELSE
                                IF PaymentLinesRec."Calculation Type" = PaymentLinesRec."Calculation Type"::Amount THEN
                                    Amountwise := TRUE
                                ELSE
                                    IF PaymentLinesRec."Calculation Type" = PaymentLinesRec."Calculation Type"::Percentage THEN
                                        Percentwise := TRUE
                                    ELSE
                                        IF PaymentLinesRec."Calculation Type" = PaymentLinesRec."Calculation Type"::Specific THEN
                                            Specificwise := TRUE;

                            PayScheduleLineRec.RESET;
                            PayScheduleLineRec.SETRANGE("Agreement Type", "Agreement Type");
                            PayScheduleLineRec.SETRANGE("Agreement No.", "No.");
                            PayScheduleLineRec.SETRANGE("Agreement Line No.", AgreementLineRec."Line No.");
                            IF PayScheduleLineRec.FINDLAST THEN
                                PaymentCounter := PayScheduleLineRec."Payment Schedule Line No."
                            ELSE
                                PaymentCounter := 0;

                            //Ratio Basis
                            IF RatioWise THEN BEGIN
                                CLEAR(TotalPaymentLineRatio);
                                TotalPaymentLineRatio := GetTotalRatio(PaymentLinesRec);
                                REPEAT
                                    PaymentCounter += 10000;
                                    PaymentScheduleLines.INIT;
                                    PaymentScheduleLines."Agreement Type" := AgreementLineRec."Agreement Type";
                                    PaymentScheduleLines."Agreement No." := AgreementLineRec."Agreement No.";
                                    PaymentScheduleLines."Agreement Line No." := AgreementLineRec."Line No.";
                                    PaymentScheduleLines."Payment Schedule Line No." := PaymentCounter;
                                    PaymentScheduleLines."Calculation Date" := AgreementLineRec."Start Date";
                                    PaymentScheduleLines.Description := PaymentLinesRec.Description;
                                    PaymentScheduleLines."Payment %" := PaymentLinesRec.Percentage;
                                    IF TotalPaymentLineRatio <> 0 THEN BEGIN
                                        IF PremiseMgtSetup."Rounding Type" = PremiseMgtSetup."Rounding Type"::Up THEN
                                            PaymentScheduleLines."Invoice Due Amt." :=
                                               ROUND((AgreementLineRec."Original Amount" * PaymentLinesRec.Value / TotalPaymentLineRatio),
                                                PremiseMgtSetup."Rounding Precision", '>')
                                        ELSE
                                            IF PremiseMgtSetup."Rounding Type" = PremiseMgtSetup."Rounding Type"::Nearest THEN
                                                PaymentScheduleLines."Invoice Due Amt." :=
                                                   ROUND((AgreementLineRec."Original Amount" * PaymentLinesRec.Value / TotalPaymentLineRatio),
                                                    PremiseMgtSetup."Rounding Precision", '=')
                                            ELSE
                                                PaymentScheduleLines."Invoice Due Amt." :=
                                                   ROUND((AgreementLineRec."Original Amount" * PaymentLinesRec.Value / TotalPaymentLineRatio),
                                                    PremiseMgtSetup."Rounding Precision", '<')
                                    END ELSE
                                        PaymentScheduleLines."Invoice Due Amt." := 0;
                                    PaymentScheduleLines."Due Date" := CALCDATE(PaymentLinesRec."Due Date Calculation", AgreementLineRec."Start Date");
                                    PaymentScheduleLines."Payment Term Code" := AgreementLineRec."Payment Term Code";
                                    PaymentScheduleLines."Due Date Calculation" := PaymentLinesRec."Due Date Calculation";
                                    PaymentScheduleLines."Element Type" := AgreementLineRec."Element Type";
                                    PaymentScheduleLines."Balance Amt." := PaymentScheduleLines."Invoice Due Amt.";
                                    PaymentScheduleLines.INSERT(TRUE);
                                    ModifyAgreement := TRUE;
                                UNTIL PaymentLinesRec.NEXT = 0;
                            END;

                            //Percent Basis
                            IF Percentwise THEN BEGIN
                                REPEAT
                                    PaymentCounter += 10000;
                                    PaymentScheduleLines.INIT;
                                    PaymentScheduleLines."Agreement Type" := AgreementLineRec."Agreement Type";
                                    PaymentScheduleLines."Agreement No." := AgreementLineRec."Agreement No.";
                                    PaymentScheduleLines."Agreement Line No." := AgreementLineRec."Line No.";
                                    PaymentScheduleLines."Payment Schedule Line No." := PaymentCounter;
                                    PaymentScheduleLines."Calculation Date" := AgreementLineRec."Start Date";
                                    PaymentScheduleLines.Description := PaymentLinesRec.Description;
                                    PaymentScheduleLines."Payment %" := PaymentLinesRec.Percentage;
                                    IF PremiseMgtSetup."Rounding Type" = PremiseMgtSetup."Rounding Type"::Up THEN
                                        PaymentScheduleLines."Invoice Due Amt." :=
                                           ROUND((AgreementLineRec."Original Amount" * PaymentLinesRec.Value / 100), PremiseMgtSetup."Rounding Precision", '>')
                                    ELSE
                                        IF PremiseMgtSetup."Rounding Type" = PremiseMgtSetup."Rounding Type"::Nearest THEN
                                            PaymentScheduleLines."Invoice Due Amt." :=
                                               ROUND((AgreementLineRec."Original Amount" * PaymentLinesRec.Value / 100), PremiseMgtSetup."Rounding Precision", '=')
                                        ELSE
                                            IF PremiseMgtSetup."Rounding Type" = PremiseMgtSetup."Rounding Type"::Down THEN
                                                PaymentScheduleLines."Invoice Due Amt." :=
                                                   ROUND((AgreementLineRec."Original Amount" * PaymentLinesRec.Value / 100), PremiseMgtSetup."Rounding Precision", '<');
                                    PaymentScheduleLines."Due Date" := CALCDATE(PaymentLinesRec."Due Date Calculation", AgreementLineRec."Start Date");
                                    PaymentScheduleLines."Payment Term Code" := AgreementLineRec."Payment Term Code";
                                    PaymentScheduleLines."Due Date Calculation" := PaymentLinesRec."Due Date Calculation";
                                    PaymentScheduleLines."Element Type" := AgreementLineRec."Element Type";
                                    PaymentScheduleLines."Balance Amt." := PaymentScheduleLines."Invoice Due Amt.";
                                    PaymentScheduleLines.INSERT(TRUE);
                                    ModifyAgreement := TRUE;
                                UNTIL PaymentLinesRec.NEXT = 0;
                            END;

                            //Amountwise
                            IF Amountwise THEN BEGIN
                                CLEAR(Amt);
                                REPEAT
                                    Amt += PaymentLinesRec.Value;
                                UNTIL PaymentLinesRec.NEXT = 0;
                                IF Amt <> AgreementLineRec."Original Amount" THEN
                                    ERROR(Text002, Amt, AgreementLineRec."Original Amount");
                                IF PaymentLinesRec.FINDFIRST THEN
                                    REPEAT
                                        PaymentCounter += 10000;
                                        PaymentScheduleLines.INIT;
                                        PaymentScheduleLines."Agreement Type" := AgreementLineRec."Agreement Type";
                                        PaymentScheduleLines."Agreement No." := AgreementLineRec."Agreement No.";
                                        PaymentScheduleLines."Agreement Line No." := AgreementLineRec."Line No.";
                                        PaymentScheduleLines."Payment Schedule Line No." := PaymentCounter;
                                        PaymentScheduleLines."Calculation Date" := AgreementLineRec."Start Date";
                                        PaymentScheduleLines.Description := PaymentLinesRec.Description;
                                        PaymentScheduleLines."Payment %" := PaymentLinesRec.Percentage;
                                        PaymentScheduleLines."Invoice Due Amt." := PaymentLinesRec.Value;
                                        PaymentScheduleLines."Due Date" := CALCDATE(PaymentLinesRec."Due Date Calculation", AgreementLineRec."Start Date");
                                        PaymentScheduleLines."Payment Term Code" := AgreementLineRec."Payment Term Code";
                                        PaymentScheduleLines."Due Date Calculation" := PaymentLinesRec."Due Date Calculation";
                                        PaymentScheduleLines."Element Type" := AgreementLineRec."Element Type";
                                        PaymentScheduleLines."Balance Amt." := PaymentScheduleLines."Invoice Due Amt.";
                                        PaymentScheduleLines.INSERT(TRUE);
                                        ModifyAgreement := TRUE;
                                    UNTIL PaymentLinesRec.NEXT = 0;
                            END;
                        END;

                        //Specific Type Basis
                        IF Specificwise THEN BEGIN
                            CLEAR(NoofPaymentTermLineRec);
                            CLEAR(NoofDays);
                            CLEAR(NoofDaysFormula);

                            IF NoofPaymentTermLine > 1 THEN BEGIN
                                IF AgreementRec."Agreement Start Date" <> CALCDATE('-CM', "Agreement Start Date") THEN
                                    NoofPaymentTermLineRec := NoofPaymentTermLine - 1
                                ELSE
                                    NoofPaymentTermLineRec := NoofPaymentTermLine;
                            END ELSE
                                NoofPaymentTermLineRec := 1;
                            CurrLineNo := PaymentLinesRec."Line No.";
                            REPEAT
                                CLEAR(MonthTotalNoofDays);
                                CLEAR(NoofDaysFormula1);
                                PaymentCounter += 10000;
                                PaymentScheduleLines.INIT;
                                PaymentScheduleLines."Agreement Type" := AgreementLineRec."Agreement Type";
                                PaymentScheduleLines."Agreement No." := AgreementLineRec."Agreement No.";
                                PaymentScheduleLines."Agreement Line No." := AgreementLineRec."Line No.";
                                PaymentScheduleLines."Payment Schedule Line No." := PaymentCounter;
                                PaymentScheduleLines."Payment Term Code" := AgreementLineRec."Payment Term Code";
                                PaymentScheduleLines."Calculation Date" := AgreementLineRec."Start Date";
                                PaymentScheduleLines."Due Date Calculation" := PaymentLinesRec."Due Date Calculation";
                                PaymentScheduleLines."Element Type" := AgreementLineRec."Element Type";
                                IF PaymentLinesRec."Line No." = CurrLineNo THEN BEGIN
                                    NoofDays := (CALCDATE('CM', AgreementLineRec."Start Date") - PaymentScheduleLines."Calculation Date") + 1;
                                    NoofDaysFormula := FORMAT(NoofDays) + 'D';
                                    PaymentScheduleLines."Due Date" := CALCDATE('CM', AgreementLineRec."Start Date");
                                END ELSE BEGIN
                                    NoofDaysFormula1 := NoofDaysFormula + '+' + FORMAT(PaymentLinesRec."Due Date Calculation");
                                    PaymentScheduleLines."Due Date" :=
                                     CALCDATE('CM', CALCDATE(PaymentScheduleLines."Due Date Calculation", PaymentScheduleLines."Calculation Date"));
                                    NoofDays := (PaymentScheduleLines."Due Date" - CALCDATE('-CM', PaymentScheduleLines."Due Date")) + 1;
                                END;
                                MonthTotalNoofDays :=
                                  (CALCDATE('CM', PaymentScheduleLines."Due Date") - CALCDATE('-CM', PaymentScheduleLines."Due Date")) + 1;
                                IF MonthTotalNoofDays <> 0 THEN
                                    PaymentScheduleLines."Payment %" := ((1 / NoofPaymentTermLineRec) * 100 * NoofDays) / MonthTotalNoofDays
                                ELSE
                                    PaymentScheduleLines."Payment %" := ((1 / NoofPaymentTermLineRec) * 100 * NoofDays) / 31;

                                PaymentScheduleLines.Description := PaymentLinesRec.Description;
                                IF PremiseMgtSetup."Rounding Type" = PremiseMgtSetup."Rounding Type"::Up THEN
                                    PaymentScheduleLines."Invoice Due Amt." :=
                                       ROUND((AgreementLineRec."Original Amount" *
                                        PaymentScheduleLines."Payment %" / 100), PremiseMgtSetup."Rounding Precision", '>')
                                ELSE
                                    IF PremiseMgtSetup."Rounding Type" = PremiseMgtSetup."Rounding Type"::Nearest THEN
                                        PaymentScheduleLines."Invoice Due Amt." :=
                                           ROUND((AgreementLineRec."Original Amount" *
                                           PaymentScheduleLines."Payment %" / 100), PremiseMgtSetup."Rounding Precision", '=')
                                    ELSE
                                        IF PremiseMgtSetup."Rounding Type" = PremiseMgtSetup."Rounding Type"::Down THEN
                                            PaymentScheduleLines."Invoice Due Amt." :=
                                               ROUND((AgreementLineRec."Original Amount" *
                                                PaymentScheduleLines."Payment %" / 100), PremiseMgtSetup."Rounding Precision", '<');
                                PaymentScheduleLines."Balance Amt." := PaymentScheduleLines."Invoice Due Amt.";
                                PaymentScheduleLines.INSERT(TRUE);
                                ModifyAgreement := TRUE;
                            UNTIL PaymentLinesRec.NEXT = 0;
                        END;
                        //Specific type basis

                        PaymentScheduleLines.RESET;
                        PaymentScheduleLines.SETCURRENTKEY(
                          "Agreement Type", "Agreement No.", "Agreement Line No.", "Payment Term Code", "Calculation Date", "Payment Schedule Line No.");
                        PaymentScheduleLines.SETRANGE("Agreement Type", AgreementLineRec."Agreement Type");
                        PaymentScheduleLines.SETRANGE("Agreement No.", AgreementLineRec."Agreement No.");
                        PaymentScheduleLines.SETRANGE("Agreement Line No.", AgreementLineRec."Line No.");
                        IF PaymentScheduleLines.FINDSET THEN BEGIN
                            REPEAT
                                TotalAmount += PaymentScheduleLines."Invoice Due Amt.";
                            UNTIL PaymentScheduleLines.NEXT = 0;
                        END;

                        IF PaymentScheduleLines.FINDLAST THEN BEGIN
                            //DP6.01.02 START
                            IF NoofPaymentTermLine = 1 THEN
                                PaymentScheduleLines."Due Date" := CALCDATE(
                                  PaymentScheduleLines."Due Date Calculation", AgreementRec."Agreement Start Date")
                            ELSE
                                //DP6.01.02 STOP
                                PaymentScheduleLines."Due Date" := AgreementRec."Agreement End Date";
                            PaymentScheduleLines."Invoice Due Amt." :=
                              PaymentScheduleLines."Invoice Due Amt." + (AgreementLineRec."Original Amount" - TotalAmount);
                            IF AgreementLineRec."Original Amount" <> 0 THEN
                                PaymentScheduleLines."Payment %" := PaymentScheduleLines."Invoice Due Amt." / AgreementLineRec."Original Amount" * 100;
                            PaymentScheduleLines."Balance Amt." := PaymentScheduleLines."Invoice Due Amt.";
                            PaymentScheduleLines.MODIFY;
                        END;
                        IF ModifyAgreement THEN BEGIN
                            AgreementLineRec."Payment Schd Line" := TRUE;
                            AgreementLineRec.MODIFY;
                        END;
                    UNTIL AgreementLineRec.NEXT = 0;
            END
        ELSE
            MESSAGE(Text001, AgreementRec."Agreement Type", AgreementRec."No.");
    end;

    procedure OpenPaymentScheduleLines(AgreementLine: Record "33016816")
    var
        PaymentScheduleRec: Record "33016824";
        PaymentScheduleForm: Form "33016851";
        AgreementHeader: Record "33016815";
    begin
        PaymentScheduleRec.RESET;
        PaymentScheduleRec.SETRANGE("Agreement Type", AgreementLine."Agreement Type");
        PaymentScheduleRec.SETRANGE("Agreement No.", AgreementLine."Agreement No.");
        PaymentScheduleRec.SETRANGE("Agreement Line No.", AgreementLine."Line No.");
        PaymentScheduleRec.SETRANGE("Payment Term Code", AgreementLine."Payment Term Code");
        PaymentScheduleRec.SETRANGE("Calculation Date", AgreementLine."Start Date");
        PaymentScheduleForm.SETTABLEVIEW(PaymentScheduleRec);
        AgreementHeader.GET(AgreementLine."Agreement Type", AgreementLine."Agreement No.");
        IF AgreementHeader."Approval Status" = AgreementHeader."Approval Status"::Open THEN
            PaymentScheduleForm.EDITABLE(TRUE)
        ELSE
            PaymentScheduleForm.EDITABLE(FALSE);
        PaymentScheduleForm.RUNMODAL;
    end;

    procedure GetTotalRatio(PaymentTermLine: Record "33016817"): Decimal
    var
        PaymentTermLine1: Record "33016817";
        TotalRatio: Integer;
    begin
        PaymentTermLine1.RESET;
        PaymentTermLine1.SETRANGE("Payment Term Code", PaymentTermLine."Payment Term Code");
        PaymentTermLine1.SETRANGE("Element Type", PaymentTermLine."Element Type");
        IF PaymentTermLine1.FINDSET(FALSE, FALSE) THEN BEGIN
            REPEAT
                TotalRatio += PaymentTermLine1.Value;
            UNTIL PaymentTermLine1.NEXT = 0;
        END;

        EXIT(TotalRatio);
    end;
}

