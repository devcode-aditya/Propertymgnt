table 33016838 "Premise Contact"
{
    Caption = 'Premise Contact';
    LookupFormID = Form33016833;

    fields
    {
        field(1; "Premise Code"; Code[20])
        {
            NotBlank = true;
            TableRelation = Premise.No.;
        }
        field(2;"No.";Code[20])
        {
            NotBlank = true;
        }
        field(3;Name;Text[30])
        {
        }
        field(4;"Phone No.";Text[30])
        {
        }
        field(5;"Mobile No.";Text[30])
        {
        }
        field(6;Comment;Text[50])
        {
        }
        field(7;"E-mail";Text[30])
        {
        }
        field(8;"Contact Method";Option)
        {
            OptionCaption = 'Phone,E-mail,Fax,In Person';
            OptionMembers = Phone,"E-mail",Fax,"In Person";
        }
    }

    keys
    {
        key(Key1;"Premise Code","No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

