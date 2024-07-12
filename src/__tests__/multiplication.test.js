import { multiply } from '../math';

describe('Multiplication testing', () => {      
    test('3 * 1 = 3', () => {
    expect(multiply(3, 1)).toBe(3);
    });

    test('3 * 3 = 9', () => {
        expect(multiply(3, 3)).toBe(9);
    });

    test('3 * 5 = 15', () => {
        expect(multiply(3, 5)).toBe(15);
    });
                
})