table 33016861 "Agreement Worksheet"
{

    fields
    {
        field(1; "Entry No"; Integer)
        {
        }
        field(2; Level; Integer)
        {
            Editable = false;
        }
        field(3; "Agreement No."; Code[20])
        {
            Editable = false;
        }
        field(4; "Agreement Type"; Option)
        {
            Editable = false;
            OptionCaption = 'Lease,Sale';
            OptionMembers = Lease,Sale;
        }
        field(5; "Agreement  Line No."; Integer)
        {
            Editable = false;
        }
        field(6; "Client No."; Code[20])
        {
            Editable = false;
            TableRelation = Customer;

            trigger OnValidate()
            var
                CustomerRec: Record Customer;
            begin
            end;
        }
        field(7; "Premise No."; Code[20])
        {
            Editable = false;
            TableRelation = Premise.No.;

            trigger OnLookup()
            var
                AgreementPremiseRec: Record "Agreement Premise Relation";
                PremiseRec: Record Premise;
                PremiseFrm: Form "33016803";
            begin
            end;
        }
        field(8;"Element Type";Code[20])
        {
            Editable = false;
            TableRelation = "Agreement Element".Code;

            trigger OnValidate()
            var
                RentElementRec: Record "Agreement Element";
            begin
            end;
        }
        field(9;Description;Text[50])
        {
            Editable = false;
        }
        field(10;"No. of Invoices";Integer)
        {
            Editable = false;
            MinValue = 0;
        }
        field(11;"Invoice Unit Price";Decimal)
        {
            Editable = false;

            trigger OnValidate()
            var
                AgreementElementRec: Record "Agreement Element";
            begin
            end;
        }
        field(12;"Original Amount";Decimal)
        {
            BlankZero = true;
            Editable = false;

            trigger OnValidate()
            var
                AgreementElementRec: Record "Agreement Element";
                AgreeHeader: Record "Agreement Header";
                Currency: Record Currency;
                CurrExchRate: Record "Currency Exchange Rate";
            begin
            end;
        }
        field(13;"Leasable/Saleable Area";Decimal)
        {
            Editable = false;
        }
        field(14;"Payment Schedule Line No.";Integer)
        {
            Editable = false;
        }
        field(15;"Invoice Due Amount";Decimal)
        {
            Editable = false;

            trigger OnValidate()
            var
                AgreementLineRec: Record "Agreement Line";
            begin
            end;
        }
        field(16;"Due Date";Date)
        {
            Editable = false;
        }
        field(17;"To Be Invoice";Integer)
        {

            trigger OnValidate()
            var
                AgmtLine: Record "Agreement Line";
            begin
                IF AgmtLine.GET("Agreement Type","Agreement No.","Agreement  Line No.") THEN
                  "Invoice Amount" := "To Be Invoice" * AgmtLine."Invoice Unit Price";
            end;
        }
        field(18;"Client Name";Text[50])
        {
            Editable = false;
        }
        field(19;"Payment Term Code";Code[10])
        {
            Editable = false;
            TableRelation = "Payment Terms";
        }
        field(20;"Balance Amount";Decimal)
        {
            Editable = false;
        }
        field(21;"Calculation Date";Date)
        {
        }
        field(22;"Invoice Amount";Decimal)
        {
            Editable = false;
        }
    }

    keys
    {
        key(Key1;"Entry No")
        {
            Clustered = true;
        }
        key(Key2;"Agreement Type","Agreement No.","Agreement  Line No.","Element Type")
        {
        }
        key(Key3;"Agreement Type","Agreement No.","Agreement  Line No.",Level,"Due Date")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        AgrmtWorkLines.RESET;
        AgrmtWorkLines.GET("Entry No");
        WHILE (AgrmtWorkLines.NEXT <> 0) AND (AgrmtWorkLines.Level > Level) DO
          AgrmtWorkLines.DELETE(TRUE);
    end;

    var
        AgrmtWorkLines: Record "Agreement Worksheet";
}

