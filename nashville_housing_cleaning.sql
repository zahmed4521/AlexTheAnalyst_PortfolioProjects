-- Nashville Housing Data Cleaning Project

USE nash_housing;

-- Standardize Date Format
ALTER TABLE housing
ADD new_date DATE;

UPDATE housing
SET new_date = STR_TO_DATE(SaleDate, '%M %d, %Y');

ALTER TABLE housing
DROP SaleDate;

ALTER TABLE housing
RENAME COLUMN new_date TO date;

-- ---------------------------------
-- Populate Empty Property Addresses
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM housing a
JOIN housing b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID 
WHERE COALESCE(a.PropertyAddress, '') = '';

UPDATE housing a
JOIN housing b
	ON a.ParcelID = b.ParcelID
    AND a.UniqueID <> b.UniqueID
SET a.PropertyAddress = b.PropertyAddress
WHERE COALESCE(a.PropertyAddress, '') = '';

-- ---------------------------------------------------------------------
-- Breaking Down PropertyAddress into Individual Columns (Address, City)
SELECT SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress) - 1) AS street_address, -- Select address until comma
		SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress) + 1) AS city -- Select address after comma
FROM housing;

ALTER TABLE housing
ADD PropertySplitAddress VARCHAR(100);

UPDATE housing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress) -1);

ALTER TABLE housing
ADD PropertySplitCity VARCHAR(100);

UPDATE housing
SET PropertySplitCity = SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress) +1);

-- ------------------------------------------------------------------
-- Breaking Down OwnerAddress into Individual Columns (Address, City)
SELECT SUBSTRING_INDEX(OwnerAddress, ',', 1) AS street_address,
		SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1) AS city,
        SUBSTRING_INDEX(OwnerAddress, ',', -1) AS state
FROM housing;

ALTER TABLE housing
ADD OwnerStreetAddress VARCHAR(100);

UPDATE housing
SET OwnerStreetAddress = SUBSTRING_INDEX(OwnerAddress, ',', 1);

ALTER TABLE housing
ADD OwnerCity VARCHAR(100);

UPDATE housing
SET OwnerCity = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1);

ALTER TABLE housing
ADD OwnerState VARCHAR(100);

UPDATE housing
SET OwnerState = SUBSTRING_INDEX(OwnerAddress, ',', -1);

-- --------------------------------------------
-- Change Y and N to Yes and No in SoldAsVacant
SELECT SoldAsVacant,
		CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
			 WHEN SoldAsVacant = 'N' THEN 'No'
             ELSE SoldAsVacant
             END
FROM housing;

UPDATE housing
SET SoldAsVacant = CASE 
			 WHEN SoldAsVacant = 'Y' THEN 'Yes'
			 WHEN SoldAsVacant = 'N' THEN 'No'
             ELSE SoldAsVacant
             END;

-- -----------------
-- Remove Duplicates
DELETE h1
FROM housing h1
JOIN housing h2
  ON h1.ParcelID = h2.ParcelID
 AND h1.PropertyAddress = h2.PropertyAddress
 AND h1.SalePrice = h2.SalePrice
 AND h1.LegalReference = h2.LegalReference
 AND h1.UniqueID > h2.UniqueID;

 -- ---------------------
 -- Delete Unused Columns
ALTER TABLE housing
DROP COLUMN OwnerAddress, 
DROP COLUMN TaxDistrict, 
DROP COLUMN PropertyAddress;
