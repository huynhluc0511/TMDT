    -- =========================================================
    -- ConvenienceStoreDB — PostgreSQL
    -- Giữ nguyên tên cột/bảng/kiểu CamelCase (double-quoted)
    -- =========================================================

    CREATE SCHEMA IF NOT EXISTS "core";
    CREATE SCHEMA IF NOT EXISTS "catalog";
    CREATE SCHEMA IF NOT EXISTS "sales";
    CREATE SCHEMA IF NOT EXISTS "inventory";
    CREATE SCHEMA IF NOT EXISTS "crm";
    CREATE SCHEMA IF NOT EXISTS "purchasing";
    CREATE SCHEMA IF NOT EXISTS "hr";
    CREATE SCHEMA IF NOT EXISTS "audit";

    -- =========================================================
    -- 3) CORE
    -- =========================================================
    CREATE TABLE "core"."Stores" (
        "StoreID"     SERIAL PRIMARY KEY,
        "StoreCode"   VARCHAR(30)  NOT NULL UNIQUE,
        "StoreName"   VARCHAR(200) NOT NULL,
        "Phone"       VARCHAR(20),
        "Email"       VARCHAR(150),
        "AddressLine" VARCHAR(300),
        "Ward"        VARCHAR(100),
        "District"    VARCHAR(100),
        "City"        VARCHAR(100),
        "Province"    VARCHAR(100),
        "ZipCode"     VARCHAR(20),
        "OpenTime"    TIME,
        "CloseTime"   TIME,
        "IsActive"    BOOLEAN     NOT NULL DEFAULT TRUE,
        "CreatedAt"   TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
        "UpdatedAt"   TIMESTAMP
    );

    CREATE TABLE "core"."Roles" (
        "RoleID"      SERIAL PRIMARY KEY,
        "RoleCode"    VARCHAR(50)  NOT NULL UNIQUE,
        "RoleName"    VARCHAR(100) NOT NULL,
        "Description" VARCHAR(500),
        "IsSystem"    BOOLEAN      NOT NULL DEFAULT FALSE,
        "CreatedAt"   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE "core"."Users" (
        "UserID"         SERIAL PRIMARY KEY,
        "Username"       VARCHAR(50)  NOT NULL UNIQUE,
        "PasswordHash"   VARCHAR(500) NOT NULL,
        "FullName"       VARCHAR(150) NOT NULL,
        "Email"          VARCHAR(150) UNIQUE,
        "Phone"          VARCHAR(20),
        "AvatarUrl"      VARCHAR(500),
        "DefaultStoreID" INT,
        "IsActive"       BOOLEAN      NOT NULL DEFAULT TRUE,
        "LastLoginAt"    TIMESTAMP,
        "CreatedAt"      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
        "UpdatedAt"      TIMESTAMP,
        CONSTRAINT "FK_Users_Stores"
            FOREIGN KEY ("DefaultStoreID") REFERENCES "core"."Stores"("StoreID")
    );

    CREATE TABLE "core"."UserRoles" (
        "UserRoleID"       SERIAL PRIMARY KEY,
        "UserID"           INT NOT NULL,
        "RoleID"           INT NOT NULL,
        "AssignedAt"       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        "AssignedByUserID" INT,
        CONSTRAINT "UQ_UserRoles" UNIQUE ("UserID", "RoleID"),
        CONSTRAINT "FK_UserRoles_Users"      FOREIGN KEY ("UserID")           REFERENCES "core"."Users"("UserID"),
        CONSTRAINT "FK_UserRoles_Roles"      FOREIGN KEY ("RoleID")           REFERENCES "core"."Roles"("RoleID"),
        CONSTRAINT "FK_UserRoles_AssignedBy" FOREIGN KEY ("AssignedByUserID") REFERENCES "core"."Users"("UserID")
    );

    CREATE TABLE "core"."Settings" (
        "SettingID"    SERIAL PRIMARY KEY,
        "SettingGroup" VARCHAR(100) NOT NULL,
        "SettingKey"   VARCHAR(100) NOT NULL,
        "SettingValue" TEXT,
        "ValueType"    VARCHAR(50)  NOT NULL DEFAULT 'string',
        "Description"  VARCHAR(500),
        "IsPublic"     BOOLEAN      NOT NULL DEFAULT FALSE,
        "CreatedAt"    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
        "UpdatedAt"    TIMESTAMP,
        CONSTRAINT "UQ_Settings" UNIQUE ("SettingGroup", "SettingKey")
    );

    -- =========================================================
    -- 4) HR
    -- =========================================================
    CREATE TABLE "hr"."Departments" (
        "DepartmentID"   SERIAL PRIMARY KEY,
        "DepartmentCode" VARCHAR(30)  NOT NULL UNIQUE,
        "DepartmentName" VARCHAR(150) NOT NULL,
        "Description"    VARCHAR(500),
        "IsActive"       BOOLEAN      NOT NULL DEFAULT TRUE
    );

    CREATE TABLE "hr"."Employees" (
        "EmployeeID"        SERIAL PRIMARY KEY,
        "EmployeeCode"      VARCHAR(30)  NOT NULL UNIQUE,
        "UserID"            INT UNIQUE,
        "StoreID"           INT          NOT NULL,
        "DepartmentID"      INT,
        "FullName"          VARCHAR(150) NOT NULL,
        "Gender"            VARCHAR(20),
        "DateOfBirth"       DATE,
        "Phone"             VARCHAR(20),
        "Email"             VARCHAR(150),
        "AddressLine"       VARCHAR(300),
        "HireDate"          DATE         NOT NULL,
        "TerminationDate"   DATE,
        "PositionTitle"     VARCHAR(100),
        "Salary"            NUMERIC(18,2),
        "EmploymentStatus"  VARCHAR(30)  NOT NULL DEFAULT 'ACTIVE',
        "ManagerEmployeeID" INT,
        "CreatedAt"         TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
        "UpdatedAt"         TIMESTAMP,
        CONSTRAINT "FK_Employees_User"       FOREIGN KEY ("UserID")            REFERENCES "core"."Users"("UserID"),
        CONSTRAINT "FK_Employees_Store"      FOREIGN KEY ("StoreID")           REFERENCES "core"."Stores"("StoreID"),
        CONSTRAINT "FK_Employees_Department" FOREIGN KEY ("DepartmentID")      REFERENCES "hr"."Departments"("DepartmentID"),
        CONSTRAINT "FK_Employees_Manager"    FOREIGN KEY ("ManagerEmployeeID") REFERENCES "hr"."Employees"("EmployeeID")
    );

    CREATE TABLE "hr"."Shifts" (
        "ShiftID"      SERIAL PRIMARY KEY,
        "ShiftCode"    VARCHAR(30)  NOT NULL UNIQUE,
        "ShiftName"    VARCHAR(100) NOT NULL,
        "StartTime"    TIME         NOT NULL,
        "EndTime"      TIME         NOT NULL,
        "BreakMinutes" INT          NOT NULL DEFAULT 0,
        "IsOvernight"  BOOLEAN      NOT NULL DEFAULT FALSE,
        "IsActive"     BOOLEAN      NOT NULL DEFAULT TRUE
    );

    CREATE TABLE "hr"."EmployeeShifts" (
        "EmployeeShiftID" SERIAL PRIMARY KEY,
        "EmployeeID"      INT  NOT NULL,
        "StoreID"         INT  NOT NULL,
        "ShiftID"         INT  NOT NULL,
        "WorkDate"        DATE NOT NULL,
        "CheckInAt"       TIMESTAMP,
        "CheckOutAt"      TIMESTAMP,
        "Status"          VARCHAR(30)  NOT NULL DEFAULT 'SCHEDULED',
        "Notes"           VARCHAR(500),
        CONSTRAINT "UQ_EmployeeShifts" UNIQUE ("EmployeeID", "WorkDate", "ShiftID"),
        CONSTRAINT "FK_EmployeeShifts_Employee" FOREIGN KEY ("EmployeeID") REFERENCES "hr"."Employees"("EmployeeID"),
        CONSTRAINT "FK_EmployeeShifts_Store"    FOREIGN KEY ("StoreID")    REFERENCES "core"."Stores"("StoreID"),
        CONSTRAINT "FK_EmployeeShifts_Shift"    FOREIGN KEY ("ShiftID")    REFERENCES "hr"."Shifts"("ShiftID")
    );

    -- =========================================================
    -- 5) CATALOG
    -- =========================================================
    CREATE TABLE "catalog"."Units" (
        "UnitID"      SERIAL PRIMARY KEY,
        "UnitCode"    VARCHAR(20) NOT NULL UNIQUE,
        "UnitName"    VARCHAR(50) NOT NULL,
        "Description" VARCHAR(200),
        "IsActive"    BOOLEAN     NOT NULL DEFAULT TRUE
    );

    CREATE TABLE "catalog"."Brands" (
        "BrandID"         SERIAL PRIMARY KEY,
        "BrandCode"       VARCHAR(30)  NOT NULL UNIQUE,
        "BrandName"       VARCHAR(100) NOT NULL,
        "Description"     VARCHAR(500),
        "CountryOfOrigin" VARCHAR(100),
        "IsActive"        BOOLEAN      NOT NULL DEFAULT TRUE,
        "CreatedAt"       TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE "catalog"."Categories" (
        "CategoryID"       SERIAL PRIMARY KEY,
        "ParentCategoryID" INT,
        "CategoryCode"     VARCHAR(30)  NOT NULL UNIQUE,
        "CategoryName"     VARCHAR(150) NOT NULL,
        "Description"      VARCHAR(500),
        "SortOrder"        INT          NOT NULL DEFAULT 0,
        "IsActive"         BOOLEAN      NOT NULL DEFAULT TRUE,
        "CreatedAt"        TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT "FK_Categories_Parent"
            FOREIGN KEY ("ParentCategoryID") REFERENCES "catalog"."Categories"("CategoryID")
    );

    CREATE TABLE "catalog"."TaxRates" (
        "TaxRateID"     SERIAL PRIMARY KEY,
        "TaxCode"       VARCHAR(30)  NOT NULL UNIQUE,
        "TaxName"       VARCHAR(100) NOT NULL,
        "TaxPercent"    NUMERIC(5,2) NOT NULL,
        "IsActive"      BOOLEAN      NOT NULL DEFAULT TRUE,
        "EffectiveFrom" DATE,
        "EffectiveTo"   DATE
    );

    CREATE TABLE "catalog"."Products" (
        "ProductID"       SERIAL PRIMARY KEY,
        "ProductCode"     VARCHAR(50)   NOT NULL UNIQUE,
        "SKU"             VARCHAR(50)   NOT NULL UNIQUE,
        "ProductName"     VARCHAR(200)  NOT NULL,
        "ShortName"       VARCHAR(100),
        "CategoryID"      INT           NOT NULL,
        "BrandID"         INT,
        "BaseUnitID"      INT           NOT NULL,
        "TaxRateID"       INT,
        "ProductType"     VARCHAR(30)   NOT NULL DEFAULT 'NORMAL',
        "CostPrice"       NUMERIC(18,2) NOT NULL DEFAULT 0,
        "SalePrice"       NUMERIC(18,2) NOT NULL DEFAULT 0,
        "MinStock"        NUMERIC(18,3) NOT NULL DEFAULT 0,
        "MaxStock"        NUMERIC(18,3),
        "ReorderPoint"    NUMERIC(18,3),
        "Weight"          NUMERIC(18,3),
        "Volume"          NUMERIC(18,3),
        "IsBatchTracked"  BOOLEAN       NOT NULL DEFAULT FALSE,
        "IsExpiryTracked" BOOLEAN       NOT NULL DEFAULT FALSE,
        "ShelfLifeDays"   INT,
        "IsActive"        BOOLEAN       NOT NULL DEFAULT TRUE,
        "ImageUrl"        VARCHAR(500),
        "Description"     VARCHAR(1000),
        "CreatedAt"       TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
        "UpdatedAt"       TIMESTAMP,
        CONSTRAINT "FK_Products_Category" FOREIGN KEY ("CategoryID")  REFERENCES "catalog"."Categories"("CategoryID"),
        CONSTRAINT "FK_Products_Brand"    FOREIGN KEY ("BrandID")     REFERENCES "catalog"."Brands"("BrandID"),
        CONSTRAINT "FK_Products_Unit"     FOREIGN KEY ("BaseUnitID")  REFERENCES "catalog"."Units"("UnitID"),
        CONSTRAINT "FK_Products_TaxRate"  FOREIGN KEY ("TaxRateID")   REFERENCES "catalog"."TaxRates"("TaxRateID")
    );

    CREATE TABLE "catalog"."ProductBarcodes" (
        "ProductBarcodeID" SERIAL PRIMARY KEY,
        "ProductID"        INT         NOT NULL,
        "Barcode"          VARCHAR(50) NOT NULL,
        "BarcodeType"      VARCHAR(30) NOT NULL DEFAULT 'EAN',
        "IsPrimary"        BOOLEAN     NOT NULL DEFAULT FALSE,
        "IsActive"         BOOLEAN     NOT NULL DEFAULT TRUE,
        CONSTRAINT "UQ_ProductBarcodes_Barcode" UNIQUE ("Barcode"),
        CONSTRAINT "FK_ProductBarcodes_Product"
            FOREIGN KEY ("ProductID") REFERENCES "catalog"."Products"("ProductID")
    );

    CREATE TABLE "catalog"."ProductPrices" (
        "ProductPriceID"  SERIAL PRIMARY KEY,
        "ProductID"       INT           NOT NULL,
        "StoreID"         INT,
        "PriceType"       VARCHAR(30)   NOT NULL DEFAULT 'RETAIL',
        "Price"           NUMERIC(18,2) NOT NULL,
        "EffectiveFrom"   TIMESTAMP     NOT NULL,
        "EffectiveTo"     TIMESTAMP,
        "IsActive"        BOOLEAN       NOT NULL DEFAULT TRUE,
        "CreatedByUserID" INT,
        "CreatedAt"       TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT "FK_ProductPrices_Product"   FOREIGN KEY ("ProductID")       REFERENCES "catalog"."Products"("ProductID"),
        CONSTRAINT "FK_ProductPrices_Store"     FOREIGN KEY ("StoreID")         REFERENCES "core"."Stores"("StoreID"),
        CONSTRAINT "FK_ProductPrices_CreatedBy" FOREIGN KEY ("CreatedByUserID") REFERENCES "core"."Users"("UserID")
    );

    -- =========================================================
    -- 6) PURCHASING (Suppliers trước)
    -- =========================================================
    CREATE TABLE "purchasing"."Suppliers" (
        "SupplierID"    SERIAL PRIMARY KEY,
        "SupplierCode"  VARCHAR(30)  NOT NULL UNIQUE,
        "SupplierName"  VARCHAR(200) NOT NULL,
        "ContactPerson" VARCHAR(150),
        "Phone"         VARCHAR(20),
        "Email"         VARCHAR(150),
        "TaxCode"       VARCHAR(50),
        "AddressLine"   VARCHAR(300),
        "Ward"          VARCHAR(100),
        "District"      VARCHAR(100),
        "City"          VARCHAR(100),
        "Province"      VARCHAR(100),
        "PaymentTerms"  VARCHAR(200),
        "IsActive"      BOOLEAN      NOT NULL DEFAULT TRUE,
        "CreatedAt"     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE "catalog"."ProductSuppliers" (
        "ProductSupplierID"   SERIAL PRIMARY KEY,
        "ProductID"           INT NOT NULL,
        "SupplierID"          INT NOT NULL,
        "SupplierProductCode" VARCHAR(50),
        "LastPurchasePrice"   NUMERIC(18,2),
        "IsPreferred"         BOOLEAN NOT NULL DEFAULT FALSE,
        "LeadTimeDays"        INT,
        "MinOrderQty"         NUMERIC(18,3),
        "IsActive"            BOOLEAN NOT NULL DEFAULT TRUE,
        CONSTRAINT "UQ_ProductSuppliers" UNIQUE ("ProductID", "SupplierID"),
        CONSTRAINT "FK_ProductSuppliers_Product"  FOREIGN KEY ("ProductID")  REFERENCES "catalog"."Products"("ProductID"),
        CONSTRAINT "FK_ProductSuppliers_Supplier" FOREIGN KEY ("SupplierID") REFERENCES "purchasing"."Suppliers"("SupplierID")
    );

    CREATE TABLE "purchasing"."PurchaseOrders" (
        "PurchaseOrderID"  SERIAL PRIMARY KEY,
        "PONumber"         VARCHAR(30)   NOT NULL UNIQUE,
        "StoreID"          INT           NOT NULL,
        "SupplierID"       INT           NOT NULL,
        "OrderDate"        DATE          NOT NULL,
        "ExpectedDate"     DATE,
        "Status"           VARCHAR(30)   NOT NULL DEFAULT 'DRAFT',
        "SubTotal"         NUMERIC(18,2) NOT NULL DEFAULT 0,
        "DiscountAmount"   NUMERIC(18,2) NOT NULL DEFAULT 0,
        "TaxAmount"        NUMERIC(18,2) NOT NULL DEFAULT 0,
        "TotalAmount"      NUMERIC(18,2) NOT NULL DEFAULT 0,
        "Notes"            VARCHAR(1000),
        "CreatedByUserID"  INT,
        "ApprovedByUserID" INT,
        "CreatedAt"        TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
        "UpdatedAt"        TIMESTAMP,
        CONSTRAINT "FK_PurchaseOrders_Store"      FOREIGN KEY ("StoreID")         REFERENCES "core"."Stores"("StoreID"),
        CONSTRAINT "FK_PurchaseOrders_Supplier"   FOREIGN KEY ("SupplierID")      REFERENCES "purchasing"."Suppliers"("SupplierID"),
        CONSTRAINT "FK_PurchaseOrders_CreatedBy"  FOREIGN KEY ("CreatedByUserID") REFERENCES "core"."Users"("UserID"),
        CONSTRAINT "FK_PurchaseOrders_ApprovedBy" FOREIGN KEY ("ApprovedByUserID") REFERENCES "core"."Users"("UserID")
    );

    CREATE TABLE "purchasing"."PurchaseOrderItems" (
        "PurchaseOrderItemID" SERIAL PRIMARY KEY,
        "PurchaseOrderID"     INT           NOT NULL,
        "ProductID"           INT           NOT NULL,
        "UnitID"              INT           NOT NULL,
        "OrderedQty"          NUMERIC(18,3) NOT NULL,
        "ReceivedQty"         NUMERIC(18,3) NOT NULL DEFAULT 0,
        "UnitPrice"           NUMERIC(18,2) NOT NULL,
        "DiscountPercent"     NUMERIC(5,2)  NOT NULL DEFAULT 0,
        "TaxPercent"          NUMERIC(5,2)  NOT NULL DEFAULT 0,
        "LineTotal"           NUMERIC(18,2) NOT NULL DEFAULT 0,
        "Notes"               VARCHAR(500),
        CONSTRAINT "UQ_POItems" UNIQUE ("PurchaseOrderID", "ProductID"),
        CONSTRAINT "FK_POItems_PO"      FOREIGN KEY ("PurchaseOrderID") REFERENCES "purchasing"."PurchaseOrders"("PurchaseOrderID"),
        CONSTRAINT "FK_POItems_Product" FOREIGN KEY ("ProductID")       REFERENCES "catalog"."Products"("ProductID"),
        CONSTRAINT "FK_POItems_Unit"    FOREIGN KEY ("UnitID")          REFERENCES "catalog"."Units"("UnitID")
    );

    CREATE TABLE "purchasing"."GoodsReceipts" (
        "GoodsReceiptID"  SERIAL PRIMARY KEY,
        "GRNNumber"       VARCHAR(30) NOT NULL UNIQUE,
        "PurchaseOrderID" INT,
        "StoreID"         INT NOT NULL,
        "SupplierID"      INT NOT NULL,
        "ReceiptDate"     TIMESTAMP NOT NULL,
        "Status"          VARCHAR(30) NOT NULL DEFAULT 'POSTED',
        "Notes"           VARCHAR(1000),
        "CreatedByUserID" INT,
        "CreatedAt"       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT "FK_GoodsReceipts_PO"        FOREIGN KEY ("PurchaseOrderID") REFERENCES "purchasing"."PurchaseOrders"("PurchaseOrderID"),
        CONSTRAINT "FK_GoodsReceipts_Store"     FOREIGN KEY ("StoreID")         REFERENCES "core"."Stores"("StoreID"),
        CONSTRAINT "FK_GoodsReceipts_Supplier"  FOREIGN KEY ("SupplierID")      REFERENCES "purchasing"."Suppliers"("SupplierID"),
        CONSTRAINT "FK_GoodsReceipts_CreatedBy" FOREIGN KEY ("CreatedByUserID") REFERENCES "core"."Users"("UserID")
    );

    CREATE TABLE "purchasing"."GoodsReceiptItems" (
        "GoodsReceiptItemID" SERIAL PRIMARY KEY,
        "GoodsReceiptID"     INT           NOT NULL,
        "ProductID"          INT           NOT NULL,
        "UnitID"             INT           NOT NULL,
        "Quantity"           NUMERIC(18,3) NOT NULL,
        "UnitCost"           NUMERIC(18,2) NOT NULL,
        "BatchNumber"        VARCHAR(50),
        "ManufactureDate"    DATE,
        "ExpiryDate"         DATE,
        "LineTotal"          NUMERIC(18,2) NOT NULL DEFAULT 0,
        CONSTRAINT "FK_GRItems_GR"      FOREIGN KEY ("GoodsReceiptID") REFERENCES "purchasing"."GoodsReceipts"("GoodsReceiptID"),
        CONSTRAINT "FK_GRItems_Product" FOREIGN KEY ("ProductID")      REFERENCES "catalog"."Products"("ProductID"),
        CONSTRAINT "FK_GRItems_Unit"    FOREIGN KEY ("UnitID")         REFERENCES "catalog"."Units"("UnitID")
    );

    -- =========================================================
    -- 7) INVENTORY
    -- =========================================================
    CREATE TABLE "inventory"."Warehouses" (
        "WarehouseID"   SERIAL PRIMARY KEY,
        "StoreID"       INT          NOT NULL,
        "WarehouseCode" VARCHAR(30)  NOT NULL,
        "WarehouseName" VARCHAR(150) NOT NULL,
        "WarehouseType" VARCHAR(30)  NOT NULL DEFAULT 'MAIN',
        "AddressLine"   VARCHAR(300),
        "IsDefault"     BOOLEAN      NOT NULL DEFAULT FALSE,
        "IsActive"      BOOLEAN      NOT NULL DEFAULT TRUE,
        "CreatedAt"     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT "UQ_Warehouses" UNIQUE ("StoreID", "WarehouseCode"),
        CONSTRAINT "FK_Warehouses_Store" FOREIGN KEY ("StoreID") REFERENCES "core"."Stores"("StoreID")
    );

    CREATE TABLE "inventory"."StockBalances" (
        "StockBalanceID"   SERIAL PRIMARY KEY,
        "StoreID"          INT NOT NULL,
        "WarehouseID"      INT NOT NULL,
        "ProductID"        INT NOT NULL,
        "BatchNumber"      VARCHAR(50),
        "ExpiryDate"       DATE,
        "QuantityOnHand"   NUMERIC(18,3) NOT NULL DEFAULT 0,
        "QuantityReserved" NUMERIC(18,3) NOT NULL DEFAULT 0,
        "AverageCost"      NUMERIC(18,2) NOT NULL DEFAULT 0,
        "LastUpdatedAt"    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT "FK_StockBalances_Store"     FOREIGN KEY ("StoreID")     REFERENCES "core"."Stores"("StoreID"),
        CONSTRAINT "FK_StockBalances_Warehouse" FOREIGN KEY ("WarehouseID") REFERENCES "inventory"."Warehouses"("WarehouseID"),
        CONSTRAINT "FK_StockBalances_Product"   FOREIGN KEY ("ProductID")   REFERENCES "catalog"."Products"("ProductID")
    );

    CREATE TABLE "inventory"."StockMovements" (
        "StockMovementID" BIGSERIAL PRIMARY KEY,
        "StoreID"         INT NOT NULL,
        "WarehouseID"     INT NOT NULL,
        "ProductID"       INT NOT NULL,
        "MovementType"    VARCHAR(30) NOT NULL,
        "ReferenceType"   VARCHAR(30),
        "ReferenceID"     BIGINT,
        "BatchNumber"     VARCHAR(50),
        "ExpiryDate"      DATE,
        "Quantity"        NUMERIC(18,3) NOT NULL,
        "UnitCost"        NUMERIC(18,2),
        "BeforeQty"       NUMERIC(18,3),
        "AfterQty"        NUMERIC(18,3),
        "Notes"           VARCHAR(500),
        "CreatedByUserID" INT,
        "CreatedAt"       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT "FK_StockMovements_Store"     FOREIGN KEY ("StoreID")         REFERENCES "core"."Stores"("StoreID"),
        CONSTRAINT "FK_StockMovements_Warehouse" FOREIGN KEY ("WarehouseID")     REFERENCES "inventory"."Warehouses"("WarehouseID"),
        CONSTRAINT "FK_StockMovements_Product"   FOREIGN KEY ("ProductID")       REFERENCES "catalog"."Products"("ProductID"),
        CONSTRAINT "FK_StockMovements_User"      FOREIGN KEY ("CreatedByUserID") REFERENCES "core"."Users"("UserID")
    );

    CREATE TABLE "inventory"."StockTransfers" (
        "StockTransferID"  SERIAL PRIMARY KEY,
        "TransferNumber"   VARCHAR(30) NOT NULL UNIQUE,
        "FromStoreID"      INT NOT NULL,
        "FromWarehouseID"  INT NOT NULL,
        "ToStoreID"        INT NOT NULL,
        "ToWarehouseID"    INT NOT NULL,
        "TransferDate"     TIMESTAMP NOT NULL,
        "Status"           VARCHAR(30) NOT NULL DEFAULT 'DRAFT',
        "Notes"            VARCHAR(1000),
        "CreatedByUserID"  INT,
        "ApprovedByUserID" INT,
        "CreatedAt"        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT "FK_StockTransfers_FromStore"     FOREIGN KEY ("FromStoreID")      REFERENCES "core"."Stores"("StoreID"),
        CONSTRAINT "FK_StockTransfers_FromWarehouse" FOREIGN KEY ("FromWarehouseID")  REFERENCES "inventory"."Warehouses"("WarehouseID"),
        CONSTRAINT "FK_StockTransfers_ToStore"       FOREIGN KEY ("ToStoreID")        REFERENCES "core"."Stores"("StoreID"),
        CONSTRAINT "FK_StockTransfers_ToWarehouse"   FOREIGN KEY ("ToWarehouseID")    REFERENCES "inventory"."Warehouses"("WarehouseID"),
        CONSTRAINT "FK_StockTransfers_CreatedBy"     FOREIGN KEY ("CreatedByUserID")  REFERENCES "core"."Users"("UserID"),
        CONSTRAINT "FK_StockTransfers_ApprovedBy"    FOREIGN KEY ("ApprovedByUserID") REFERENCES "core"."Users"("UserID")
    );

    CREATE TABLE "inventory"."StockTransferItems" (
        "StockTransferItemID" SERIAL PRIMARY KEY,
        "StockTransferID"     INT           NOT NULL,
        "ProductID"           INT           NOT NULL,
        "Quantity"            NUMERIC(18,3) NOT NULL,
        "UnitCost"            NUMERIC(18,2),
        "BatchNumber"         VARCHAR(50),
        "ExpiryDate"          DATE,
        "Notes"               VARCHAR(500),
        CONSTRAINT "FK_StockTransferItems_Transfer" FOREIGN KEY ("StockTransferID") REFERENCES "inventory"."StockTransfers"("StockTransferID"),
        CONSTRAINT "FK_StockTransferItems_Product"  FOREIGN KEY ("ProductID")       REFERENCES "catalog"."Products"("ProductID")
    );

    CREATE TABLE "inventory"."StockCounts" (
        "StockCountID"     SERIAL PRIMARY KEY,
        "CountNumber"      VARCHAR(30) NOT NULL UNIQUE,
        "StoreID"          INT NOT NULL,
        "WarehouseID"      INT NOT NULL,
        "CountDate"        TIMESTAMP NOT NULL,
        "Status"           VARCHAR(30) NOT NULL DEFAULT 'DRAFT',
        "Notes"            VARCHAR(1000),
        "CreatedByUserID"  INT,
        "ApprovedByUserID" INT,
        "CreatedAt"        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT "FK_StockCounts_Store"     FOREIGN KEY ("StoreID")         REFERENCES "core"."Stores"("StoreID"),
        CONSTRAINT "FK_StockCounts_Warehouse" FOREIGN KEY ("WarehouseID")     REFERENCES "inventory"."Warehouses"("WarehouseID"),
        CONSTRAINT "FK_StockCounts_CreatedBy" FOREIGN KEY ("CreatedByUserID") REFERENCES "core"."Users"("UserID"),
        CONSTRAINT "FK_StockCounts_ApprovedBy" FOREIGN KEY ("ApprovedByUserID") REFERENCES "core"."Users"("UserID")
    );

    CREATE TABLE "inventory"."StockCountItems" (
        "StockCountItemID" SERIAL PRIMARY KEY,
        "StockCountID"     INT           NOT NULL,
        "ProductID"        INT           NOT NULL,
        "SystemQty"        NUMERIC(18,3) NOT NULL,
        "CountedQty"       NUMERIC(18,3) NOT NULL,
        "DifferenceQty"    NUMERIC(18,3) NOT NULL,
        "BatchNumber"      VARCHAR(50),
        "ExpiryDate"       DATE,
        "Notes"            VARCHAR(500),
        CONSTRAINT "FK_StockCountItems_Count"   FOREIGN KEY ("StockCountID") REFERENCES "inventory"."StockCounts"("StockCountID"),
        CONSTRAINT "FK_StockCountItems_Product" FOREIGN KEY ("ProductID")    REFERENCES "catalog"."Products"("ProductID")
    );

    -- =========================================================
    -- 8) CRM
    -- =========================================================
    CREATE TABLE "crm"."CustomerGroups" (
        "CustomerGroupID" SERIAL PRIMARY KEY,
        "GroupCode"       VARCHAR(30)  NOT NULL UNIQUE,
        "GroupName"       VARCHAR(100) NOT NULL,
        "DiscountPercent" NUMERIC(5,2) NOT NULL DEFAULT 0,
        "Description"     VARCHAR(500),
        "IsActive"        BOOLEAN      NOT NULL DEFAULT TRUE
    );

    CREATE TABLE "crm"."Customers" (
        "CustomerID"      SERIAL PRIMARY KEY,
        "CustomerCode"    VARCHAR(30)  NOT NULL UNIQUE,
        "FullName"        VARCHAR(150) NOT NULL,
        "Phone"           VARCHAR(20) UNIQUE,
        "Email"           VARCHAR(150),
        "Gender"          VARCHAR(20),
        "DateOfBirth"     DATE,
        "AddressLine"     VARCHAR(300),
        "Ward"            VARCHAR(100),
        "District"        VARCHAR(100),
        "City"            VARCHAR(100),
        "Province"        VARCHAR(100),
        "CustomerGroupID" INT,
        "LoyaltyPoints"   INT           NOT NULL DEFAULT 0,
        "TotalSpent"      NUMERIC(18,2) NOT NULL DEFAULT 0,
        "IsActive"        BOOLEAN       NOT NULL DEFAULT TRUE,
        "CreatedAt"       TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
        "UpdatedAt"       TIMESTAMP,
        CONSTRAINT "FK_Customers_Group" FOREIGN KEY ("CustomerGroupID") REFERENCES "crm"."CustomerGroups"("CustomerGroupID")
    );

    CREATE TABLE "crm"."LoyaltyTransactions" (
        "LoyaltyTransactionID" BIGSERIAL PRIMARY KEY,
        "CustomerID"           INT NOT NULL,
        "TransactionType"      VARCHAR(30) NOT NULL,
        "Points"               INT NOT NULL,
        "ReferenceType"        VARCHAR(30),
        "ReferenceID"          BIGINT,
        "Notes"                VARCHAR(500),
        "CreatedAt"            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT "FK_LoyaltyTransactions_Customer"
            FOREIGN KEY ("CustomerID") REFERENCES "crm"."Customers"("CustomerID")
    );

    CREATE TABLE "crm"."Promotions" (
        "PromotionID"       SERIAL PRIMARY KEY,
        "PromotionCode"     VARCHAR(30)  NOT NULL UNIQUE,
        "PromotionName"     VARCHAR(200) NOT NULL,
        "PromotionType"     VARCHAR(30)  NOT NULL,
        "StartAt"           TIMESTAMP    NOT NULL,
        "EndAt"             TIMESTAMP    NOT NULL,
        "DiscountPercent"   NUMERIC(5,2),
        "DiscountAmount"    NUMERIC(18,2),
        "MinOrderAmount"    NUMERIC(18,2),
        "MaxDiscountAmount" NUMERIC(18,2),
        "IsActive"          BOOLEAN      NOT NULL DEFAULT TRUE,
        "Description"       VARCHAR(1000),
        "CreatedAt"         TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE "crm"."PromotionProducts" (
        "PromotionProductID" SERIAL PRIMARY KEY,
        "PromotionID"        INT NOT NULL,
        "ProductID"          INT NOT NULL,
        CONSTRAINT "UQ_PromotionProducts" UNIQUE ("PromotionID", "ProductID"),
        CONSTRAINT "FK_PromotionProducts_Promotion" FOREIGN KEY ("PromotionID") REFERENCES "crm"."Promotions"("PromotionID"),
        CONSTRAINT "FK_PromotionProducts_Product"   FOREIGN KEY ("ProductID")   REFERENCES "catalog"."Products"("ProductID")
    );

    CREATE TABLE "crm"."Coupons" (
        "CouponID"       SERIAL PRIMARY KEY,
        "CouponCode"     VARCHAR(50) NOT NULL UNIQUE,
        "PromotionID"    INT,
        "CustomerID"     INT,
        "DiscountType"   VARCHAR(20)   NOT NULL DEFAULT 'AMOUNT',
        "DiscountValue"  NUMERIC(18,2) NOT NULL,
        "MinOrderAmount" NUMERIC(18,2),
        "StartAt"        TIMESTAMP,
        "EndAt"          TIMESTAMP,
        "UsageLimit"     INT           NOT NULL DEFAULT 1,
        "UsedCount"      INT           NOT NULL DEFAULT 0,
        "IsActive"       BOOLEAN       NOT NULL DEFAULT TRUE,
        CONSTRAINT "FK_Coupons_Promotion" FOREIGN KEY ("PromotionID") REFERENCES "crm"."Promotions"("PromotionID"),
        CONSTRAINT "FK_Coupons_Customer"  FOREIGN KEY ("CustomerID")  REFERENCES "crm"."Customers"("CustomerID")
    );

    -- =========================================================
    -- 9) SALES
    -- =========================================================
    CREATE TABLE "sales"."PaymentMethods" (
        "PaymentMethodID"    SERIAL PRIMARY KEY,
        "MethodCode"         VARCHAR(30)  NOT NULL UNIQUE,
        "MethodName"         VARCHAR(100) NOT NULL,
        "RequiresReference"  BOOLEAN      NOT NULL DEFAULT FALSE,
        "IsActive"           BOOLEAN      NOT NULL DEFAULT TRUE
    );

    CREATE TABLE "sales"."CashRegisters" (
        "CashRegisterID"      SERIAL PRIMARY KEY,
        "StoreID"             INT NOT NULL,
        "RegisterCode"        VARCHAR(30)  NOT NULL,
        "RegisterName"        VARCHAR(100) NOT NULL,
        "LocationDescription" VARCHAR(200),
        "IsActive"            BOOLEAN NOT NULL DEFAULT TRUE,
        CONSTRAINT "UQ_CashRegisters" UNIQUE ("StoreID", "RegisterCode"),
        CONSTRAINT "FK_CashRegisters_Store" FOREIGN KEY ("StoreID") REFERENCES "core"."Stores"("StoreID")
    );

    CREATE TABLE "sales"."CashSessions" (
        "CashSessionID"    SERIAL PRIMARY KEY,
        "CashRegisterID"   INT NOT NULL,
        "StoreID"          INT NOT NULL,
        "EmployeeID"       INT NOT NULL,
        "OpenedAt"         TIMESTAMP NOT NULL,
        "ClosedAt"         TIMESTAMP,
        "OpeningAmount"    NUMERIC(18,2) NOT NULL DEFAULT 0,
        "ClosingAmount"    NUMERIC(18,2),
        "ExpectedAmount"   NUMERIC(18,2),
        "DifferenceAmount" NUMERIC(18,2),
        "Status"           VARCHAR(30) NOT NULL DEFAULT 'OPEN',
        "Notes"            VARCHAR(500),
        CONSTRAINT "FK_CashSessions_Register" FOREIGN KEY ("CashRegisterID") REFERENCES "sales"."CashRegisters"("CashRegisterID"),
        CONSTRAINT "FK_CashSessions_Store"    FOREIGN KEY ("StoreID")        REFERENCES "core"."Stores"("StoreID"),
        CONSTRAINT "FK_CashSessions_Employee" FOREIGN KEY ("EmployeeID")     REFERENCES "hr"."Employees"("EmployeeID")
    );

    CREATE TABLE "sales"."Orders" (
        "OrderID"             BIGSERIAL PRIMARY KEY,
        "OrderNumber"         VARCHAR(30) NOT NULL UNIQUE,
        "StoreID"             INT NOT NULL,
        "CashRegisterID"      INT,
        "CashSessionID"       INT,
        "CustomerID"          INT,
        "EmployeeID"          INT,
        "OrderType"           VARCHAR(30)   NOT NULL DEFAULT 'POS',
        "OrderStatus"         VARCHAR(30)   NOT NULL DEFAULT 'COMPLETED',
        "OrderSource"         VARCHAR(30)   NOT NULL DEFAULT 'WEB',
        "OrderDate"           TIMESTAMP     NOT NULL,
        "SubTotal"            NUMERIC(18,2) NOT NULL DEFAULT 0,
        "DiscountAmount"      NUMERIC(18,2) NOT NULL DEFAULT 0,
        "TaxAmount"           NUMERIC(18,2) NOT NULL DEFAULT 0,
        "ShippingAmount"      NUMERIC(18,2) NOT NULL DEFAULT 0,
        "FinalAmount"         NUMERIC(18,2) NOT NULL DEFAULT 0,
        "PaidAmount"          NUMERIC(18,2) NOT NULL DEFAULT 0,
        "ChangeAmount"        NUMERIC(18,2) NOT NULL DEFAULT 0,
        "LoyaltyPointsEarned" INT           NOT NULL DEFAULT 0,
        "LoyaltyPointsUsed"   INT           NOT NULL DEFAULT 0,
        "PromotionID"         INT,
        "CouponID"            INT,
        "Notes"               VARCHAR(1000),
        "CreatedAt"           TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
        "UpdatedAt"           TIMESTAMP,
        CONSTRAINT "FK_Orders_Store"     FOREIGN KEY ("StoreID")        REFERENCES "core"."Stores"("StoreID"),
        CONSTRAINT "FK_Orders_Register"  FOREIGN KEY ("CashRegisterID") REFERENCES "sales"."CashRegisters"("CashRegisterID"),
        CONSTRAINT "FK_Orders_Session"   FOREIGN KEY ("CashSessionID")  REFERENCES "sales"."CashSessions"("CashSessionID"),
        CONSTRAINT "FK_Orders_Customer"  FOREIGN KEY ("CustomerID")     REFERENCES "crm"."Customers"("CustomerID"),
        CONSTRAINT "FK_Orders_Employee"  FOREIGN KEY ("EmployeeID")     REFERENCES "hr"."Employees"("EmployeeID"),
        CONSTRAINT "FK_Orders_Promotion" FOREIGN KEY ("PromotionID")    REFERENCES "crm"."Promotions"("PromotionID"),
        CONSTRAINT "FK_Orders_Coupon"    FOREIGN KEY ("CouponID")       REFERENCES "crm"."Coupons"("CouponID")
    );

    CREATE TABLE "sales"."OrderItems" (
        "OrderItemID"     BIGSERIAL PRIMARY KEY,
        "OrderID"         BIGINT        NOT NULL,
        "ProductID"       INT           NOT NULL,
        "UnitID"          INT           NOT NULL,
        "Quantity"        NUMERIC(18,3) NOT NULL,
        "UnitPrice"       NUMERIC(18,2) NOT NULL,
        "DiscountPercent" NUMERIC(5,2)  NOT NULL DEFAULT 0,
        "DiscountAmount"  NUMERIC(18,2) NOT NULL DEFAULT 0,
        "TaxPercent"      NUMERIC(5,2)  NOT NULL DEFAULT 0,
        "TaxAmount"       NUMERIC(18,2) NOT NULL DEFAULT 0,
        "LineTotal"       NUMERIC(18,2) NOT NULL DEFAULT 0,
        "CostAtSale"      NUMERIC(18,2),
        "BatchNumber"     VARCHAR(50),
        "ExpiryDate"      DATE,
        "Notes"           VARCHAR(500),
        CONSTRAINT "FK_OrderItems_Order"   FOREIGN KEY ("OrderID")   REFERENCES "sales"."Orders"("OrderID"),
        CONSTRAINT "FK_OrderItems_Product" FOREIGN KEY ("ProductID") REFERENCES "catalog"."Products"("ProductID"),
        CONSTRAINT "FK_OrderItems_Unit"    FOREIGN KEY ("UnitID")    REFERENCES "catalog"."Units"("UnitID")
    );

    CREATE TABLE "sales"."OrderPayments" (
        "OrderPaymentID"   BIGSERIAL PRIMARY KEY,
        "OrderID"          BIGINT        NOT NULL,
        "PaymentMethodID"  INT           NOT NULL,
        "Amount"           NUMERIC(18,2) NOT NULL,
        "PaidAt"           TIMESTAMP     NOT NULL,
        "TransactionRef"   VARCHAR(100),
        "PaymentStatus"    VARCHAR(30)   NOT NULL DEFAULT 'SUCCESS',
        "Notes"            VARCHAR(500),
        CONSTRAINT "FK_OrderPayments_Order"  FOREIGN KEY ("OrderID")         REFERENCES "sales"."Orders"("OrderID"),
        CONSTRAINT "FK_OrderPayments_Method" FOREIGN KEY ("PaymentMethodID") REFERENCES "sales"."PaymentMethods"("PaymentMethodID")
    );

    CREATE TABLE "sales"."ReturnOrders" (
        "ReturnOrderID"   BIGSERIAL PRIMARY KEY,
        "ReturnNumber"    VARCHAR(30) NOT NULL UNIQUE,
        "OriginalOrderID" BIGINT      NOT NULL,
        "StoreID"         INT         NOT NULL,
        "CustomerID"      INT,
        "EmployeeID"      INT,
        "ReturnDate"      TIMESTAMP   NOT NULL,
        "Status"          VARCHAR(30) NOT NULL DEFAULT 'COMPLETED',
        "RefundAmount"    NUMERIC(18,2) NOT NULL DEFAULT 0,
        "Notes"           VARCHAR(1000),
        CONSTRAINT "FK_ReturnOrders_Order"    FOREIGN KEY ("OriginalOrderID") REFERENCES "sales"."Orders"("OrderID"),
        CONSTRAINT "FK_ReturnOrders_Store"    FOREIGN KEY ("StoreID")         REFERENCES "core"."Stores"("StoreID"),
        CONSTRAINT "FK_ReturnOrders_Customer" FOREIGN KEY ("CustomerID")      REFERENCES "crm"."Customers"("CustomerID"),
        CONSTRAINT "FK_ReturnOrders_Employee" FOREIGN KEY ("EmployeeID")      REFERENCES "hr"."Employees"("EmployeeID")
    );

    CREATE TABLE "sales"."ReturnOrderItems" (
        "ReturnOrderItemID" BIGSERIAL PRIMARY KEY,
        "ReturnOrderID"     BIGINT        NOT NULL,
        "OrderItemID"       BIGINT        NOT NULL,
        "ProductID"         INT           NOT NULL,
        "Quantity"          NUMERIC(18,3) NOT NULL,
        "RefundAmount"      NUMERIC(18,2) NOT NULL,
        "Reason"            VARCHAR(500),
        CONSTRAINT "FK_ReturnOrderItems_ReturnOrder" FOREIGN KEY ("ReturnOrderID") REFERENCES "sales"."ReturnOrders"("ReturnOrderID"),
        CONSTRAINT "FK_ReturnOrderItems_OrderItem"   FOREIGN KEY ("OrderItemID")   REFERENCES "sales"."OrderItems"("OrderItemID"),
        CONSTRAINT "FK_ReturnOrderItems_Product"     FOREIGN KEY ("ProductID")     REFERENCES "catalog"."Products"("ProductID")
    );

    -- =========================================================
    -- 10) AUDIT
    -- =========================================================
    CREATE TABLE "audit"."ActivityLogs" (
        "ActivityLogID" BIGSERIAL PRIMARY KEY,
        "UserID"        INT,
        "StoreID"       INT,
        "ActionName"    VARCHAR(100) NOT NULL,
        "EntityName"    VARCHAR(100),
        "EntityID"      VARCHAR(100),
        "IpAddress"     VARCHAR(50),
        "UserAgent"     VARCHAR(500),
        "Description"   VARCHAR(1000),
        "CreatedAt"     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT "FK_ActivityLogs_User"  FOREIGN KEY ("UserID")  REFERENCES "core"."Users"("UserID"),
        CONSTRAINT "FK_ActivityLogs_Store" FOREIGN KEY ("StoreID") REFERENCES "core"."Stores"("StoreID")
    );

    CREATE TABLE "audit"."ErrorLogs" (
        "ErrorLogID"   BIGSERIAL PRIMARY KEY,
        "ErrorCode"    VARCHAR(100),
        "ErrorMessage" VARCHAR(2000) NOT NULL,
        "StackTrace"   TEXT,
        "SourceModule" VARCHAR(200),
        "UserID"       INT,
        "StoreID"      INT,
        "CreatedAt"    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT "FK_ErrorLogs_User"  FOREIGN KEY ("UserID")  REFERENCES "core"."Users"("UserID"),
        CONSTRAINT "FK_ErrorLogs_Store" FOREIGN KEY ("StoreID") REFERENCES "core"."Stores"("StoreID")
    );

    -- =========================================================
    -- 11) INDEXES
    -- =========================================================
    CREATE INDEX "IX_Products_ProductName"                ON "catalog"."Products" ("ProductName");
    CREATE INDEX "IX_Products_CategoryID"                 ON "catalog"."Products" ("CategoryID");
    CREATE INDEX "IX_ProductPrices_ProductID_StoreID"     ON "catalog"."ProductPrices" ("ProductID", "StoreID");
    CREATE INDEX "IX_StockBalances_Store_Warehouse_Product" ON "inventory"."StockBalances" ("StoreID", "WarehouseID", "ProductID");
    CREATE INDEX "IX_StockMovements_ProductID_CreatedAt"  ON "inventory"."StockMovements" ("ProductID", "CreatedAt");
    CREATE INDEX "IX_Customers_FullName"                  ON "crm"."Customers" ("FullName");
    CREATE INDEX "IX_Customers_Phone"                     ON "crm"."Customers" ("Phone");
    CREATE INDEX "IX_Orders_OrderDate"                    ON "sales"."Orders" ("OrderDate");
    CREATE INDEX "IX_Orders_StoreID"                      ON "sales"."Orders" ("StoreID");
    CREATE INDEX "IX_Orders_CustomerID"                   ON "sales"."Orders" ("CustomerID");
    CREATE INDEX "IX_OrderItems_OrderID"                  ON "sales"."OrderItems" ("OrderID");
    CREATE INDEX "IX_PO_OrderDate"                        ON "purchasing"."PurchaseOrders" ("OrderDate");
    CREATE INDEX "IX_GoodsReceipts_ReceiptDate"           ON "purchasing"."GoodsReceipts" ("ReceiptDate");
    CREATE INDEX "IX_Employees_StoreID"                   ON "hr"."Employees" ("StoreID");

    -- =========================================================
    -- 12) CHECK CONSTRAINTS
    -- =========================================================
    ALTER TABLE "catalog"."Products"
        ADD CONSTRAINT "CK_Products_CostPrice" CHECK ("CostPrice" >= 0),
        ADD CONSTRAINT "CK_Products_SalePrice" CHECK ("SalePrice" >= 0),
        ADD CONSTRAINT "CK_Products_MinStock"  CHECK ("MinStock"  >= 0);

    ALTER TABLE "catalog"."TaxRates"
        ADD CONSTRAINT "CK_TaxRates_TaxPercent" CHECK ("TaxPercent" >= 0 AND "TaxPercent" <= 100);

    ALTER TABLE "purchasing"."PurchaseOrderItems"
        ADD CONSTRAINT "CK_POItems_OrderedQty" CHECK ("OrderedQty" > 0),
        ADD CONSTRAINT "CK_POItems_UnitPrice"  CHECK ("UnitPrice" >= 0);

    ALTER TABLE "purchasing"."GoodsReceiptItems"
        ADD CONSTRAINT "CK_GRItems_Quantity" CHECK ("Quantity" > 0),
        ADD CONSTRAINT "CK_GRItems_UnitCost" CHECK ("UnitCost" >= 0);

    ALTER TABLE "inventory"."StockBalances"
        ADD CONSTRAINT "CK_StockBalances_QOH" CHECK ("QuantityOnHand"   >= 0),
        ADD CONSTRAINT "CK_StockBalances_QR"  CHECK ("QuantityReserved" >= 0);

    ALTER TABLE "sales"."OrderItems"
        ADD CONSTRAINT "CK_OrderItems_Quantity"  CHECK ("Quantity"  > 0),
        ADD CONSTRAINT "CK_OrderItems_UnitPrice" CHECK ("UnitPrice" >= 0);

    ALTER TABLE "sales"."OrderPayments"
        ADD CONSTRAINT "CK_OrderPayments_Amount" CHECK ("Amount" >= 0);

    ALTER TABLE "crm"."Coupons"
        ADD CONSTRAINT "CK_Coupons_UsedCount"  CHECK ("UsedCount"  >= 0),
        ADD CONSTRAINT "CK_Coupons_UsageLimit" CHECK ("UsageLimit" >= 0);

    ALTER TABLE "crm"."Customers"
        ADD CONSTRAINT "CK_Customers_LoyaltyPoints" CHECK ("LoyaltyPoints" >= 0),
        ADD CONSTRAINT "CK_Customers_TotalSpent"    CHECK ("TotalSpent"    >= 0);