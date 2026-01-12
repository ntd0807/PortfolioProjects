SELECT *
INTO NashVille
FROM NashVille_Backup
;

-- Date Format Standardizing
ALTER TABLE NashVille
ADD SaleDateConverted DATE
;

UPDATE NashVille
SET SaleDateConverted = CONVERT(DATE, SaleDate)
WHERE SaleDate IS NOT NULL
;

-- Populate Property Address Data
WITH SafeAddress AS (
	SELECT 
		ParcelID,
		MAX(PropertyAddress) AS PropertyAddress
	FROM NashVille
	WHERE PropertyAddress IS NOT NULL
	GROUP BY ParcelID
	HAVING COUNT(DISTINCT PropertyAddress) = 1
)

UPDATE NashVille
SET NashVille.PropertyAddress = sa.PropertyAddress
FROM NashVille nh
JOIN SafeAddress sa
	ON nh.ParcelID = sa.ParcelID
WHERE nh.PropertyAddress is NULL
;

-- Split Property Address
ALTER TABLE NashVille
ADD PropertySplitAddress NVARCHAR(255),
	PropertySplitCity NVARCHAR(255)
;

UPDATE NashVille
SET
	PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1),
	PropertySplitCity = LTRIM(SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)))
WHERE PropertyAddress IS NOT NULL
;

-- Split Owner Address
ALTER TABLE NashVille
ADD OwnerSplitAddress NVARCHAR(255),
	OwnerSplitCity NVARCHAR(255),
	OwnerSplitState NVARCHAR(255)
;

UPDATE NashVille
SET
	OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
	OwnerSplitCity    = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
	OwnerSplitState   = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
WHERE OwnerAddress IS NOT NULL
;

-- Normalize SoldAsVacant Values
UPDATE NashVille
SET SoldAsVacant = CASE
    WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
END;

-- Identify Duplicates (safe preview)
WITH RowNumCTE AS (
	SELECT *,
			ROW_NUMBER() OVER (
				PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDateConverted, LegalReference
				ORDER BY UniqueID -- Decides the first/original roww get row_num = 1
			) AS row_num
	FROM NashVille
)

SELECT * 
FROM RowNumCTE
WHERE row_num > 1 -- picks the extra rows in each group, i.e., duplicates.
;

-- Deleting the duplicates
WITH RowNumCTE AS (
	SELECT *,
			ROW_NUMBER() OVER (
				PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDateConverted, LegalReference
				ORDER BY UniqueID -- Decides the first/original roww get row_num = 1
			) AS row_num
	FROM NashVille
)

 DELETE 
FROM RowNumCTE
WHERE row_num > 1
;


-- DROP unused columns
ALTER TABLE NashVille
DROP COLUMN PropertyAddress, OwnerAddress, SaleDate
;

-- Final Intergrity check
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT UniqueID) AS unique_rows
FROM NashVille
;
