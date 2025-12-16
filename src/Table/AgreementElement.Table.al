table 33016812 "Agreement Element"
{
    Caption = 'Agreement Element';
    DataCaptionFields = "Code";
    // LookupFormID = Form33016810;

    fields
    {
        field(1; "Code"; Code[20])
        {
            NotBlank = true;
        }
        field(2; Description; Text[50])
        {
        }
        field(3; "Gen. Prod. Posting Group"; Code[10])
        {
            TableRelation = "Gen. Product Posting Group";
        }
        field(4; "VAT Prod. Posting Group"; Code[10])
        {
            TableRelation = "VAT Product Posting Group";
        }
        field(5; "Invoice G/L Account"; Code[20])
        {
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                IF GLAccount.GET("Invoice G/L Account") THEN BEGIN
                    VALIDATE("Gen. Prod. Posting Group", GLAccount."Gen. Prod. Posting Group");
                    VALIDATE("VAT Prod. Posting Group", GLAccount."VAT Prod. Posting Group");
                END;
            end;
        }
        field(6; "No L/S Area Applicable"; Boolean)
        {
        }
        field(7; "Revenue Sharing"; Boolean)
        {
        }
        field(8; "Rental Element"; Boolean)
        {
        }
        field(10; "Premise Specific L/S Area"; Boolean)
        {
        }
        field(11; "No. of Invoices Not Applicable"; Boolean)
        {
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        GLAccount: Record "G/L Account";
}

