

async function test(param, a, b) {
  const [] = param;

  const foo = 1;
  const FOO = 2;
  let bar = {
    [foo]: 'bar',
    [FOO]() {
      super();
      JSON.parse();
      this.foo.bar;
    }
  };
  bar.foo.bar

  console.log(param, a, b);

}
