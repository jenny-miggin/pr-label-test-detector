import { filterByTerm } from '../filter';

describe("Filter function", () => {
    test("it should filter characters by a search term", () => {
      const input = [
        { id: 1, name: "Zelda" },
        { id: 2, name: "Ganondorf" },
        { id: 3, name: "Link" }
      ];
  
      const output = [{ id: 3, name: "Link" }];
  
      expect(filterByTerm(input, "link")).toEqual(output);
  
      expect(filterByTerm(input, "LINK")).toEqual(output);
    });
  });
