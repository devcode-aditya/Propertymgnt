table 3 "Payment Terms"
{
    // DP = changes made by DVS

    Caption = 'Payment Terms';
    DataCaptionFields = "Code", Description;
    LookupFormID = Form4;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; "Due Date Calculation"; DateFormula)
        {
            Caption = 'Due Date Calculation';
        }
        field(3; "Discount Date Calculation"; DateFormula)
        {
            Caption = 'Discount Date Calculation';
        }
        field(4; "Discount %"; Decimal)
        {
            Caption = 'Discount %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(5; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(6; "Calc. Pmt. Disc. on Cr. Memos"; Boolean)
        {
            Caption = 'Calc. Pmt. Disc. on Cr. Memos';
        }
        field(33016800; "Multiple Pay. Terms"; Boolean)
        {
            CalcFormula = Exist("Payment Term Line" WHERE(Payment Term Code=FIELD(Code)));
            Description = 'DP6.01.01';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1;"Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown;"Code",Description,"Due Date Calculation")
        {
        }
    }

    trigger OnDelete()
    var
        PaymentTermsTranslation: Record "Payment Terms Translation";
    begin
        WITH PaymentTermsTranslation DO BEGIN
          SETRANGE("Payment Term",Code);
          DELETEALL
        END;
    end;
 
    procedure TranslateDescription(var PaymentTerms: Record "Payment Terms";Language: Code[10])
    var
        PaymentTermsTranslation: Record "Payment Terms Translation";
    begin
        IF PaymentTermsTranslation.GET(PaymentTerms.Code,Language) THEN
          PaymentTerms.Description := PaymentTermsTranslation.Description;
    end;
}

