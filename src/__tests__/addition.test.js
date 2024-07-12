import { add } from '../math';

describe('Addition testing', () => {
    test('2 + 2 = 4', () => {
        expect(add(2, 2)).toBe(4);
      });

      test('2 + 3 = 5', () => {
        expect(add(2, 3)).toBe(5);
      });   

      test('2 + 5 = 7', () => {
        expect(add(2, 5)).toBe(7);
      });    

      test('2 + 7 = 9', () => {
        expect(add(2, 7)).toBe(9);
      });    

      test('2 + 20 = 22', () => {
        expect(add(2, 20)).toBe(22);
      });
})