# Setting Up Dynamic Environment Variables with Vite and Docker

## How does it work

In this `.env.production` you want to write the name of the environment variable that has to be replace with the value. The reason is that this value will be placed in your code during build time. When we are running the docker container we are going to run a script that will replace the value in the source with the value that is passed in the environment by docker compose.

.env.production
```properties
VITE_VALUE=PREFIX_VALUE
```

docker compose .env 
```properties
APP_PREFIX=PREFIX_
PREFIX_VALUE=Hello world
```

```typescript
class Environment {
    VALUE: string;
    constructor() {
        this.VALUE = import.meta.env.VITE_VALUE;
    }
}

const environment = new Environment();

export default environment;
```

This will be replaced in build time by this.

```typescript
...
        this.VALUE = "PREFIX_VALUE";
...
```

And when we run the env.sh script it will replace this marker with the value in the environment like this.

```typescript
...
        this.VALUE = "Hello world";
...
```

[![](https://mermaid.ink/img/pako:eNp9kt1q4zAQhV9FzLVrYsfOj6GFbpJlA7tQShNKMRTFmsYismTGcrNpnHevbEO9LWx1ITQjfeeMpDlDZgRCAi_KHLOck2UPy1QzN6p6tyde5uyOTIZV1WfbsTTZAWlhitJUyK6ubtiPWirRrprt-mH1vL39vVld392vfq4f-6Bh64Lv8RuN5t_j179QKcOOhpRo2KZkA9jpdADqV0lGF6itv-Wqxi-Om3KgnMRXD9bzLc5eOUm-U8gIS8UzFOwobc7yoQq2O7WAX-UNW2lLp9JIbQeDIfef2j7daGG05VIj9QKoBXiwJykgeeGqQg8KpIK3MZzbMynYHAtMIXFLwemQQqovDiq5fjKmgMRS7TAy9T7_EKlLwS0uJXcfWXxkydm1T19rC0kQR9NOBZIz_IUkDGI_mgTxJBgH03AWxbEHJ0gmU38ejcNZGM2DIIxH8cWDt8535M_CyXg0GodumrttD1BIa-hP31hdf13eAek8wtI?type=png)](https://mermaid.live/edit#pako:eNp9kt1q4zAQhV9FzLVrYsfOj6GFbpJlA7tQShNKMRTFmsYismTGcrNpnHevbEO9LWx1ITQjfeeMpDlDZgRCAi_KHLOck2UPy1QzN6p6tyde5uyOTIZV1WfbsTTZAWlhitJUyK6ubtiPWirRrprt-mH1vL39vVld392vfq4f-6Bh64Lv8RuN5t_j179QKcOOhpRo2KZkA9jpdADqV0lGF6itv-Wqxi-Om3KgnMRXD9bzLc5eOUm-U8gIS8UzFOwobc7yoQq2O7WAX-UNW2lLp9JIbQeDIfef2j7daGG05VIj9QKoBXiwJykgeeGqQg8KpIK3MZzbMynYHAtMIXFLwemQQqovDiq5fjKmgMRS7TAy9T7_EKlLwS0uJXcfWXxkydm1T19rC0kQR9NOBZIz_IUkDGI_mgTxJBgH03AWxbEHJ0gmU38ejcNZGM2DIIxH8cWDt8535M_CyXg0GodumrttD1BIa-hP31hdf13eAek8wtI)

## How to use it

You can set the `.env.production` like this in your vite app. Why `production`? Because vite will use this during build time to populate the environment variables. The prefix here could also be `VITE_`, but just remember what you are using so you can use it later in the docker compose file. You can still overwrite your local development environment using `.env.local`.

```properties
VITE_VALUE=PREFIX_VALUE
```

Copy this script to a file called [env.sh](https://github.com/Dutchskull/Vite-Dynamic-Environment-Variables/blob/main/app/env.sh) with in the root of your vite app.


Now we can update our docker file. You can intergrate this how every you want in your docker file. The most important part is that the `env.sh` is addd and called.

```dockerfile
FROM node:23-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM nginx:alpine

COPY ./nginx.conf /etc/nginx/nginx.conf
# Remember where you copy your app too
COPY --from=builder /app/dist /var/www/html/

# This is the important part
# Copy the script to the entrypoint
COPY env.sh /docker-entrypoint.d/env.sh
# Make sure it has the right line endings using dos2unix
RUN dos2unix /docker-entrypoint.d/env.sh
# Make sure that the script is executable
RUN chmod +x /docker-entrypoint.d/env.sh
# Call entrypoint before you run your main process
ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["nginx","-g","daemon off;"]
```

Now you can use the prefix that you used in your `.env.production` and fill it in your docker compose file. This is what the `env.sh` script will use to find the enviroment variables to replace.

```yaml
services:
  app:
    image: app:latest
    build:
      context: app
    environment:
      # The path too where your app is hosted from resides
      ASSET_DIR: /var/www/html
      # prefix for environment variables
      APP_PREFIX: PREFIX_
      # example
      PREFIX_HELLO_WORLD: "Hello world from docker compose"
```

So everytime you start your docker container it will replace the value in the source with the value in the environment.




