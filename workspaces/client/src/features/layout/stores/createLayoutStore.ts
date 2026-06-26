import { lens } from '@dhmk/zustand-lens';

interface LayoutState {
  pointer: { x: number; y: number };
}

interface LayoutActions {
  updatePointer: (pointer: { x: number; y: number }) => void;
}

export const createLayoutStoreSlice = () => {
  return lens<LayoutState & LayoutActions>((set) => ({
    pointer: { x: 0, y: 0 },
    updatePointer: (pointer) => {
      set(() => ({ pointer }));
    },
  }));
};
