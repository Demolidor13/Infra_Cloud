terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=2.46.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg-patrick" {
  name     = "rg-patrick"
  location = "East US"
}

resource "azurerm_virtual_network" "vn-patrick" {
  name                = "vn-patrick"
  location            = azurerm_resource_group.rg-patrick.location
  resource_group_name = azurerm_resource_group.rg-patrick.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "sub-patrick" {
  name                 = "sub-patrick"
  resource_group_name  = azurerm_resource_group.rg-patrick.name
  virtual_network_name = azurerm_virtual_network.vn-patrick.name
  address_prefixes     = ["10.0.1.0/24"]
}


resource "azurerm_network_interface" "ni-patrick" {
  name                = "ni-patrick"
  location            = azurerm_resource_group.rg-patrick.location
  resource_group_name = azurerm_resource_group.rg-patrick.name

  ip_configuration {
    name                            = "internal"
    subnet_id                       = azurerm_subnet.sub-patrick.id
    private_ip_address_allocation   = "Dynamic"
    public_ip_address_id            = azurerm_public_ip.ippublic-patrick.id
  }
}


resource "azurerm_public_ip" "ippublic-patrick" {
  name                = "ippublic-patrick"
  resource_group_name = azurerm_resource_group.rg-patrick.name
  location            = azurerm_resource_group.rg-patrick.location
  allocation_method   = "Static"

  tags = {
    environment = "IPPUBLIC"
  }
}


data "azurerm_public_ip" "data-ippublic-patrick" {
    resource_group_name = azurerm_resource_group.rg-patrick.name
    name = azurerm_public_ip.ippublic-patrick.name
}

resource "azurerm_network_security_group" "nsg-patrick" {
  name                = "nsg-patrick"
  location            = azurerm_resource_group.rg-patrick.location
  resource_group_name = azurerm_resource_group.rg-patrick.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "MySql"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3306"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Firewall"
  }
}


resource "azurerm_subnet_network_security_group_association" "nsga-patrick" {
  subnet_id                 = azurerm_subnet.sub-patrick.id
  network_security_group_id = azurerm_network_security_group.nsg-patrick.id
}

/*
resource "azurerm_storage_account" "storagepatrick" {
    name                        = "storagepatrick"
    resource_group_name         = azurerm_resource_group.rg-patrick.name
    location                    = "East US"
    account_tier                = "Standard"
    account_replication_type    = "LRS"
}
*/

resource "azurerm_linux_virtual_machine" "vm-linux" {
    name                  = "vm-linux"
    location              = azurerm_resource_group.rg-patrick.location
    resource_group_name   = azurerm_resource_group.rg-patrick.name
    network_interface_ids = [azurerm_network_interface.ni-patrick.id]
    size                  = "Standard_DS1_v2"

    os_disk {
        name              = "disk-patrick"
        caching           = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }

    computer_name  = "vm-linux"
    admin_username = "admintst"
    admin_password = "Admin123@"
    disable_password_authentication = false

/*
    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.storagepatrick.primary_blob_endpoint
    }
*/
    tags = {
        environment = "Terraform vm Teste"
    }
}

output "publicip-patrick" {
    value = azurerm_public_ip.ippublic-patrick.ip_address
}

resource "time_sleep" "wait_30_seg" {
    depends_on = [azurerm_linux_virtual_machine.vm-linux]
    create_duration = "30s"
}


resource "null_resource" "carrega_arq_local" {
    provisioner "file" {
        connection {
            type = "ssh"
            user = "admintst"
            password = "Admin123@"
            host = data.azurerm_public_ip.data-ippublic-patrick.ip_address
        }
        source = "config"
        destination = "rg-patrick"
    }

    depends_on = [ time_sleep.wait_30_seg ]
}


resource "null_resource" "install_sql" {
    triggers = {
        order = null_resource.carrega_arq_local.id
    }

    provisioner "remote-exec" {
      connection {
        type = "ssh"
        user = "admintst"
        password = "Admin123@"
        host = data.azurerm_public_ip.data-ippublic-patrick.ip_address
      }
    inline = [
        "sudo apt-get update",
        "sudo apt-get install -y mysql-server-5.7",
        "sudo mysql < rg-patrick/config/user.sql",
        "sudo cp -f rg-patrick/config/mysqld.cnf /etc/mysql/mysql.conf.d/mysqld.cnf",
        "sudo service mysql restart",
    ]
    }
    
    depends_on = [ time_sleep.wait_30_seg ]
}