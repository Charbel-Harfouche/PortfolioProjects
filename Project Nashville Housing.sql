-- Nashville housing data for data cleaning project
select * from [SQL Project]..nashvillehousing




-- Populate address columns that are NULL
-- Houses with the same ParcelID have the same address
-- First, let's count how many houses don't have an address
SELECT count(*) FROM [SQL Project]..NashvilleHousing
WHERE PropertyAddress IS NULL 
-- there are 29 houses without an address

select a.UniqueID, a.ParcelID, a.propertyaddress, b.UniqueID, b.ParcelID, b.PropertyAddress, ISNULL(a.propertyaddress,b.propertyaddress) as UpdatedPropertyaddress
from [SQL Project].dbo.NashvilleHousing as a
join [SQL Project].dbo.NashvilleHousing as b
on  a.ParcelID = b.ParcelID
and a.UniqueID <> b.UniqueID
where a.PropertyAddress is null
order by a.UniqueID


-- Now let's add the updated and correct info into a new column
Alter table [SQL Project]..Nashvillehousing
add UpdatedPropertyaddress nvarchar(255)

update [SQL Project]..NashvilleHousing
set updatedpropertyaddress = PropertyAddress

Update a
set UpdatedPropertyaddress = ISNULL(a.propertyaddress,b.propertyaddress)
from [SQL Project].dbo.NashvilleHousing as a
join [SQL Project].dbo.NashvilleHousing as b
on  a.ParcelID = b.ParcelID
and a.UniqueID <> b.UniqueID
where a.PropertyAddress is null

select UpdatedPropertyAddress from [SQL Project].dbo.NashvilleHousing
where UpdatedPropertyAddress is null
-- All the empty address columns have been appropriately filled


-- Breaking the Propertyaddress column into address and city
select propertyaddress, substring(propertyaddress, 1, charindex(',', PropertyAddress)-1) as address
, substring(propertyaddress, charindex(',',propertyaddress)+2,len(propertyaddress)) as City from [SQL Project]..NashvilleHousing

-- Let's add these two new columns
Alter table Nashvillehousing
add Address Nvarchar(255),
City Nvarchar(255)

UPDATE NashvilleHousing
set address = substring(propertyaddress, 1, charindex(',', PropertyAddress)-1)

UPDATE NashvilleHousing
set City = substring(propertyaddress, charindex(',',propertyaddress)+2,len(propertyaddress))
select address, city from NashvilleHousing


-- Now let's use the owneraddress to get the state and then separate it into a new column called state
-- This time, PARSENAME will be used instead of SUBSTRING
Select owneraddress from [SQL Project]..NashvilleHousing
Select PARSENAME(replace(owneraddress,',','.'),1) as State from [SQL Project]..NashvilleHousing

Alter table Nashvillehousing
add State Nvarchar(50)

Update Nashvillehousing
set State = PARSENAME(replace(owneraddress,',','.'),1)
select state from [SQL Project]..NashvilleHousing


-- Soldasvacant column has multiple values for YES and NO that needs to be fixed
Select distinct SoldAsVacant, count(soldasvacant) from [SQL Project]..NashvilleHousing
group by SoldAsVacant
-- It's a mess with 'N' and 'No' and 'Y' and 'Yes' and it needs fixing

-- Let's replace the 'Y' and 'N' with 'Yes' and 'No' and output to a new column titled 'SoldAsVacantFixed'
Select SoldAsVacant,
CASE
WHEN SoldAsVacant = 'Y' THEN 'Yes'
WHEN SoldAsVacant = 'N' THEN 'No'
ELSE SoldAsVacant
END as SoldAsVacantFixed
from [SQL Project]..NashvilleHousing

ALTER table NashvilleHousing
add SoldAsVacantFixed Nvarchar(50)

UPDATE NashvilleHousing
Set SoldAsVacantFixed =
CASE
WHEN SoldAsVacant = 'Y' THEN 'Yes'
WHEN SoldAsVacant = 'N' THEN 'No'
ELSE SoldAsVacant
END
from [SQL Project]..NashvilleHousing

Select soldasvacantfixed, count(soldasvacantfixed) from NashvilleHousing
group by soldasvacantfixed


-- Deleting duplicate Rows
-- Every row has a uniqueID, but the rest of the columns might be duplicates
-- It would be better to use the window function ROW_NUMBER() in a CTE

With RowNumb as(
select *, ROW_NUMBER() over ( partition by
parcelid,
propertyaddress,
saleprice,
saledate,
legalreference,
yearbuilt,
totalvalue,
acreage
order by uniqueid) as rownb
from [SQL Project]..NashvilleHousing)
--select * from RowNumb
DELETE FROM RowNumb
where rownb > 1


-- Deleting unnecessary and duplicate columns and fixing column names
-- Renaming is optional, the original columns could have been edited, but they weren't for the sake of this project
ALTER TABLE NashvilleHousing
DROP COLUMN owneraddress, propertyaddress, soldasvacant
EXEC sp_rename 'nashvillehousing.soldasvacantfixed', 'SoldAsVacant', 'COLUMN';
EXEC sp_rename 'nashvillehousing.UpdatedPropertyaddress', 'PropertyAddress', 'COLUMN';


select * from NashvilleHousing

