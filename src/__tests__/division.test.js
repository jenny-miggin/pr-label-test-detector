import { divide } from '../math';

describe('Division testing', () => {
      
    test('8 / 1 = 8', () => {
        expect(divide(8, 1)).toBe(8);
    });

    test('9 / 3 = 2', () => {
        expect(divide(9, 3)).toBe(3);
    });
})