table 33016874 "Payment Schedule Lines VAT"
{
    // APNT-T018890  16Jan18   Ajay            Modification for VAT Sale Invoice

    Caption = 'Payment Schedule Lines VAT';

    fields
    {
        field(1; "Agreement Type"; Option)
        {
            OptionCaption = 'Lease,Sale';
            OptionMembers = Lease,Sale;
        }
        field(2; "Agreement No."; Code[20])
        {
            TableRelation = "Agreement Header".No.;
        }
        field(3;"Agreement Line No.";Integer)
        {
        }
        field(4;"Payment Schedule Line No.";Integer)
        {
        }
        field(5;"Calculation Date";Date)
        {
        }
        field(6;"Payment %";Decimal)
        {

            trigger OnValidate()
            var
                AgreementLineRec: Record "Agreement Line";
            begin
                AgreementLineRec.RESET;
                AgreementLineRec.SETRANGE("Agreement Type","Agreement Type");
                AgreementLineRec.SETRANGE("Agreement No.","Agreement No.");
                AgreementLineRec.SETRANGE("Line No.","Agreement Line No.");
                IF AgreementLineRec.FINDFIRST THEN
                  "Invoice Due Amt." := (AgreementLineRec."Original Amount" * "Payment %")/100;
            end;
        }
        field(7;"Invoice Due Amt.";Decimal)
        {

            trigger OnValidate()
            var
                AgreementLineRec: Record "Agreement Line";
            begin
                AgreementLineRec.RESET;
                AgreementLineRec.SETRANGE("Agreement Type","Agreement Type");
                AgreementLineRec.SETRANGE("Agreement No.","Agreement No.");
                AgreementLineRec.SETRANGE("Line No.","Agreement Line No.");
                IF AgreementLineRec.FINDFIRST THEN
                  "Payment %" := ("Invoice Due Amt." * 100) / AgreementLineRec."Original Amount";
            end;
        }
        field(8;"Due Date";Date)
        {
        }
        field(9;"Invoice No.";Code[20])
        {
            Editable = false;
        }
        field(10;"Posted Invoice No.";Code[20])
        {
            Editable = false;
        }
        field(11;"Payment Term Code";Code[10])
        {
            TableRelation = "Payment Terms";
        }
        field(12;"Due Date Calculation";DateFormula)
        {

            trigger OnValidate()
            begin
                TESTFIELD("Calculation Date");
                "Due Date" := CALCDATE("Due Date Calculation","Calculation Date");
            end;
        }
        field(13;Description;Text[50])
        {
        }
        field(14;"Element Type";Code[20])
        {
        }
        field(15;"Credit Memo No.";Code[20])
        {
            Editable = false;
        }
        field(16;"Posted Cr. Memo No.";Code[20])
        {
            Editable = false;
        }
        field(17;"Rcpt. Jnl. Amt.";Decimal)
        {
            CalcFormula = Sum("Agrmt Line Application Entries"."Applied Amount" WHERE (Ref. Document Type=FIELD(Agreement Type),
                                                                                       Ref. Document No.=FIELD(Agreement No.),
                                                                                       Ref. Document Line No.=FIELD(Agreement Line No.),
                                                                                       Payment Schedule Line No.=FIELD(Payment Schedule Line No.),
                                                                                       Element Type=FIELD(Element Type),
                                                                                       Entry Type=FILTER(Approved)));
            Editable = false;
            FieldClass = FlowField;
        }
        field(18;"Post Rcpt. Jnl. Amt.";Decimal)
        {
            CalcFormula = Sum("Agrmt Line Application Entries"."Applied Amount" WHERE (Ref. Document Type=FIELD(Agreement Type),
                                                                                       Ref. Document No.=FIELD(Agreement No.),
                                                                                       Ref. Document Line No.=FIELD(Agreement Line No.),
                                                                                       Payment Schedule Line No.=FIELD(Payment Schedule Line No.),
                                                                                       Element Type=FIELD(Element Type),
                                                                                       Entry Type=FILTER(Processed)));
            Editable = false;
            FieldClass = FlowField;
        }
        field(19;"Posted Amt.";Decimal)
        {
            CalcFormula = Sum("Agrmt Line Application Entries"."Applied Amount" WHERE (Ref. Document Type=FIELD(Agreement Type),
                                                                                       Ref. Document No.=FIELD(Agreement No.),
                                                                                       Ref. Document Line No.=FIELD(Agreement Line No.),
                                                                                       Payment Schedule Line No.=FIELD(Payment Schedule Line No.),
                                                                                       Element Type=FIELD(Element Type),
                                                                                       Entry Type=FILTER(Posted)));
            Editable = false;
            FieldClass = FlowField;
        }
        field(20;"Amount Paid";Decimal)
        {
        }
        field(21;"Balance Amt.";Decimal)
        {
        }
        field(50000;"VAT Sales Invoice Created";Boolean)
        {
        }
        field(50001;"VAT Sales Invoice Posted";Boolean)
        {
        }
        field(50002;"New Invoice Due Amt. VAT";Decimal)
        {
        }
        field(50003;"VAT Sales Invoice No.";Code[20])
        {
        }
    }

    keys
    {
        key(Key1;"Agreement Type","Agreement No.","Agreement Line No.","Payment Term Code","Calculation Date","Payment Schedule Line No.")
        {
            Clustered = true;
        }
        key(Key2;"Agreement Type","Agreement No.","Agreement Line No.","Due Date")
        {
        }
        key(Key3;"Agreement Type","Agreement No.","Due Date")
        {
        }
    }

    fieldgroups
    {
    }
}

