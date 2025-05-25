class Environment {
    HELLO_WORLD: string;
    constructor() {
        this.HELLO_WORLD = import.meta.env.VITE_HELLO_WORLD;
    }
}

const environment = new Environment();

export default environment;