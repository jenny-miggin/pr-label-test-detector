const filterByTerm = (inputArr, searchTerm) => {
    const regex = new RegExp(searchTerm, "i");
    return inputArr.filter((arrayElement) => {
      return arrayElement.name.match(regex);
    });

  }

module.exports = { filterByTerm };