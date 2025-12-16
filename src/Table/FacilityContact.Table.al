table 33016849 "Facility Contact"
{
    Caption = 'Facility Contact';
    LookupFormID = Form33016876;

    fields
    {
        field(1; "Facility Code"; Code[20])
        {
            TableRelation = Facility.No.;
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
        field(9;"No. Series";Code[20])
        {
            TableRelation = "No. Series";
        }
    }

    keys
    {
        key(Key1;"Facility Code","No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

