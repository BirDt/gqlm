# GQLM - GraphQL Macros
## A macro pre-processor for your GraphQL Schema

Have **YOU** ever been annoyed about repeating property definitions when using interfaces?

Are **YOU** suffering from RSI from pressing CTRL+C and CTRL+V every 30 seconds?

Do **YOU** wonder if there's a better way?

**WELL THERE IS NOW! AND IT'S CALLED GQLM**

### Installation

gqlm is designed to drag and drop into your existing Node.JS environment - just install Biwascheme with:
```bash
$ npm install biwascheme
```
And copy `gqlm.scm` to your directory of choice.

Then, give gqlm a whirl by running:
```bash
biwas gqlm.scm -f example/schema.graphql -o output.graphql
```
And **BAM!**, you should have a brand spanking new, top of the line GraphQL schema in the repo root.

### What does it do?

Commandline flags reference:
- `-f` Specifies the input file (defaults to schema.graphql)
- `-o` Specifies the ouput file (defaults to the value of `-f`)

One or both of these flags must be supplied for gqlm to run.

Now, the good stuff: gqlm adds interface expansions to GraphQL.

What does that mean? It means if you have an interface definition, like so:
```graphql
interface Animal {
  id: ID!
  name: String!
  scientificName: String!
}
```
And you want a new type which implements that definition, instead of writing:
```graphql
type Chicken implements Animal {
  id: ID!
  name: String!
  scientificName: String!
  eggs: [Egg]
}
```
You can just write:
```graphql
type Chicken implements Animal {
  ...Animal
  eggs: [Egg]
}
```
And it'll expand into what you would normally have to type manually. Isn't that neat?!

What's more, you aren't limited to just one expansion per type - you can expand any interface in any type as many times as you want. gqlm won't stop you!
