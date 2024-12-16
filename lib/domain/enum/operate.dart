enum Operate{
  view,
  create,
  edit,
  delete;

   bool get  isCreate => this == Operate.create;
   bool get  isEdit => this == Operate.edit;
   bool get  isView => this == Operate.view;
}
