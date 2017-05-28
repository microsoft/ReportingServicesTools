# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)


Describe "Set-RsDatsSourcePassword" {
    Context "Set-RsDataSourcePassword with minimun parameters" {

        Set-RsDataSourcePassword -Path -Password 'SuperSecretPassword'
    }
}
