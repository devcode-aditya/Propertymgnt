table 33016817 "Payment Term Line"
{
    Caption = 'Payment Term Line';
    DrillDownFormID = Form33016850;
    LookupFormID = Form33016850;

    fields
    {
        field(1; "Payment Term Code"; Code[10])
        {
            NotBlank = true;
            TableRelation = "Payment Terms";
        }
        field(2; "Element Type"; Code[20])
        {
            NotBlank = true;
            TableRelation = "Agreement Element".Code;

            trigger OnValidate()
            var
                AgreementElement: Record "Agreement Element";
            begin
                IF AgreementElement.GET("Element Type") THEN
                    Description := AgreementElement.Description
                ELSE
                    Description := '';
            end;
        }
        field(3; "Line No."; Integer)
        {
        }
        field(4; "Due Date Calculation"; DateFormula)
        {
        }
        field(5; Description; Text[50])
        {
        }
        field(6; "Calculation Type"; Option)
        {
            OptionCaption = 'Ratio,Amount,Percentage,Specific';
            OptionMembers = Ratio,Amount,Percentage,Specific;

            trigger OnValidate()
            begin
                IF "Calculation Type" <> xRec."Calculation Type" THEN BEGIN
                    Rec.Value := 0;
                    Rec.Percentage := 0;
                END;

                CheckElementLines;

                IF "Calculation Type" = "Calculation Type"::Specific THEN
                    Value := 1
                ELSE
                    Value := 0;
            end;
        }
        field(7; Value; Integer)
        {
            MinValue = 0;

            trigger OnValidate()
            var
                TermLineRec: Record "Payment Term Line";
                TotalPercent: Decimal;
            begin
                IF ("Calculation Type" <> "Calculation Type"::Amount) AND (Value > 100) THEN
                    ERROR(Text003, "Calculation Type");

                IF "Calculation Type" = "Calculation Type"::Amount THEN BEGIN
                    IF Value <> 0 THEN
                        Percentage := 100
                    ELSE
                        Percentage := 0;
                END;

                IF "Calculation Type" = "Calculation Type"::Percentage THEN BEGIN
                    IF Value <> 0 THEN
                        Percentage := Value
                    ELSE
                        Percentage := 0;
                END;

                IF "Calculation Type" = "Calculation Type"::Ratio THEN BEGIN
                    IF Value = 0 THEN
                        Percentage := 0;
                END;

                CheckElementLines;

                IF "Calculation Type" = "Calculation Type"::Percentage THEN BEGIN
                    CLEAR(TotalPercent);
                    TermLineRec.RESET;
                    TermLineRec.SETRANGE("Payment Term Code", "Payment Term Code");
                    TermLineRec.SETRANGE("Element Type", "Element Type");
                    TermLineRec.SETRANGE("Calculation Type", TermLineRec."Calculation Type"::Percentage);
                    TermLineRec.SETFILTER(TermLineRec."Line No.", '<>%1', "Line No.");
                    IF TermLineRec.FINDSET THEN BEGIN
                        REPEAT
                            TotalPercent += TermLineRec.Value;
                        UNTIL TermLineRec.NEXT = 0;
                        IF TotalPercent = 100 THEN
                            ERROR(Text001, "Element Type", "Payment Term Code");
                        IF (TotalPercent + Value) > 100 THEN
                            ERROR(Text002, (100 - TotalPercent), "Element Type", "Payment Term Code");
                    END;
                END;
            end;
        }
        field(8; Percentage; Decimal)
        {
            Editable = false;

            trigger OnLookup()
            var
                TotalPercent: Decimal;
            begin
            end;
        }
    }

    keys
    {
        key(Key1; "Payment Term Code", "Element Type", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    var
        TermLineRec: Record "Payment Term Line";
    begin
        VALIDATE("Element Type");

        IF "Line No." = 0 THEN BEGIN
            TermLineRec.RESET;
            TermLineRec.SETRANGE("Payment Term Code", "Payment Term Code");
            TermLineRec.SETRANGE("Element Type", "Element Type");
            TermLineRec.SETFILTER("Line No.", '>%1', 0);
            IF TermLineRec.FINDLAST THEN
                "Line No." := TermLineRec."Line No.";
            "Line No." := "Line No." + 10000;
        END;
    end;

    trigger OnRename()
    begin
        VALIDATE("Element Type");
    end;

    var
        Text001: Label 'Sum of Payment Term Lines is already 100 percent for the Element %1 in Payment Term %2';
        Text002: Label 'You can only define Payment Terms Lines with %1 percent for the Element %2 in Payment Term %3';
        Text003: Label 'Value cannot be greater than 100 for Calculation Type %1';
        Text33016835: Label 'Calculation Type for Payment term = %1,Element type = %2 and Line No = %3 must be %4';

    procedure CalculatePaymentRatio()
    var
        PaymentTermLine: Record "Payment Term Line";
        TotalRatio: Integer;
        TempPaymentTermLine: Record "Payment Term Line" temporary;
        PremiseMgtSetup: Record "Premise Management Setup";
        TotalPercentage: Decimal;
    begin
        PremiseMgtSetup.GET;
        TempPaymentTermLine.DELETEALL;

        PaymentTermLine.RESET;
        PaymentTermLine.SETRANGE("Payment Term Code", "Payment Term Code");
        IF PaymentTermLine.FINDSET THEN BEGIN
            REPEAT
                TempPaymentTermLine.RESET;
                TempPaymentTermLine.SETRANGE("Payment Term Code", PaymentTermLine."Payment Term Code");
                TempPaymentTermLine.SETRANGE("Element Type", PaymentTermLine."Element Type");
                IF NOT TempPaymentTermLine.FINDFIRST THEN BEGIN
                    TempPaymentTermLine.INIT;
                    TempPaymentTermLine := PaymentTermLine;
                    TempPaymentTermLine.INSERT;
                END;
            UNTIL PaymentTermLine.NEXT = 0;
        END;

        TempPaymentTermLine.RESET;
        TempPaymentTermLine.SETRANGE("Payment Term Code", "Payment Term Code");
        IF TempPaymentTermLine.FINDSET THEN
            REPEAT
                IF TempPaymentTermLine."Calculation Type" = TempPaymentTermLine."Calculation Type"::Ratio THEN BEGIN
                    TotalRatio := 0;
                    TotalPercentage := 0;
                    PaymentTermLine.RESET;
                    PaymentTermLine.SETRANGE("Payment Term Code", TempPaymentTermLine."Payment Term Code");
                    PaymentTermLine.SETRANGE("Element Type", TempPaymentTermLine."Element Type");
                    IF PaymentTermLine.FINDSET THEN BEGIN
                        REPEAT
                            TotalRatio += PaymentTermLine.Value;
                        UNTIL PaymentTermLine.NEXT = 0;
                    END;

                    IF TotalRatio <> 0 THEN BEGIN
                        PaymentTermLine.RESET;
                        PaymentTermLine.SETRANGE("Payment Term Code", TempPaymentTermLine."Payment Term Code");
                        PaymentTermLine.SETRANGE("Element Type", TempPaymentTermLine."Element Type");
                        IF PaymentTermLine.FINDSET THEN BEGIN
                            REPEAT
                                IF PremiseMgtSetup."Rounding Type" = PremiseMgtSetup."Rounding Type"::Up THEN
                                    PaymentTermLine.Percentage := ROUND(
                                     ((PaymentTermLine.Value / TotalRatio) * 100), PremiseMgtSetup."Rounding Precision", '>')
                                ELSE
                                    IF PremiseMgtSetup."Rounding Type" = PremiseMgtSetup."Rounding Type"::Down THEN
                                        PaymentTermLine.Percentage := ROUND(
                                         ((PaymentTermLine.Value / TotalRatio) * 100), PremiseMgtSetup."Rounding Precision", '<')
                                    ELSE
                                        IF PremiseMgtSetup."Rounding Type" = PremiseMgtSetup."Rounding Type"::Nearest THEN
                                            PaymentTermLine.Percentage := ROUND(
                                             ((PaymentTermLine.Value / TotalRatio) * 100), PremiseMgtSetup."Rounding Precision", '=');
                                PaymentTermLine.MODIFY;
                            UNTIL PaymentTermLine.NEXT = 0;
                        END;
                        IF PaymentTermLine.FINDSET THEN BEGIN
                            REPEAT
                                TotalPercentage += PaymentTermLine.Percentage;
                            UNTIL PaymentTermLine.NEXT = 0;
                        END;
                        PaymentTermLine.RESET;
                        PaymentTermLine.SETCURRENTKEY("Payment Term Code", "Element Type", "Line No.");
                        PaymentTermLine.SETRANGE("Payment Term Code", TempPaymentTermLine."Payment Term Code");
                        PaymentTermLine.SETRANGE("Element Type", TempPaymentTermLine."Element Type");
                        IF PaymentTermLine.FINDLAST THEN BEGIN
                            PaymentTermLine.Percentage := PaymentTermLine.Percentage + (100 - TotalPercentage);
                            PaymentTermLine.MODIFY;
                        END;
                    END;
                END;
            UNTIL TempPaymentTermLine.NEXT = 0;
    end;

    procedure CheckElementLines()
    var
        PaymentTermLine: Record "Payment Term Line";
    begin
        PaymentTermLine.RESET;
        PaymentTermLine.SETRANGE("Payment Term Code", "Payment Term Code");
        PaymentTermLine.SETRANGE("Element Type", "Element Type");
        PaymentTermLine.SETFILTER("Line No.", '<>%1', "Line No.");
        PaymentTermLine.SETFILTER("Calculation Type", '<>%1', "Calculation Type");
        IF PaymentTermLine.FINDFIRST THEN
            ERROR(Text33016835, "Payment Term Code", "Element Type", "Line No.", PaymentTermLine."Calculation Type");
    end;
}

